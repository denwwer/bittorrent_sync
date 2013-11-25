# encoding: UTF-8
require 'simplecov'
SimpleCov.start
require 'rubygems'
require 'bittorrent_sync'
require 'bittorrent_sync/config'

RSpec.configure do |config|
  config.fail_fast = true
  config.before(:all) do
    init
  end
end

# test settings
def init
  @dir_to_add = '/home/boris/Pictures' # path to dir which we will add to sync, dir SHOULD NOT BE EMPTY
  @dir_to_add.freeze
  @temp = File.dirname(__FILE__) + '/temp'
  @temp.freeze
  @config = @temp + '/bts_config.json'
  @config.freeze

  FileUtils.mkdir_p(@temp) if !Dir.exist?(@temp)
  # generate config
  BitTorrentSync::Config.generate(@temp) unless File.file?(@config)
end


