require_relative "okcoin.rb"
require 'colorize'
require_relative "indicators/rsi.rb"
require_relative "indicators/stochastic.rb"
require_relative "indicators/macd.rb"
require_relative "indicators/atr.rb"
# require_relative "ema_stochastic_strategy.rb"
require 'active_record'
ActiveRecord::Base.establish_connection( 
 :adapter => "mysql2",
 :host => "localhost",
 :username=>"root",
 :password=>"mouse16081999",
 :database => "okcoin"
)

class HistoricalData < ActiveRecord::Base
end

@five_min_raw_data = okcoin_raw_data("1m", 999999)
@five_min_prices = okcoin_prices("1m", 999999)

final_price=@five_min_prices.last
initial_price=@five_min_prices.first(100).last

#Parameters
stochastic_period=5
stochastic_k=3
stochastic_d=2
macd_short=8
macd_long=17
atr_ma=12
open_ema=2#6
close_ema=1#5
main_ema=50

# puts "Shift?"
# shift=gets.chomp.to_i

# @five_min_raw_data.shift(shift)
# @five_min_prices.shift(shift)

# @initial_five_min_raw_data=[]
# @five_min_raw_data.each do |data|
# 	@initial_five_min_raw_data << data
# end
# @initial_five_min_prices=[]
# @five_min_prices.each do |data|
# 	@initial_five_min_prices << data
# end

# TODO: Place orders before price atcually hits expected high

@gain=0
@gain_trades=0
@loss=0
@loss_trades=0

# ema_stochastic_strategy
@btc_balance = 1.0
@usd_balance = 0.0
@initial_balance=@btc_balance*@five_min_prices.first(100).last + @usd_balance
@last_sold=0
@last_bought=@five_min_prices.first(100).last

# puts @thirty_min_prices

# n=0
# # thirty_min_raw_data=[]
# # @long_prices=[]
# # @five_min_raw_data=[]
# # @short_prices=[]
# # @long_raw_data = []
# # @short_raw_data = []
# z=0

# @best_return=0

# @bought_price=@five_min_prices.first(50).last
# @sold_price=@five_min_prices.first(50).last
# @stop_loss=@five_min_raw_data.first(50).last(8+4+3)*(99.7/100)


# Indicators
# MACD: 12,26,1 ( 1 means nothing )
# Stochastic: 5,3,3
# EMA: 5 to the close
# EMA: 5 to the open

# *no trades during news times
# *Risk is set to 1%
# *Take profit is random based on market conditions but I'll usually cash out based on reversal patterns or a cross of the two ema's
# *Trade signals are only confirmed on closed candles/bars.

def buy(price, amount=@usd_balance/price)
	@last_bought=price
	puts "Bought at #{price}"
	puts @btc_balance+=amount#*(99.8/100)
	if @last_sold<price
		puts "LOSS: Last-Sold: #{@last_sold}"
		# @loss_trades+=1
		# @loss-=((price*(100.2/100))-(@last_sold)).abs
		# sleep(5)
	else
		puts "GAIN"
		# @gain_trades+=1
		# @gain+=((price*(100.2/100))-(@last_sold)).abs
	end
	puts "====="
	@usd_balance-=amount*price
	@trades+=1
end

def sell(price, amount=@btc_balance)
	if amount<@btc_balance
		@take_profit=true
	else
		@take_profit=false
	end
	@last_sold=price
	puts "Sold at #{price}"
	puts @usd_balance+=amount*price#*(99.8/100)
	if @last_bought>price
		puts "LOSS: Last-Bought: #{@last_bought}".red
		@loss_trades+=1
		@loss-=(price-@last_bought).abs
		# sleep(5)
	else
		puts "GAIN".green
		@gain_trades+=1
		@gain+=(price-@last_bought).abs
	end
	puts "====="
	@btc_balance-=amount
	@trades+=1
end

@buy_stop_loss_activated=false
@sell_stop_loss_activate=false
@trades=0


# 50.times do
# stochastic_period+=1
# 10.times do
# stochastic_k+=1
# 10.times do
# stochastic_d+=1
# 20.times do
# macd_short+=1
# macd_long=macd_short+1
# 50.times do
# macd_short+=1
# 50.times do
# atr_ma+=1
# 20.times do
# open_ema+=1
# 20.times do
# close_ema+=1
# 50.times do
# main_ema+=1

#STARTS
(@five_min_prices.count).times do

@five_min_raw_data.shift
@five_min_prices.shift

@short_raw_data=@five_min_raw_data.first(100)
@short_prices=@five_min_prices.first(100)

if @short_prices.count == 100
	# puts "running"
	# puts @last_price=@short_prices.last.to_f
	open_prices=[]
	@short_raw_data.each do |data|
		open_prices << data["open"].to_f
	end

	# puts @short_raw_data.last
	# puts stochastic(@short_raw_data.last(50), 5, 3, 3)["k"]
	if stochastic(@short_raw_data.last(100), stochastic_period, stochastic_k, stochastic_d)["k"]<20
		# puts "Crossed-Lower-Line"
		@crossed_lower_line=true
		@crossed_upper_line=false
	elsif stochastic(@short_raw_data.last(100), stochastic_period, stochastic_k, stochastic_d)["k"]>80
		# puts "Crossed-Upper-Line"
		@crossed_upper_line=true
		@crossed_lower_line=false
	end

	puts "O:#{@short_raw_data.last["open"]} C:#{@short_raw_data.last["close"]} L:#{@short_raw_data.last["low"]} H:#{@short_raw_data.last["high"]}"

	begin
		#Update Stop-loss
		if @short_raw_data.last["low"].to_f>=@sell_stop_loss
			@sell_stop_loss=@short_raw_data.last["low"].to_f
		elsif @short_raw_data.last["high"].to_f<=@buy_stop_loss
			@buy_stop_loss=@short_raw_data.last["high"].to_f
		end

		# Stop-loss sell at bought price.
		# if @last_bought <= @short_raw_data.last["low"].to_f && @btc_balance!=0 && @sell_stop_loss_activate==false && atr(@short_raw_data, 1)>1.5
		# 	puts "Stop-loss Sell".red
		# 	sell(@last_bought)
		# 	@sell_stop_loss_activate=true
		# end

		#Proccess Stop-loss Activation if Needed
		if @short_raw_data.last["close"].to_f<=@sell_stop_loss && @sell_stop_loss_activate==false && atr(@short_raw_data, 1)>1.5 && stochastic(@short_raw_data.last(50), stochastic_period, stochastic_k, stochastic_d)["k"]>20 #&& atr(@short_raw_data, atr_ma)>1 #&& @short_prices.last(6).first(5).ema>@short_prices.last(5).ema
			puts "Stop-loss Sell".red
			sell(@short_raw_data.last["close"].to_f)
			@sell_stop_loss_activate=true
		#NOTE: Losses always occur on stop-loss buy (at least in an uptrend, so make sure stop-loss sell does not oversell)
		elsif @short_raw_data.last["low"].to_f>=@buy_stop_loss && atr(@short_raw_data, 1)>1.5 && @buy_stop_loss_activated==false && stochastic(@short_raw_data.last(50), stochastic_period, stochastic_k, stochastic_d)["k"]<80 && @short_raw_data.last["close"].to_f>@short_raw_data.last["open"].to_f && @usd_balance!=0 && stochastic(@short_raw_data.last(50), stochastic_period, stochastic_k, stochastic_d)["k"]>20 && @short_prices.last(close_ema).ema>open_prices.last(open_ema).ema && @crossed_lower_line && @short_prices.last(main_ema).ema<@short_prices.last#&& macd(@short_prices, macd_short, macd_long, 1)>0 && macd(@short_prices, macd_short, macd_long, 1)>macd(@short_prices.first(@short_prices.count-1), macd_short, macd_long, 1) && stochastic(@short_raw_data.last(50), stochastic_period, stochastic_k, stochastic_d)["k"]>20 && @short_prices.last(close_ema).ema>open_prices.last(open_ema).ema && @crossed_lower_line && @short_prices.last(main_ema).ema<@short_prices.last
			puts "Stop-loss Buy".green
			buy(@short_raw_data.last["close"].to_f)
			@bought_low=@short_raw_data.last["low"].to_f
			@buy_stop_loss_activated=true
		end

		# if (@last_bought*(100.25/100))/(99.8/100)<@short_raw_data.last["high"].to_f && @btc_balance!=0
		# 	sell((@last_bought*(100.25/100))/(99.8/100), @btc_balance/2)
		# end

		# if @take_profit && @last_bought*(100.2/100)>=@short_prices.last.to_f
		# 	sell(@short_prices.last.to_f)
		# end

	rescue
	end

	# 	Buy Signal
	# a) When the stochastic crosses up from the 20 line and is not ovebought;
	# b) The MACD closses higher than the previous time interval;
	# c) The Signal candle/bar closes higher bullish;
	# d) The 5 ema to the close has crossed the 5 ema to the open;
	# Stop Loss is the low of the previous candle or 20 pips but 20 pip min.
	# Close when the 5 ema to the close has crossed the 5 ema to the open

	# sleep(2)

	if @take_profit==false && stochastic(@short_raw_data.last(50), stochastic_period, stochastic_k, stochastic_d)["k"]>20 && stochastic(@short_raw_data.last(50), stochastic_period, stochastic_k, stochastic_d)["k"]<80 && macd(@short_prices, macd_short, macd_long, 1)>macd(@short_prices.first(@short_prices.count-1), macd_short, macd_long, 1)  && @short_raw_data.last["close"].to_f>@short_raw_data.last["open"].to_f && @short_prices.last(close_ema).ema>open_prices.last(open_ema).ema && @crossed_lower_line && @short_prices.last(main_ema).ema<@short_prices.last && macd(@short_prices, macd_short, macd_long, 1)>0 && atr(@short_raw_data, atr_ma)>1 && @usd_balance!=0#&& atr(@short_raw_data, 1)>atr(@short_raw_data, 9)
		buy(@short_prices.last.to_f)
		@bought_low=@short_raw_data.last["low"].to_f
		@sell_stop_loss=@short_prices.last.to_f
		# if @short_raw_data.last["low"].to_f>@short_prices.last*(0.5/100)
		# 	@sell_stop_loss=@short_raw_data.last["low"].to_f
		# else
		# 	@sell_stop_loss=@short_prices.last.to_f*(0.5/100)
		# end
		@sell_stop_loss_activate=false
	end


	# Sell Signal
	# a) When the stochastic crosses down from the 80 line and is not oversold;
	# b) The MACD closses lower than the previous time interval;
	# c) The Signal candle/bar closes lower bearish;
	# d) The 5 ema to the close has crossed the 5 ema to the open;
	# Stop Loss is the high of the previous candle or 20 pips but 20 pip min.
	# Close is based on price action.
	if stochastic(@short_raw_data.last(50), stochastic_period, stochastic_k, stochastic_d)["k"]>20 && stochastic(@short_raw_data.last(50), stochastic_period, stochastic_k, stochastic_d)["k"]<80 && macd(@short_prices, macd_short, macd_long, 1)<macd(@short_prices.first(@short_prices.count-1), macd_short, macd_long, 1) && @short_raw_data.last["close"].to_f<@short_raw_data.last["open"].to_f && @short_prices.last(close_ema).ema<open_prices.last(open_ema).ema && @crossed_upper_line && @btc_balance!=0#&& macd(@short_prices, 12, 26, 1)<0
		sell(@short_prices.last.to_f)
		@buy_stop_loss=@short_prices.last.to_f
		# @buy_stop_loss=@short_raw_data.last["high"].to_f
		@buy_stop_loss_activated=false
	end
end

end

@end_balance=@btc_balance*final_price+@usd_balance

puts "Gain: #{@gain}: #{@gain_trades}".green
puts "Loss: #{@loss}: #{@loss_trades}".red
puts "Earnings: #{@end_balance-@initial_balance}=#{((@end_balance-@initial_balance)/@initial_balance)*100}%".yellow
puts "Price Change: #{((final_price-initial_price)/initial_price)*100}%"
puts ""
puts "stochastic_period=#{stochastic_period}"
puts "stochastic_k=#{stochastic_k}"
puts "stochastic_d=#{stochastic_d}"
puts "macd_short=#{macd_short}"
puts "macd_long=#{macd_long}"
puts "atr_ma=#{atr_ma}"
puts "open_ema=#{open_ema}"
puts "close_ema=#{close_ema}"
puts "main_ema=#{main_ema}"

# puts @initial_five_min_prices.count

# puts @best_return
# puts (@btc_balance*@initial_five_min_prices.last)+(@usd_balance/@initial_five_min_prices.last)
# puts @trades
# puts stochastic_period
# puts stochastic_k
# puts stochastic_d
# puts macd_short
# puts macd_long
# puts atr_ma
# puts open_ema
# puts close_ema
# puts main_ema
# puts " "

# if @best_return<((@btc_balance*@initial_five_min_prices.last)+(@usd_balance/@initial_five_min_prices.last)) && @trades>=3
# 	@best_return=(@btc_balance*@initial_five_min_prices.last)+(@usd_balance/@initial_five_min_prices.last)
# 	best_stochastic_period=stochastic_period
# 	best_stochastic_k=stochastic_k
# 	best_stochastic_d=stochastic_d
# 	best_macd_short=macd_short
# 	best_macd_long=macd_long
# 	best_atr_ma=atr_ma
# 	best_open_ema=open_ema
# 	best_close_ema=close_ema
# 	best_main_ema=main_ema

# 	puts "\e[H\e[2J"
# 	puts "best_stochastic_period#{best_stochastic_period}"
# 	puts "best_stochastic_k#{best_stochastic_k}"
# 	puts "best_stochastic_d#{best_stochastic_d}"
# 	puts "best_macd_short#{best_macd_short}"
# 	puts "best_macd_long#{best_macd_long}"
# 	puts "best_atr_ma#{best_atr_ma}"
# 	puts "best_open_ema#{best_open_ema}"
# 	puts "best_close_ema#{best_close_ema}"
# 	puts "best_main_ema#{best_main_ema}"
# 	puts "BEST RETURN: #{@best_return}"
# end

# #Reset
# @btc_balance=1
# @usd_balance=0
# @five_min_raw_data = @initial_five_min_raw_data.dup
# @five_min_prices = @initial_five_min_prices.dup
# buy=false
# sell=true
# n=0
# z=0
# @bought_price=@five_min_prices.first
# @sold_price=@five_min_prices.first
# @stop_loss=@five_min_raw_data.first(8+4+3)*(99.7/100)
# buy_signal=false
# sell_signal=false
# @trades=0

# #ENDS
# end
# main_ema=5
# end
# close_ema=2
# end
# open_ema=2
# end
# atr_ma=1
# end
# macd_long=3
# end
# macd_short=2
# end
# stochastic_d=1
# end
# stochastic_k=1
# end
# stochastic_period=2









# 99999.times do
# begin
# 	@five_min_prices.shift
# 	@five_min_raw_data.shift
# 	# puts stochastic(@five_min_raw_data.first(8+4+3), 8, 4, 3)["k"].to_f<20
# 	if stochastic(@five_min_raw_data.first(8+4+3), 8, 4, 3)["k"].to_f<20
# 		buy_signal=true
# 	elsif stochastic(@five_min_raw_data.first(8+4+3), 8, 4, 3)["k"].to_f>80
# 		sell_signal=true
# 	end
# 	if sell_signal && stochastic(@five_min_raw_data.first(8+4+3), 8, 4, 3)["k"].to_f<80
# 		sell=true
# 		sell_signal=false
# 	elsif buy_signal && stochastic(@five_min_raw_data.first(8+4+3), 8, 4, 3)["k"].to_f>20
# 		buy=true
# 		buy_signal=false
# 	end
# 	if @five_min_prices.first(8+4+3).last(5).ema<@five_min_raw_data.first(8+4+3).last["close"].to_f
# 		if stochastic(@five_min_raw_data.first(8+4+3), 8, 4, 3)["k"].to_f > stochastic(@five_min_raw_data.first(8+4+3), 8, 4, 3)["d"].to_f && buy && @sold_price*(100.2/100)<=@five_min_raw_data.first(8+4+3).last["close"].to_f
# 			puts "buy at #{@five_min_raw_data.first(8+4+3).last["close"]}"
# 			@btc_balance += (@usd_balance/(@five_min_raw_data.first(8+4+3).last["close"].to_f))*(99.8/100)
# 			@usd_balance = 0
# 			@bought_price = @five_min_raw_data.first(8+4+3).last["close"].to_f
# 			buy=false
# 			# sell=true
# 		elsif stochastic(@five_min_raw_data.first(8+4+3), 8, 4, 3)["k"].to_f < stochastic(@five_min_raw_data.first(8+4+3), 8, 4, 3)["d"].to_f && sell
# 			puts "sell at #{@five_min_raw_data.first(8+4+3).last["close"]}"
# 			# puts @five_min_raw_data.first(8+4+3).last["close"].to_f
# 			# puts @btc_balance
# 			@usd_balance += @btc_balance*(@five_min_raw_data.first(8+4+3).last["close"].to_f)*(99.8/100)
# 			@btc_balance = 0
# 			@sold_price = @five_min_raw_data.first(8+4+3).last["close"].to_f
# 			# buy=true
# 			sell=false
# 		end
# 	end
# 	if @five_min_raw_data.first(8+4+3).last["close"].to_f<@stop_loss
# 		puts "sell at #{@five_min_raw_data.first(8+4+3).last["close"]}"
# 		# puts @five_min_raw_data.first(8+4+3).last["close"].to_f
# 		# puts @btc_balance
# 		@usd_balance += @btc_balance*@stop_loss*(99.8/100)
# 		@btc_balance = 0
# 		@sold_price = @five_min_raw_data.first(8+4+3).last["close"].to_f
# 		buy=true
# 		sell=false
# 	end
# 	if @five_min_raw_data.first(8+4+3).last["close"].to_f*(99.7/100)>@stop_loss
# 		@stop_loss=@five_min_raw_data.first(8+4+3).to_f*(99.7/100)
# 	end

	# if @five_min_prices.first.to_f>@bought_price*(0.25/100) && @btc_balance!=0
	# 	@usd_balance+=@btc_balance*@five_min_prices.first.to_f
	# 	@btc_balance=0
	# 	@sold_price=@five_min_prices.first.to_f
	# 	puts "sell"
	# elsif @five_min_prices.first.to_f>@sold_price*(0.25/100) && @usd_balance!=0
	# 	@btc_balance+=@usd_balance/@five_min_prices.first.to_f
	# 	@usd_balance=0
	# 	@bought_price=@five_min_prices.first.to_f
	# 	puts "buy"
	# end
# rescue
# end
# end

# puts @usd_balance
# puts @btc_balance

# require 'active_record'

# ActiveRecord::Base.establish_connection( 
#  :adapter => "mysql2",
#  :host => "localhost",
#  :username=>"root",
#  :password=>"mouse16081999",
#  :database => "bitfinex"
# )

# class HistoricalData < ActiveRecord::Base
# end

# @five_min_raw_data = []
# @five_min_prices = []
# @long_raw_data = []
# @long_prices = []
# @thirty_min_prices = []
# @thirty_min_raw_data = []
# @thirty_min_prices = []


# HistoricalData.all.each do |data|
# 	@five_min_raw_data << {"date" => data["date"].to_i, "open" => data["open"].to_f, "close" => data["close"].to_f, "high" => data["high"].to_f, "low" => data["low"].to_f, "volume" => data["volume"].to_f}
# 	@five_min_prices << data["close"].to_f
# end

# n=0
# closes=[]
# opens=[]
# lows=[]
# highs=[]
# dates=[]
# volumes=[]
# @five_min_raw_data.each do |data|
# 	n+=1
# 	if n%6==0
# 		@thirty_min_raw_data << {"date" => dates.first, "open" => opens.first, "close" => closes.last, "high" => highs.max, "low" => lows.min}
# 		@thirty_min_prices << closes.last
# 		closes.shift(6)
# 		opens.shift(6)
# 		lows.shift(6)
# 		highs.shift(6)
# 		dates.shift(6)
# 		volumes.shift(6)
# 	else
# 		closes<<data["close"].to_f
# 		opens<<data["open"].to_f
# 		lows<<data["low"].to_f
# 		highs<<data["high"].to_f
# 		dates<<data["date"].to_f
# 		volumes<<data["volume"].to_f
# 	end
# end

# n=0
# z=0






# period=8
# k=4
# d=3

# 99999.times do
# begin
# n+=1
# z+=1
# if n==6
# 	n=0
# 	@long_raw_data << @thirty_min_raw_data.first
# 	@thirty_min_raw_data.shift
# 	@long_prices << @thirty_min_prices.first
# 	@thirty_min_prices.shift
# end
# @short_raw_data << @five_min_raw_data.first
# @five_min_raw_data.shift
# @short_prices << @five_min_prices.first
# @five_min_prices.shift
# if @short_raw_data.last["close"].to_f != 0
# # if @short_prices.last.to_f == @long_prices.last.to_f
# # 	if @wesh
# # 		puts "YOYOYOY: Something is fucked up here"
# # 		puts @short_raw_data.last(6)
# # 		puts "===="
# # 		puts @long_raw_data.last
# # 	end
# # 	@wesh=true
# # else
# # 	@wesh=false
# # end
# if @short_prices.last.to_f!=0
# 	# puts stochastic(@long_raw_data, 8, 4, 3)["k"].to_f
# 	# puts stochastic(@long_raw_data, 8, 4, 3)["d"].to_f
# 	if stochastic(@long_raw_data, period, k, d)["k"].to_f > stochastic(@long_raw_data, period, k, d)["d"].to_f && stochastic(@long_raw_data, period, k, d)["k"].to_f > stochastic(@long_raw_data.first(@long_raw_data.count-1), period, k, d)["k"].to_f
# 		if stochastic(@short_raw_data, period, k, d)["k"].to_f > stochastic(@short_raw_data, period, k, d)["d"].to_f && stochastic(@short_raw_data, period, k, d)["k"].to_f > stochastic(@short_raw_data.first(@short_raw_data.count-1), period, k, d)["k"].to_f
# 			if @long_prices.last(13).ema<@long_prices.last(5).ema && @long_prices.last(5).ema > @long_prices.first(@long_prices.count-1).last(5).ema
# 				if @btc_balance==0
# 					puts "Buying at #{@short_prices.last.to_f}"
# 				end
# 				@btc_balance += @usd_balance/@short_prices.last.to_f
# 				@usd_balance = 0
# 			end
# 		end
# 	elsif stochastic(@long_raw_data, period, k, d)["k"].to_f < stochastic(@long_raw_data, period, k, d)["d"].to_f
# 		if @usd_balance==0
# 			puts "Selling at #{@short_prices.last.to_f}"
# 		end
# 		@usd_balance += @btc_balance*@short_prices.last.to_f
# 		@btc_balance = 0
# 	end
# end
# end
# rescue
# end
# end

# puts "Done: USD: #{@usd_balance} | BTC: #{@btc_balance}"






































# require_relative "../bitfinex/bitfinex.rb"
# require_relative "../indicators/rsi.rb"
# require_relative "../indicators/stochastic.rb"
# require_relative "ema_stochastic_strategy.rb"
# require_relative "simple_ema.rb"

# @thirty_min_raw_data = bitfinex_raw_data("30m", 999999)
# @thirty_min_prices = bitfinex_prices("30m", 999999)
# @five_min_raw_data = bitfinex_raw_data("5m", 999999)
# @five_min_prices = bitfinex_prices("5m", 999999)

# # ema_stochastic_strategy
# @btc_balance = 1
# @usd_balance = 0

# puts @thirty_min_prices

# n=0
# thirty_min_raw_data=[]
# @long_prices=[]
# five_min_raw_data=[]
# @short_prices=[]
# z=0


# 99999.times do
# n+=1
# z+=1
# if n==6
# 	n=0
# 	thirty_min_raw_data << @thirty_min_raw_data.first
# 	@thirty_min_raw_data.shift
# 	@long_prices << @thirty_min_prices.first
# 	@thirty_min_prices.shift
# end
# five_min_raw_data << @five_min_raw_data.first
# @five_min_raw_data.shift
# @short_prices << @five_min_prices.first
# @five_min_prices.shift
# if z>6*15*2
# 	puts stochastic(@long_prices, 8, 3, 4, 3)["k"].to_f
# 	puts stochastic(@long_prices, 8, 3, 4, 3)["d"].to_f
# 	if stochastic(@long_prices, 8, 3, 4, 3)["k"].to_f > stochastic(@long_prices, 8, 3, 4, 3)["d"].to_f && stochastic(@long_prices, 8, 3, 4, 3)["k"].to_f > stochastic(@long_prices.first(@long_prices.count-1), 8, 3, 4, 3)["k"].to_f
# 		if stochastic(@short_prices, 8, 3, 4, 3)["k"].to_f > stochastic(@short_prices, 8, 3, 4, 3)["d"].to_f && stochastic(@short_prices, 8, 3, 4, 3)["k"].to_f > stochastic(five_min_prices.first(five_min_prices.count-1), 8, 3, 4, 3)["k"].to_f
# 			if @long_prices.last(13)<@long_prices.last(5) && @long_prices.first(@long_prices).last(5)>@long_prices.first(@long_prices.count-1).last(5)
# 				puts "Buying"
# 				@btc_balance += @usd_balance/@short_prices.last
# 				@usd_balance = 0
# 			end
# 		end
# 	elsif stochastic(@long_prices, 8, 3, 4, 3)["k"].to_f < stochastic(@long_prices, 8, 3, 4, 3)["d"].to_f
# 		puts "Selling"
# 		@usd_balance += @btc_balance*@short_prices.last
# 		@btc_balance = 0
# 	end
# end

# puts "Done: USD: #{@usd_balance} | BTC: #{@btc_balance}"
# end