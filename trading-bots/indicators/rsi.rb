		#               100
    # RSI = 100 - --------
    #              1 + RS
    # RS = Average Gain / Average Loss
    # First Average Gain = Sum of Gains over the past 14 periods / 14
    # First Average Loss = Sum of Losses over the past 14 periods / 14
    # Average Gain = [(previous Average Gain) x 13 + current Gain] / 14.
    # Average Loss = [(previous Average Loss) x 13 + current Loss] / 14.
    # 
    # StochRSI = (RSI - Lowest Low RSI) / (Highest High RSI - Lowest Low RSI)

require 'moving_average'

def rsi(data, period=14) #Data= prices in order: oldest to newest
	# puts "RSI"
	# puts data
	# puts "...."
	#First Averages
	gain_sum=0
	loss_sum=0
	data.first(period+1).each do |price| #+1 because first on rescues just to get first price
		begin
			if @prev_price<price.to_f #Up
				gain_sum+=price.to_f-@prev_price
			else #Down
				loss_sum+=@prev_price-price.to_f
			end
		rescue Exception => e
			
		end
		@prev_price=price.to_f
	end
	@avg_gain=gain_sum/14
	@avg_loss=loss_sum/14

	#Averages Gain & Loss
	@rsi=[]
	data.shift(period)
	data.each do |price|
		# puts price
		# puts period
		# puts @prev_price
		# puts @avg_gain
		# puts @avg_loss
		# puts "..."
		if @prev_price<price.to_f && price.to_f != 0
			@avg_gain=(@avg_gain*(period-1)+(price.to_f-@prev_price))/period
			# puts "... #{@avg_gain}"
			rs=@avg_gain/@avg_loss
			rsi_value=100-(100/(1+rs))
			@rsi<<rsi_value
		elsif price.to_f != 0
			@avg_loss=(@avg_loss*(period-1)+(@prev_price-price.to_f))/period
			rs=@avg_gain/@avg_loss
			rsi_value=100-(100/(1+rs))
			@rsi<<rsi_value
			# puts "... #{@avg_loss}"
		end
		@prev_price=price.to_f
		# puts "
		# 
		# 
		# 
		# 
		# "
	end
	# puts @avg_gain
	# puts @avg_loss
	# puts @rsi
	rs=@avg_gain/@avg_loss
	rsi_value=100-(100/(1+rs))
	return {"last_rsi" => rsi_value, "all_rsi" => @rsi}
end

def stoch_rsi(data, rsi_period=14, stoch_period=14)
	# StochRSI = (RSI - Lowest Low RSI) / (Highest High RSI - Lowest Low RSI)
	# puts data
	# puts "..."
	all_rsi=rsi(data, rsi_period)["all_rsi"]
	all_stoch_rsi=[]
	(all_rsi.count-stoch_period).times do
		# puts all_rsi
		# puts "...."
		calculation_rsi = all_rsi.first(stoch_period)
		# puts (calculation_rsi.last.to_f-calculation_rsi.min.to_f)/(calculation_rsi.max.to_f-calculation_rsi.min.to_f)
		all_stoch_rsi << (calculation_rsi.last.to_f-calculation_rsi.min.to_f)/(calculation_rsi.max.to_f-calculation_rsi.min.to_f)
		all_rsi.shift
	end
	# stoch_period.times do
	# 	if data.count > rsi_period
	# 		all_rsi<<rsi(data, rsi_period)
	# 		data.pop
	# 	end
	# end
	# puts all_rsi.last
	# puts all_rsi.min
	# puts all_rsi.max
	# puts "Stoch RSI:"
	# puts (all_rsi.last.to_f-all_rsi.min.to_f)/(all_rsi.max.to_f-all_rsi.min.to_f)
	sleep(2)
	return all_stoch_rsi
	# puts data
	# rsi=rsi(data, rsi_period)
	# @rsi.last(stoch_period).each do |rsi_data|
	# 	begin
	# 		if @highest_rsi<rsi_data 
	# 			@highest_rsi=rsi_data
	# 		elsif @lowest_rsi>rsi_data
	# 			@lowest_rsi=rsi_data
	# 		end
	# 	rescue
	# 		@lowest_rsi=rsi_data
	# 		@highest_rsi=rsi_data
	# 	en
	# end
	# stoch_rsi=((rsi-@lowest_rsi)/(@highest_rsi-@lowest_rsi))*100
	# return stoch_rsi
end

def stoch_rsi_k(data, rsi_period=14, stoch_period=14, k, d)
	k_stochrsi=[]
	n=0
	d.times do
		puts stoch_rsi(data, rsi_period, stoch_period).last(k)
		# puts "..."
		k_stochrsi<<stoch_rsi(data, rsi_period, stoch_period).last(k).sma
	end
	# stoch_rsi(data, rsi_period, stoch_period).last(k)
	return k_stochrsi #TRYING WITH EMA INSTEAD OF SMA
end

def full_stoch_rsi(data, rsi_period=14, stoch_period=14, k, d)
	stoch_k = stoch_rsi_k(data, rsi_period, stoch_period, k, d)
	k_value = stoch_k.last
	d_value = stoch_k.last(d).sma
	# puts k_value
	# n=0
	# d.times do
	# 	n+=1
	# 	d_stochrsi<<stoch_rsi_k(d_data, rsi_period, stoch_period, k)
	# 	d_data.pop
	# 	# puts n
	# end
	values = {"d" => d_value, "k" => k_value}
	return values
end
data = 100.times.map{ 20 + Random.rand(11) } 
# puts full_stoch_rsi(data, 14, 14, 4, 3)