# coding: utf-8

require 'rubygems'
require 'net/https'
require 'twitter'
require 'oauth'
require 'json'
require 'pp'

class MyBot
    CONSUMER_KEY       = "iA6syG3GpvAksccRUmoAUg"
    CONSUMER_SECRET    = "9kTijp0gabxwIPlJZrWSzZUYvbvtMrDvLrhplZbc"
    ACCESS_TOKEN        = "400941481-EB8ImJjBPNu81MMkheLnSxhWS9MOz9vANJkhCzm6"
    ACCESS_TOKEN_SECRET = "oQ6TvwpqrcsQaicMc8wbzVp4X5cskREQcovSoxW3E"

    MY_SCREEN_NAME = "geekmaru"

    BOT_USER_AGENT = "my bot @#{MY_SCREEN_NAME}"

    HTTPS_CA_FILE_PATH = "./verisign.cer"

    def initialize
        @consumer = OAuth::Consumer.new(
            CONSUMER_KEY,
            CONSUMER_SECRET,
            :site => 'http://twitter.com'
        )
        @access_token = OAuth::AccessToken.new(
            @consumer,
            ACCESS_TOKEN,
            ACCESS_TOKEN_SECRET
        )
        Twitter.configure do |config|
            config.consumer_key       = "iA6syG3GpvAksccRUmoAUg"
            config.consumer_secret    = "9kTijp0gabxwIPlJZrWSzZUYvbvtMrDvLrhplZbc"
            config.oauth_token        = "400941481-EB8ImJjBPNu81MMkheLnSxhWS9MOz9vANJkhCzm6"
            config.oauth_token_secret = "oQ6TvwpqrcsQaicMc8wbzVp4X5cskREQcovSoxW3E"
        end
    end

    def connect
        uri = URI.parse("https://userstream.twitter.com/2/user.json?track=#{MY_SCREEN_NAME}")

        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.ca_file = HTTPS_CA_FILE_PATH
        https.verify_mode = OpenSSL::SSL::VERIFY_PEER
        https.verify_depth = 5

        pp https

        https.start do |https|
            request = Net::HTTP::Get.new(uri.request_uri)
            request["User-Agent"] = BOT_USER_AGENT
            request.oauth!(https, @consumer, @access_token)

            buf = ""
            https.request(request) do |response|
                response.read_body do |chunk|
                    buf << chunk
                    while(line = buf[/.+?(\r\n)+/m]) != nil
                        begin
                            buf.sub!(line,"")
                            line.strip!
                            status = JSON.parse(line)
                        rescue
                            break
                        end

                        yield status
                    end
                end
            end
        end
    end

    def run
        loop do
            begin
                connect do |json|
                    if json['text']
                        user = json['user']
                        pp json['text']
                        if /^@#{MY_SCREEN_NAME}/ =~ json['text']
                            if /all/ =~ json['text'] || /みんな/ =~ json['text']
                                tweet_members(json['text'], user['screen_name'])
                            end
                        end
                    end
                end
            rescue Timeout::Error, StandardError
                puts "Twitterとの接続が切れた為、再接続します"
            end
        end
    end

    def tweet_members (text, from)
        notification = text.gsub(/^@#{MY_SCREEN_NAME}/, '')
        notification = notification.gsub(/みんな/, '[みんな]')
        notification = notification.gsub(/all/, '[all]')
        Twitter.list_members('geekmaru-member').attrs[:users].each do |key,value|
            puts '@' + key[:screen_name] + notification + " #{from}から"
            Twitter.update('@' + key[:screen_name] + notification + " #{from}から")
        end
    end
end

if $0 == __FILE__
    MyBot.new.run
end
