require 'bittorrent_sync/api'

module BitTorrentSync

  def self.connect(config)
    API.new(config)
  end

end