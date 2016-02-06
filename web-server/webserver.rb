#Gems
require 'sinatra'
require 'poloniex'
require 'json'
require 'open-uri'
require 'open3'
require 'openssl'
require 'net/http'
require 'yaml'

#Dependencies
# require_relative '../trading-bots/bitfinex/bitfinex.rb'
# require_relative '../trading-bots/okcoin/okcoin_rest_client.rb'

#Setup
# keys=File.read("../keys.yaml")
# Poloniex.setup do | config |
#   config.key = keys["poloniex"]["key"]
#   config.secret = keys["poloniex"]["secret"]
# end

#Web Connections
get '/' do
  erb :landing
end

get '/dashboard' do
  # puts Okcoin.order_history( 2, 1, 200)
  # # @transactions=[]
  erb :dashboard
end

get '/statistics' do
  erb :statistics
end

post '/update-balances' do
	balances={"USD" => 0, "BTC" => 0, "LTC"=> 0, "ETH" => 0} #README: Add possible balances here to have the webpage show them and not cause errors
	#Get Bitfinex Data
	bfx = Bitfinex.new("Gxt3Qa0W35fq5JWpX1ILNwca1N3eDNNZKlJf8fqYyhl", "92LSVKCcL2vFu4DSTJEbUe9ttgH1VOwxFeNHGDDea9n")
	bfx.balances.each do |data|
		balances[data["currency"].upcase]+=data["amount"].to_f
	end

	#Get Poloniex Data
	JSON.parse(Poloniex.balances).each do |currency, balance|
		if balance.to_f!=0
			balances[currency.upcase]+=balance.to_f
		end
	end

	#Calculate Value in USD of all Balances
	total_value=0
	balances.each do |currency, balance|
		total_value+=balance.to_f*JSON.parse(open("http://api.cryptocoincharts.info/tradingPair/#{currency.downcase}_usd").read)["price"].to_f
	end

	return_array=[]

	balances.each do |currency, balance|
		return_array<<"<b>#{currency}</b>: #{balance}<br>"
	end

	html="<p>#{return_array.join('')}</p><p><b>Value: #{total_value.round(2)} USD</b></p>"

	return html

end

post '/update-assets' do

end

post '/update-market-prices' do
  data=JSON.parse(open("http://api.cryptocoincharts.info/tradingPair/btc_usd").read)
  btc_usd_price=data["price"].to_f
  btc_usd_volume=data["volume_btc"].to_f
	price_before=data["price_before_24h"].to_f
	btc_usd_change=(((btc_usd_price-price_before)/price_before)*100).round(2)

  data=JSON.parse(open("http://api.cryptocoincharts.info/tradingPair/btc_cny").read)
  btc_cny_price=data["price"].to_f
  btc_cny_volume=data["volume_btc"].to_f
  price_before=data["price_before_24h"].to_f
  btc_cny_change=(((btc_cny_price-price_before)/price_before)*100).round(2)

  data=JSON.parse(open("http://api.cryptocoincharts.info/tradingPair/ltc_usd").read)
	ltc_usd_price=data["price"].to_f
  ltc_usd_volume=data["volume_btc"].to_f
	price_before=data["price_before_24h"].to_f
	ltc_usd_change=(((ltc_usd_price-price_before)/price_before)*100).round(2)

  data=JSON.parse(open("http://api.cryptocoincharts.info/tradingPair/ltc_btc").read)
	ltc_btc_price=data["price"].to_f
  ltc_btc_volume=data["volume_btc"].to_f
	price_before=data["price_before_24h"].to_f
	ltc_btc_change=(((ltc_btc_price-price_before)/price_before)*100).round(2)

  data=JSON.parse(open("http://api.cryptocoincharts.info/tradingPair/eth_btc").read)
	eth_btc_price=data["price"].to_f
  eth_btc_volume=data["volume_btc"].to_f
	price_before=data["price_before_24h"].to_f
	eth_btc_change=(((eth_btc_price-price_before)/price_before)*100).round(2)

  data=JSON.parse(open("http://api.cryptocoincharts.info/tradingPair/eth_usdt").read)
  eth_usd_price=data["price"].to_f
  eth_usd_volume=data["volume_btc"].to_f
  price_before=data["price_before_24h"].to_f
  eth_usd_change=(((eth_usd_price-price_before)/price_before)*100).round(2)
  eth_usd_price=eth_usd_price.round(3)

  return_hash = "{'btc_usd': {'price': #{btc_usd_price}, 'volume': #{btc_usd_volume}, 'change': #{btc_usd_change}},"\
                "'btc_cny': {'price': #{btc_cny_price}, 'volume': #{btc_cny_volume}, 'change': #{btc_cny_change}},"\
                "'ltc_usd': {'price': #{ltc_usd_price}, 'volume': #{ltc_usd_volume}, 'change': #{ltc_usd_change}},"\
                "'ltc_btc': {'price': #{ltc_btc_price}, 'volume': #{ltc_btc_volume}, 'change': #{ltc_btc_change}},"\
                "'eth_btc': {'price': #{eth_btc_price}, 'volume': #{eth_btc_volume}, 'change': #{eth_btc_change}},"\
                "'eth_usd': {'price': #{eth_usd_price}, 'volume': #{eth_usd_volume}, 'change': #{eth_usd_change}}"\
                "}"

  puts "Update Market Prices Done"

  return return_hash

end