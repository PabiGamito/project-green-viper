#  * Middle Band = 20-day simple moving average (SMA)
# * Upper Band = 20-day SMA + (20-day standard deviation of price x 2) 
# * Lower Band = 20-day SMA - (20-day standard deviation of price x 2)
# 
# standard deviation of price
# Calculate the average (mean) price for the number of periods or observations.
# Determine each period's deviation (close less average price).
# Square each period's deviation.
# Sum the squared deviations.
# Divide this sum by the number of observations.
# The standard deviation is then equal to the square root of that number.

require 'open-uri'
require 'json'
require 'pp'
require 'open3'
require 'openssl'
require 'net/http'

def bb(data, sma_period=14, deviation_period=14, lower_deviation=2, upper_deviation=2) #data = only prices in order
	avg_price=data.last(sma_period).inject(0.0) { |sum, el| sum + el } / sma_period
	@middle_band=avg_price
	deviation=[]
	data.last(deviation_period).each do |price|
		# puts ((price.to_f-avg_price.to_f)**2)
		deviation<<((price.to_f-avg_price.to_f)**2)
	end
	deviation_total=0
	avg_deviation=deviation.inject(0.0) { |sum, el| sum + el } / deviation.size
	standard_deviation=Math.sqrt(avg_deviation)
	@upper_band=avg_price+(standard_deviation*upper_deviation)
	@lower_band=avg_price-(standard_deviation*lower_deviation)
	return{:upper_band => @upper_band, :lower_band => @lower_band, :middle_band => @middle_band}
end

# prices=[1,2,1.5,2.1,2.3,2.4,3,2.8,2.7,3.5,3]

# JSON.parse(open("https://poloniex.com/public?command=returnChartData&currencyPair=BTC_ETH&start=0&end=9442275200&period=7200", :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE).read).each do |data|
# 	# puts data["close"].to_f
# 	prices<<data["close"].to_f
# end

# puts bb(prices)[:upper_band]
# puts @lower_band
# puts @upper_band
# puts @middle_band