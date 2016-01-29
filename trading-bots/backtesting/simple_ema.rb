require 'rubygems'
require 'bundler'
require 'bundler'
require 'open-uri'
require 'json'
require 'pp'
require 'open3'
require 'openssl'
require 'net/http'
require 'moving_average'

data=JSON.parse(open("http://api.coindesk.com/v1/bpi/historical/close.json?start=2015-01-01&end=2016-01-01").read)
@prices=[]
data["bpi"].each do |data, price|
	@prices<<price.to_f
end

@btc_balance=1
@usd_balance=0
@last_action="bought"

999999.times do
begin
	prices=@prices.first(50)
	@prices.shift
	if prices.last(12).ema>prices.last(48).ema && @last_action=="sold"
		puts "Buying at #{prices.last}"
		@btc_balance+=@usd_balance/prices.last
		@usd_balance=0
		@last_action="bought"
	elsif prices.last(12).ema<prices.last(48).ema && @last_action=="bought"
		puts "Selling at #{prices.last}"
		@usd_balance+=@btc_balance*prices.last
		@btc_balance=0
		@last_action="sold"
	end
rescue
end
end

puts @usd_balance
puts @btc_balance