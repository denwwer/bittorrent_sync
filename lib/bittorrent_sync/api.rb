require 'bittorrent_sync/cfg'
require 'bittorrent_sync/ext'
require 'uri'
require 'net/http'
require 'base64'
require 'oj'

module BitTorrentSync
  class RequestError < Exception; end
  class WrongConfig < Exception; end
  class WrongFormat < Exception; end

  class API
    attr_reader :errors

    def initialize(config)
      init_vars(config)
    end

    # check if we has any error in returned data
    def has_errors?
      !@errors.empty?
    end

    def successful?
      @errors.empty?
    end

    # Return Array with folder information
    # Example:
    #   sync.folders
    #   =>
    #       [{:dir => '/home/music',
    #         :secret => 'AYA5DBCQOTWZWCQ3CNC5YDMP5JISA6MNC',
    #         :size => 23762511569,
    #         :type => 'read_write',
    #         :files => 12,
    #         :error => 0,
    #         :indexing => nil}]
    #
    # Arguments:
    #   secret (optional): if a secret is specified, will return info about the folder with this secret
    def folders(secret = '')
      params = {}
      params[:secret] = secret unless secret.empty?
      send_request 'get_folders', params
    end

    # Return folder information be specified folder path
    # Example:
    #   sync.folder_by_dir('/home/music')
    #   =>
    #       {:dir => '/home/music',
    #        :secret => 'AYA5DBCQOTWZWCQ3CNC5YDMP5JISA6MNC',
    #        :size => 23762511569,
    #        :type => 'read_write',
    #        :files => 12,
    #        :error => 0,
    #        :indexing => nil}
    #
    # Arguments:
    #   dir: path to the sync folder
    def folder_by_dir(dir)
      folder = folders.select{|f| f[:dir] == dir}[0]
      return folder.nil? ? {} : folder
    end

    # Add folder to Sync
    # Example:
    #   sync.add_folder('/home/music')
    #   => true
    #
    # Arguments:
    #   dir: path to the sync folder
    #   params:
    #     secret (optional): folder secret
    #     selective (optional): specify sync mode, selective - 1, all files (default) - 0
    def add_folder(dir, params = {})
      params.keep_only([:selective, :secret])
      params[:selective_sync] = params[:selective] ? 1 : 0
      params.delete(:selective)
      params[:dir] = dir
      data = send_request 'add_folder', params

     return successful?
    end

    # Remove folder from Sync but leaving folder and files on disk
    # Example:
    #   sync.remove_folder('AYA5DBCQOTWZWCQ3CNC5YDMP5JISA6MNC)
    #   => true
    #
    # Arguments:
    #   secret: folder secret
    def remove_folder(secret)
      data = send_request 'remove_folder', {:secret => secret}
      return successful?
    end

    # Returns list of peers connected to the specified folder
    # Example:
    #   sync.folder_peers('AYA5DBCQOTWZWCQ3CNC5YDMP5JISA6MNC')
    #   =>
    #       [{:id => "ARRdk5XANMb7RmQqEDfEZE-k5aI=",
    #         :connection => 'direct', // direct or relay
    #         :name => 'GT-I9500',
    #         :synced => 0, // timestamp when last sync completed
    #         :download => 0,
    #         :upload => 22455367417}]
    #
    # Arguments:
    #   secret: folder secret
    def folder_peers(secret)
      send_request 'get_folder_peers', {:secret => secret}
    end

    # Returns list of peers connected to the specified folder
    # Example:
    #   sync.folder_peers('AYA5DBCQOTWZWCQ3CNC5YDMP5JISA6MNC')
    #   =>
    #       [{:id => "ARRdk5XANMb7RmQqEDfEZE-k5aI=",
    #         :connection => 'direct', // direct or relay
    #         :name => 'GT-I9500',
    #         :synced => 0, // timestamp when last sync completed
    #         :download => 0,
    #         :upload => 22455367417}]
    #
    # Arguments:
    #   secret: folder secret
    #   encrypted (optional): generate secret with support of encrypted peer
    def secrets(secret, encrypted = false)
      params = {:secret => secret}
      params[:type] = 'encryption' if encrypted
      send_request 'get_secrets', params
    end

    def preferences(secret, params = {})
      # get
      method = 'get_folder_prefs'
      unless params.empty?
        # set
        method = 'set_folder_prefs'
        params.keep_only([:search_lan, :use_dht, :use_hosts, :use_relay_server, :use_sync_trash, :use_tracker])
      end
      send_request method, params.merge({:secret => secret})
    end

    # Returns list of predefined hosts for the folder
    def hosts(secret, hosts = [], force = false)
      # get
      params = {:secret => secret}
      method = 'get_folder_hosts'
      if !hosts.empty? || force
        # set
        method = 'set_folder_hosts'
        params.merge!({:hosts => hosts.join(',')})
      end
      data = send_request method, params
      return data[:hosts]
    end

    def config(params = {})
      # get
      method = 'get_prefs'
      unless params.empty?
        # set
        method = 'set_prefs'
        params.keep_only([:device_name,
                          :disk_low_priority,
                          :download_limit,
                          :folder_rescan_interval,
                          :lan_encrypt_data,
                          :lan_use_tcp,
                          :lang,
                          :listening_port,
                          :max_file_size_diff_for_patching,
                          :max_file_size_for_versioning,
                          :rate_limit_local_peers,
                          :send_buf_size,
                          :sync_max_time_diff,
                          :sync_trash_ttl,
                          :upload_limit,
                          :use_upnp,
                          :recv_buf_size])
      end
      send_request method, params
    end

    def os
      data = send_request 'get_os'
      return data[:os]
    end

    def version
      data = send_request 'get_version'
      return data[:version]
    end

    def speed
      send_request 'get_speed'
    end

    def off
      send_request  'shutdown'
      return successful?
    end

    # Returns list of files within the specified directory, default is root
    # Example:
    #   sync.files('AYA5DBCQOTWZWCQ3CNC5YDMP5JISA6MNC')
    #   =>
    #       [{:have_pieces => 1,
    #         :name => 'index.html',
    #         :size => 2726,
    #         :state => 'created',
    #         :total_pieces => 1,
    #         :type => 'file',
    #         :download => 1 # IMPORTANT: only for selective sync folders
    #       }]
    #
    # Arguments:
    #   secret: folder secret
    #   path (optional): path to specified subfolder
    def files(secret, path = nil)
      params = {:secret => secret}
      params[:path] = path if path
      send_request 'get_files', params
    end

    # IMPORTANT: only for selective sync folders
    # Selects file for download for selective sync folders
    # Example:
    #   sync.file_info('AYA5DBCQOTWZWCQ3CNC5YDMP5JISA6MNC','index.html')
    #   =>
    #       {:have_pieces => 1,
    #         :name => 'index.html',
    #         :size => 2726,
    #         :state => 'created',
    #         :total_pieces => 1,
    #         :type => 'file',
    #         :download => 1}
    #
    # Arguments:
    #   secret: folder secret
    #   path (optional): path to specified subfolder
    def file_download(secret, path, download = true)
      data = send_request 'set_file_prefs', {:secret => secret,
                                            :path => path,
                                            :download => download ? 1 : 0}
      if data.size > 1
        return data
      else
        return data[0]
      end
    end

    private

    # initialize vars
    def init_vars(config)
      login = ''
      password = ''

      if config.is_a?(Hash)
        @host = config[:host]
        login = config[:login]
        password = config[:password]
      elsif config.is_a?(String)
        begin
          config = Oj.load( File.read(config) )
          @host = config['webui']['listen']
          login = config['webui']['login']
          password = config['webui']['password']
        rescue Exception
          raise WrongConfig, 'Config file not found or has bad format.'
        end
      else
        raise WrongConfig, 'Config argument should be Hash or path to bts_config.json file.'
      end

      @host = "http://#{@host}"
      # auth header
      if login && password
        @auth = {'Authorization' => 'Basic ' + Base64.encode64("#{login}:#{password}")}
      end
    end

    # send request to server and return data
    def send_request(method, params = {})
      # default path
      path = "/api?method=#{method}"
      # headers
      headers = {'Content-Type' => 'application/json',
                 'User-Agent' => "Ruby client library v#{BitTorrentSync::VERSION}"}
      headers.merge!(@auth) if @auth
      # add other params if present
      path <<  '&' + URI.encode_www_form(params) unless params.empty?
      uri = URI.parse(@host)
      http = Net::HTTP.new(uri.host, uri.port)
      # debug
      if BitTorrentSync::DEBUG_MODE
        http.set_debug_output($stderr)
        puts '-'*70
      end
      # start
      req = Net::HTTP::Get.new(path, headers)
      http.start{|h| @response = h.request(req) }
      # raise if unsuccessful
      if @response.code.to_i != 200
        error = "#{@response.code} #{@response.message}"
        error << ": #{@response.body}" unless @response.body.empty?
        raise RequestError, error
      end
      parse_response!
    end

    def parse_response!
      @errors = {}
      data = Oj.strict_load(@response.body, :symbol_keys => true)
      if data.kind_of?(Array)
        @errors = data.select{|d| d[:error] if d[:error].to_i > 0}
      elsif (data[:error].to_i > 0) || (data[:result].to_i > 200)
        # Hash
        @errors = data
      end
      return data
    end

  end
end