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
require_relative '../trading-bots/bitfinex/bitfinex.rb'
require_relative '../trading-bots/okcoin/okcoin_rest_client.rb'

#Setup
keys=File.read("../keys.yaml")
Poloniex.setup do | config |
  config.key = keys["poloniex"]["key"]
  config.secret = keys["poloniex"]["secret"]
end

#Web Connections
get '/' do
  erb :landing
end

get '/dashboard' do
  puts Okcoin.order_history( 2, 1, 200)
  @transactions=[]
  erb :dashboard
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

post '/update-pairs' do
	@btc_usd_price=JSON.parse(open("http://api.cryptocoincharts.info/tradingPair/btc_usd").read)["price"].to_f
	price_before=JSON.parse(open("http://api.cryptocoincharts.info/tradingPair/btc_usd").read)["price_before_24h"].to_f
	@btc_usd_change=(((@btc_usd_price-price_before)/price_before)*100).round(2)

	@ltc_usd_price=JSON.parse(open("http://api.cryptocoincharts.info/tradingPair/ltc_usd").read)["price"].to_f
	price_before=JSON.parse(open("http://api.cryptocoincharts.info/tradingPair/ltc_usd").read)["price_before_24h"].to_f
	@ltc_usd_change=(((@ltc_usd_price-price_before)/price_before)*100).round(2)

	@btc_ltc_price=JSON.parse(open("http://api.cryptocoincharts.info/tradingPair/ltc_btc").read)["price"].to_f
	price_before=JSON.parse(open("http://api.cryptocoincharts.info/tradingPair/ltc_btc").read)["price_before_24h"].to_f
	@btc_ltc_change=(((@btc_ltc_price-price_before)/price_before)*100).round(2)

	@btc_eth_price=JSON.parse(open("http://api.cryptocoincharts.info/tradingPair/eth_btc").read)["price"].to_f
	price_before=JSON.parse(open("http://api.cryptocoincharts.info/tradingPair/eth_btc").read)["price_before_24h"].to_f
	@btc_eth_change=(((@btc_eth_price-price_before)/price_before)*100).round(2)

	return_array=[]
	return_array<<""\
	"<table class='table table-hover'>"\
    "<thead>"\
      "<tr>"\
       	"<th style='text-align: center;'>Pair</th>"\
        "<th style='text-align: center;'>Price</th>"\
        "<th style='text-align: center;'>Change</th>"\
      "</tr>"\
    "</thead>"\
    "<tbody style='overflow-y: scroll; height: 100px;'>"\
      "<tr>"\
        "<td>BTC/USD</td>"
        if @btc_usd_change.to_f>=0
        return_array<<""\
        "<td style='color: green;''>#{@btc_usd_price}</td>"\
        "<td style='color: green;'>#{@btc_usd_change}%</td>"
        else
        return_array<<""\
        "<td style='color: red;'>#{@btc_usd_price}</td>"\
        "<td style='color: red;'>#{@btc_usd_change}%</td>"
        end
      return_array<<""\
      "</tr>"\
      "<tr>"\
        "<td>LTC/USD</td>"
        if @ltc_usd_change.to_f>=0
        return_array<<""\
        "<td style='color: green;'>#{@ltc_usd_price}</td>"\
        "<td style='color: green;'>#{@ltc_usd_change}%</td>"
        else
        return_array<<""\
        "<td style='color: red;'>#{@ltc_usd_price}</td>"\
        "<td style='color: red;'>#{@ltc_usd_change}%</td>"
       	end
      return_array<<""\
      "</tr>"\
      "<tr>"\
        "<td>LTC/BTC</td>"
        if @btc_ltc_change.to_f>=0
        return_array<<""\
        "<td style='color: green;'>#{@btc_ltc_price}</td>"\
        "<td style='color: green;'>#{@btc_ltc_change}%</td>"
        else
        return_array<<""\
        "<td style='color: red;'>#{@btc_ltc_price}</td>"\
        "<td style='color: red;'>#{@btc_ltc_change}%</td>"
        end
      return_array<<""\
      "</tr>"\
      "<tr>"\
        "<td>ETH/BTC</td>"
        if @btc_eth_change.to_f>=0
        return_array<<""\
        "<td style='color: green;'>#{@btc_eth_price}</td>"\
        "<td style='color: green;'>#{@btc_eth_change}%</td>"
        else
        return_array<<""\
        "<td style='color: red;'>#{@btc_eth_price}</td>"\
        "<td style='color: red;'>#{@btc_eth_change}%</td>"
        end
      return_array<<""\
      "</tr>"\
      # "<tr>"\
    		# "<td style='color: red;'>#{@btc_eth_price}</td>"\
      #   "<td style='color: red;'>#{@btc_eth_change}%</td>"\
      # "</tr>"\
    "</tbody>"\
  "</table>"

  return return_array.join(' ')
end

post '/update-updates' do
	updates={}
	#Bitfinex Trade History
	bfx = Bitfinex.new("Gxt3Qa0W35fq5JWpX1ILNwca1N3eDNNZKlJf8fqYyhl", "92LSVKCcL2vFu4DSTJEbUe9ttgH1VOwxFeNHGDDea9n")
	puts "running"
	#Poloniex Trade History
	JSON.parse(Poloniex.trade_history("BTC_ETH")).each do |data|
		time_stamp=Time.parse(data["date"]).to_i
		if data["type"]=="sell"
			updates[time_stamp]="#{data['amount']} ETH sold at #{data['rate']} BTC each for a total of #{data['total']} BTC"
		elsif data["type"]=="buy"
			updates[time_stamp]="#{data['amount']} ETH bought at #{data['rate']} BTC each for a total of #{data['total']} BTC"
		end
	end

	Hash[updates.sort.reverse]

	return_array=[]

	updates.each do |time, message|
		return_array<<""\
		"<div class='desc' style='width: 100%;'>"\
      "<div class='thumb'>"\
        "<span class='badge bg-theme'><i class='fa fa-clock-o'></i></span>"\
      "</div>"\
      "<div class='details'>"\
	      "<p><muted>#{Time.at(time)}</muted><br>"\
	      "#{message}<br>"\
	      "</p>"\
      "</div>"\
    "</div>"
	end

	return return_array.join('')

end