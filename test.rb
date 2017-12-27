$LOAD_PATH << 'lib'

require "rubygems"
require 'alexa'
require 'pry'

MultiXml.parser = 'nokogiri'

unless ARGV[0] && ARGV[1]
  puts "Usage: ruby test.rb access_key_id secret_access_key"
  exit 0
end

client = Alexa::Client.new(
  access_key_id:     ARGV[0],
  secret_access_key: ARGV[1]
)

puts client.url_info(url: "google.com").rank


