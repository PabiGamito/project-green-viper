class DashboardController < ApplicationController

	#Gems
require 'json'
require 'open-uri'
require 'open3'
require 'openssl'
require 'net/http'
require 'yaml'

  def index
  	
  end

  def update_markets
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

	  return_hash = {'btc_usd': {'price': btc_usd_price, 'volume': btc_usd_volume, 'change': btc_usd_change},
	                'btc_cny': {'price': btc_cny_price, 'volume': btc_cny_volume, 'change': btc_cny_change},
	                'ltc_usd': {'price': ltc_usd_price, 'volume': ltc_usd_volume, 'change': ltc_usd_change},
	                'ltc_btc': {'price': ltc_btc_price, 'volume': ltc_btc_volume, 'change': ltc_btc_change},
	                'eth_btc': {'price': eth_btc_price, 'volume': eth_btc_volume, 'change': eth_btc_change},
	                'eth_usd': {'price': eth_usd_price, 'volume': eth_usd_volume, 'change': eth_usd_change}
	                }

	  puts "Update Market Prices Done"

	  render :json => return_hash
  end

  def bitcoin_price_history
  	data=JSON.parse(open("http://api.coindesk.com/v1/bpi/historical/close.json").read)
  	price_a_month_ago=data["bpi"].values.first
  	price_a_week_ago=data["bpi"].values.last(7).first.to_f
  	current_price=JSON.parse(open("http://api.coindesk.com/v1/bpi/currentprice.json").read)["bpi"]["USD"]["rate"].to_f
  	render :json => {'price_last_month': price_a_month_ago, 
  		'price_last_week': price_a_week_ago,
  		'month_variation': (((current_price-price_a_month_ago)/price_a_month_ago)*100).round(2),
  		'week_variation': (((current_price-price_a_week_ago)/price_a_week_ago)*100).round(2),
  		'current_price': current_price,
  	}
  end

  def bitcoin_ticker
  	
  end

end