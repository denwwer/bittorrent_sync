#!/usr/bin/env ruby
require '../lib/bittorrent_sync/config'
BitTorrentSync::Config.generate(ARGV[0])