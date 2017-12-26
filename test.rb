$LOAD_PATH << 'lib'

require "rubygems"
require 'alexa'
require 'pry'

MultiXml.parser = 'nokogiri'

client = Alexa::Client.new(
  access_key_id:     "AKIAI6PLPJPHKFRRIDHQ",
  secret_access_key: "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"
)

url_info = client.url_info(url: "google.com")
puts url_info.rank


