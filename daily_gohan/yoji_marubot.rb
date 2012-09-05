#!/usr/local/bin/ruby
# coding: utf-8
require 'twitter'
require 'mongo'
require 'pp'

require "#{Dir::pwd}/marubot_secret.rb"

class YojiMaru
    def initialize
        Twitter.configure do |config|
            config.consumer_key       = CONSUMER_KEY
            config.consumer_secret    = CONSUMER_SECRET
            config.oauth_token        = OAUTH_TOKEN
            config.oauth_token_secret = OAUTH_SECRET
        end
        @mongo = Mongo::Connection.new(MONGO_CONNECT, 27017).db('marubot')
    end

    def ask_eat
        member = ""
        Twitter.list_members('geekmaru-member').attrs[:users].each do |t|
          member = "#{member} @#{t[:screen_name]}"
        end
        data = {"last_update" => Time::now.to_i}
        @mongo['daily_gohan'].insert(data)
        Twitter.update("#{member} ご飯いる？")
    end
end

YojiMaru.new.ask_eat
