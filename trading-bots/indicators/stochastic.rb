require 'moving_average'
# require_relative "../bitfinex/bitfinex.rb"

# %K = (Current Close - Lowest Low)/(Highest High - Lowest Low) * 100
# %D = 3-day SMA of %K

# Lowest Low = lowest low for the look-back period
# Highest High = highest high for the look-back period
# %K is multiplied by 100 to move the decimal point two places

# Fast Stochastic Oscillator:
# Fast %K = %K basic calculation
# Fast %D = 3-period SMA of Fast %K

# Slow Stochastic Oscillator:
# Slow %K = Fast %K smoothed with 3-period SMA
# Slow %D = 3-period SMA of Slow %K

# Full Stochastic Oscillator:
# Full %K = Fast %K smoothed with X-period SMA
# Full %D = X-period SMA of Full %K


# def get_k(raw_data, period)#k_period, k_smoothed_period, d_smoothed_period)
# 	# Get all highs and lows in two different arrays
# 	lows=[]
# 	highs=[]
# 	data=raw_data
# 	data.last(period).each do |raw_data|
# 		lows << raw_data["low"].to_f
# 	end
# 	data.last(period).each do |raw_data|
# 		highs << raw_data["high"].to_f
# 	end
# 	# Get lowest low
# 	lowest_low=lows.min
# 	# puts "Lowest Low: #{lowest_low}"
# 	# Get highest high
# 	highest_high=highs.max
# 	# puts "Highest High: #{highest_high}"
# 	# puts "Close: #{data.last["close"].to_f}"
# 	k = ((data.last["close"].to_f-lowest_low)/(highest_high-lowest_low))*100
# 	# puts "K: #{k}"
# 	# puts "============"
# 	return k
# end

# def smoothed_k(raw_data, period, k_smoothed_period)
# 	#Calculate all needed %K and add them to array
# 	all_k = []
# 	data=raw_data
# 	k_smoothed_period.times do
# 		all_k << get_k(data, period)
# 		data.pop
# 	end
# 	return all_k.sma
# end

# def smoothed_d(raw_data, period, k_smoothed_period, d_smoothed_period)
# 	#Calculate all needed %K and add them to array
# 	data=raw_data
# 	all_full_k = []
# 	d_smoothed_period.times do
# 		all_full_k << smoothed_k(data, period, k_smoothed_period)
# 		data.pop
# 	end
# 	# puts "All ks #{all_full_k}"
# 	return all_full_k.sma
# end

# def stochastic(raw_data, period, k_smoothed_period, d_smoothed_period)
# 	d = smoothed_d(raw_data, period, k_smoothed_period, d_smoothed_period)
# 	k = smoothed_k(raw_data, period, k_smoothed_period)
# 	values = {"d" => d, "k" => k}
# 	return values
# end

# require 'rufus-scheduler'
# require 'open-uri'
# require 'json'
# require 'openssl'
# require 'net/http'
# require 'active_record'

# puts JSON.parse(open("http://api.coindesk.com/v1/bpi/historical/close.json").read)

def stochastic(raw_data, period, k_smoothed_period, d_smoothed_period)
	raw_data=raw_data.last(period+k_smoothed_period+d_smoothed_period)
	closes=[]
	opens=[]
	highs=[]
	lows=[]
	raw_data.each do |data|
		closes << data["close"].to_f
		opens << data["open"].to_f
		highs << data["high"].to_f
		lows << data["low"].to_f
	end
	n=0
	close_low=[]
	high_low=[]
	(k_smoothed_period+d_smoothed_period).times do
		close_low << closes.first(period).last-lows.first(period).min
		high_low << highs.first(period).max-lows.first(period).min
		closes.shift
		opens.shift
		highs.shift
		lows.shift
	end
	smoothed_k = []
	d_smoothed_period.times do
		close_low_avg = close_low.first(k_smoothed_period).inject(0.0) { |sum, el| sum + el } / k_smoothed_period
		high_low_avg = high_low.first(k_smoothed_period).inject(0.0) { |sum, el| sum + el } / k_smoothed_period
		smoothed_k << (close_low_avg/high_low_avg)*100
		close_low.shift
		high_low.shift
	end
	smoothed_d = smoothed_k.last(d_smoothed_period).inject(0.0) { |sum, el| sum + el } / d_smoothed_period
	results = {"k" => smoothed_k.last, "d" => smoothed_d}
	return results
end


# raw_data = [
# 	{"close" => 1.36105, "open" => 1.35757, "low" => 1.35722, "high" =>1.36225},
# 	{"close" => 1.36105, "open" => 1.36107, "low" => 1.36026, "high" =>1.36323},
# 	{"close" => 1.36685, "open" => 1.36174, "low" => 1.36066, "high" =>1.36743},
# 	{"close" => 1.36563, "open" => 1.36692, "low" => 1.36322, "high" =>1.36741},
# 	{"close" => 1.36704, "open" => 1.36563, "low" => 1.35854, "high" =>1.37101},
# 	{"close" => 1.36387, "open" => 1.36703, "low" => 1.3638, "high" =>1.36721},
# 	{"close" => 1.36244, "open" => 1.36496, "low" => 1.36244, "high" =>1.36592},
# 	{"close" => 1.3626, "open" => 1.36244, "low" => 1.36183, "high" =>1.36351},
# 	{"close" => 1.3586, "open" => 1.3626, "low" => 1.35789, "high" =>1.36357},
# 	{"close" => 1.35699, "open" => 1.35859, "low" => 1.35481, "high" =>1.35923},
# 	{"close" => 1.35339, "open" => 1.357, "low" => 1.35226, "high" =>1.35798},
# 	{"close" => 1.35132, "open" => 1.35342, "low" => 1.35046, "high" =>1.3536},
# 	{"close" => 1.35041, "open" => 1.35132, "low" => 1.34909, "high" =>1.35203},
# 	{"close" => 1.34838, "open" => 1.35041, "low" => 1.34807, "high" =>1.35052},
# 	{"close" => 1.35236, "open" => 1.34838, "low" => 1.34577, "high" =>1.35466},
# 	{"close" => 1.3517, "open" => 1.35232, "low" => 1.35079, "high" =>1.35679},
# 	{"close" => 1.35837, "open" => 1.3517, "low" => 1.35011, "high" =>1.35968},
# 	{"close" => 1.35823, "open" => 1.35836, "low" => 1.35722, "high" =>1.35925}
# 	# {"close" => 7, "open" => 6, "low" => 5, "high" =>8},
# 	# {"close" => 7, "open" => 6, "low" => 5, "high" =>8},
# 	# {"close" => 7, "open" => 6, "low" => 5, "high" =>8},
# 	# {"close" => 7, "open" => 6, "low" => 5, "high" =>8},
# 	# {"close" => 7, "open" => 6, "low" => 5, "high" =>8}
# 	]

# # puts stochastic(raw_data, 8, 3, 4)
# # 
# # thirty_min_raw_data = bitfinex_raw_data("30m", 100) #period = 5m, 30m, 1h, 2h, 6h \ amount=int : amount of datapoints needed
# puts stoch = stochastic(raw_data, 5, 3, 3) #calculates the 30min stoch
# # should get k=40.93 and d=30.53