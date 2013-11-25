# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require '/cfg'

Gem::Specification.new do |s|
  s.name                       = 'bittorrent_sync'
  s.version                    = BitTorrentSync::VERSION
  s.summary                    = 'Client library for BitTorrent Sync API'
  s.description                = 'Simple and fast library for official BitTorrent Sync API'
  s.author                     = 'Boris Murga'
  s.email                      = 'denwwer.c4@gmail.com'
  s.files                      = Dir.glob("lib/**/*")
  s.test_files                 = Dir.glob('spec/**/*')
  s.require_path               = 'lib'
  s.add_runtime_dependency     'oj', '>= 2.2.2'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.post_install_message       = "Thanks for installation, check #{BitTorrentSync::HOME_PAGE} for news."
  s.homepage                   = BitTorrentSync::HOME_PAGE
  s.license                    = 'MIT'
end
