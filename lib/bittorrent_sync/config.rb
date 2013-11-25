module BitTorrentSync
  module Config
    def self.generate(path)
      config = File.read(File.join( File.dirname(__FILE__),'config.json'))
      File.open(path + '/bts_config.json', 'w'){|f| f.write(config)}
    end
  end
end