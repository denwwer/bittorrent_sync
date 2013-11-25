require 'spec_helper'

describe BitTorrentSync do

  before(:each) do
    @sync = BitTorrentSync.connect(@config)
  end

  describe 'folders' do
    it 'should return folder list' do
      folders = @sync.folders
      folders.should be_kind_of Array
      @sync.has_errors?.should be_false
    end

    it 'should return error when try add fake folder' do
      @sync.add_folder('/dd/ds', :mode => '', 'secret' => 11).should be_false
      @sync.has_errors?.should be_true
    end

    it 'should add folder' do
      @sync.add_folder(@dir_to_add).should be_true
      @sync.has_errors?.should be_false
    end

    it 'should remove folder from sync' do
      @sync.add_folder(@dir_to_add).should be_true
      secret = @sync.folder_by_dir(@dir_to_add)[:secret]
      @sync.remove_folder(secret).should eq true
    end

    it 'should return peers list' do
      build_secret
      list = @sync.folder_peers(@secret)
      list.should be_kind_of Array
      @sync.has_errors?.should be_false
    end

    it 'should return secrets' do
      build_secret
      s = @sync.secrets(@secret, true)
      #FIXME :encryption not working now from sync
      #[:read_only, :read_write, :encryption].each do |key|
      #  s.has_key(key).should be_true
      #end
      [:read_only, :read_write].each do |key|
        s.has_key?(key).should be_true
      end
    end

    it 'should return preferences' do
      build_secret
      list = @sync.preferences(@secret)
      list.should be_kind_of Hash
      @sync.has_errors?.should be_false
    end

    it 'should update preferences' do
      build_secret
      options = {:search_lan => 1,
                 :use_dht => 1,
                 :use_hosts => 0,
                 :use_relay_server => 1,
                 :use_sync_trash => 0,
                 :use_tracker => 0}
      @sync.preferences(@secret, options).should be_kind_of Hash
      pref = @sync.preferences(@secret)
      options.each do |key, val|
        pref[key].should eq val
      end
      @sync.has_errors?.should be_false
    end

    it 'should return hosts' do
      build_secret
      list = @sync.hosts(@secret)
      list.should be_kind_of Array
      @sync.has_errors?.should be_false
    end

    it 'should update hosts' do
      build_secret
      new_hosts = ['192.168.1.3:3000', '192.168.1.5:4040']
      old = @sync.hosts(@secret)
      @sync.hosts(@secret, new_hosts)
      @sync.hosts(@secret).sort.should eq new_hosts.sort!
      @sync.hosts(@secret, old, true)
      @sync.has_errors?.should be_false
    end

    after(:each) do
      clear!
    end
  end

  describe 'files' do
    it 'should return file list in directory' do
      build_secret
      files = @sync.files(@secret)
      files.should be_kind_of Array
      files.empty?.should be_false
      @sync.has_errors?.should be_false
    end

    it 'should turn off download for selective sync folder' do
      build_secret(true)
      file = @sync.files(@secret)[0]
      file[:download].should eq 1
      pref = @sync.file_download(@secret, file[:name], false)
      pref[:download].should eq 0
    end

    after(:each) do
      clear!
    end
  end

  describe 'sync' do
    it 'should return sync preferences' do
      @sync.config.should be_kind_of Hash
      @sync.has_errors?.should be_false
    end
    # TODO: need check more options
    it 'should update sync preferences' do
      new_conf = {:device_name => 'Sync Server'}
      old = @sync.config
      @sync.config(new_conf)
      cfg = @sync.config
      new_conf.each do |key, val|
        cfg[key].should eq val
      end
      # rollback
      @sync.config(old)
      @sync.has_errors?.should be_false
    end

    it 'should return OS name' do
      @sync.os.empty?.should be_false
      @sync.has_errors?.should be_false
    end

    it 'should return BitTorrent Sync version' do
      @sync.version.empty?.should be_false
      @sync.has_errors?.should be_false
    end

    it 'should return speed' do
      @sync.speed.should be_kind_of Hash
      @sync.has_errors?.should be_false
    end
    # IMPORTANT: this stop server, so run this block last
    it 'should stops Sync' do
      #@sync.off.should be_true
    end
  end


  # helpers
  def build_secret(selective = false)
    options = {}
    options[:selective] = true if selective
    @sync.add_folder(@dir_to_add, options).should be_true
    @secret = @sync.folder_by_dir(@dir_to_add)[:secret]
    @secret.freeze
    @sync.has_errors?.should be_false
    sleep 5 # wait for indexing
  end

  def clear!
    if @secret
      @sync.remove_folder(@secret).should eq true
    end
  end

end