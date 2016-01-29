 # 'MONEY FLOW INDEX - MFI'

# 1. Determine the Typical Price as follows: (High + Low + Close) / 3

# 2. Calculate the Raw Money Flow: Typical Price x Volume

# 3. Identify the Money Flow Ratio: (14-period Positive Money Flow) / (14-period Negative Money Flow)
# (Note: Positive money values are created when the typical price is greater than the previous typical price value. 
# The sum of positive money over the number of periods – usually 14 days – is the positive money flow. The opposite is true for the negative money flow values.)

# 4. Finally, arrive at the Money Flow Index. This is: 100 – [100/(1 + Money Flow Ratio)]

#===================================#
# DOESN"T SEEM TO WORK VERY WELL... #
#===================================#

require 'open-uri'
require 'json'
require 'pp'
require 'open3'
require 'openssl'
require 'net/http'

def mfi(data, period=14)
	#data{"close: high: low: volume:,}"} RAW Poloniex data
	possitive_money_flow = []
	negative_money_flow = []
	data.last(period+1).each do |data|
		avg_price = (data["high"].to_f+data["low"].to_f+data["close"].to_f)/3
		begin
			if @prev_avg_price<avg_price
				possitive_money_flow << avg_price*data["volume"].to_f
			else
				negative_money_flow << avg_price*data["volume"].to_f
			end
		rescue
		end
		@prev_avg_price = avg_price
	end
	period_possitive_flow=0
	period_negative_flow=0
	possitive_money_flow.each do |flow|
		period_possitive_flow+=flow
			flow_ratio=period_possitive_flow/period_negative_flow
			mfi=100-(100/(1+flow_ratio))
			puts mfi
			puts period_negative_flow==0
	end
	negative_money_flow.each do |flow|
		period_negative_flow+=flow
			flow_ratio=period_possitive_flow/period_negative_flow
			mfi=100-(100/(1+flow_ratio))
			puts mfi
	end
	flow_ratio=period_possitive_flow/period_negative_flow
	mfi=100-(100/(1+flow_ratio))
	return mfi
end

# data=JSON.parse(open("https://poloniex.com/public?command=returnChartData&currencyPair=BTC_ETH&start=0&end=9442275200&period=7200", :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE).read)
# puts mfi(data, 99999)