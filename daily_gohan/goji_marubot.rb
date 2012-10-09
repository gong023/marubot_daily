#!/usr/local/bin/ruby
# coding: utf-8
require 'twitter'
require 'mongo'
require 'pp'

require "#{Dir::pwd}/marubot_secret.rb"

class GojiMaru
    def initialize
        Twitter.configure do |config|
            config.consumer_key       = CONSUMER_KEY
            config.consumer_secret    = CONSUMER_SECRET
            config.oauth_token        = OAUTH_TOKEN
            config.oauth_token_secret = OAUTH_SECRET
        end
        @mongo = Mongo::Connection.new(MONGO_CONNECT, 27017).db('marubot').collection('daily_gohan')
        @want_word = /いる|欲しい|ほしい|たべる|食べる|はい|ほしかばい/
        @cook_word = /つくる|作る/
    end

    def goji_routine
      mentions = Twitter.mentions
      last_update = @mongo.find.to_a[-1]["last_update"]
      want_member = count_menber(mentions, last_update, @want_word)
      cook_member = count_menber(mentions, last_update, @cook_word)
      tweet_text = getTweetText(want_member, cook_member)
      Twitter.update(tweet_text) unless tweet_text.nil?
      profile_text = getProfileText(tweet_text)
      Twitter.update_profile({:description => profile_text})
    end
    
    def count_menber(mentions, last_update, regrep)
      member = []
      mentions.each do |m|
        if m[:created_at].to_i > last_update && regrep =~ m[:text]
          member << m[:user][:screen_name]
        end
      end
      member.uniq
    end

    def getTweetText(want_member, cook_member)
      result = ''
      if want_member.size != 0
        result = '今日食べたいひとは '
        want_member.each{|w| result = "#{result} @#{w} "}
        result = "#{result}の#{want_member.size}人だよ！"
      end
      if cook_member.size != 0
        result = "#{result} ご飯は" 
        cook_member.each{|c| result = "#{result} @#{c}"}
        result = "#{result} が作ってくれるよ！ありがとう！"
      end
    end

    def getProfileText(text)
      default = 'ギークハウス高円寺の妖精まるちゃんだよ 【毎日六時に更新されます】→'
      profile = text.nil? ? "#{Time.now.strftime("%m/%d")}は食べる人も作る人もいないよ" : text
      return default + profile
    end
end

GojiMaru.new.goji_routine
