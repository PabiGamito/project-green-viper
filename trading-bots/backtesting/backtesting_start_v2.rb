# require_relative "../bitfinex/bitfinex.rb"
require 'colorize'
require_relative "../indicators/rsi.rb"
require_relative "../indicators/stochastic.rb"
require_relative "../indicators/macd.rb"
require_relative "../indicators/atr.rb"
require_relative "ema_stochastic_strategy.rb"
require_relative "simple_ema.rb"

@thirty_min_raw_data = bitfinex_raw_data("30m", 999999)
@thirty_min_prices = bitfinex_prices("30m", 999999)
@five_min_raw_data = bitfinex_raw_data("5m", 999999)
@five_min_prices = bitfinex_prices("5m", 999999)

@btc_balance = 1
buy=false
sell=true
@usd_balance = 0
@last_sold=0
@last_bought=0
@gain=0
# @gain-=377.38
@gain_trades=0
@loss=0
@loss_trades=0

def buy(price)
	@last_bought=price
	@last_action="bought"
	puts "Bought at #{price}"
	puts @btc_balance+=(@usd_balance/price)*(99.8/100)
	if @last_sold<price
		puts "LOSS: Last-Sold: #{@last_sold}".red
		@loss_trades+=1
	 	# @loss-=((price*(100.2/100))-(@last_sold)).abs
	 	# puts ((price*(100.2/100))-(@last_sold)).abs
		if ((price*(100.2/100))-(@last_sold)).abs>5
			# sleep(10)
		end
	else
		puts "GAIN: Last-Sold: #{@last_sold}".green
		@gain_trades+=1
		# @gain+=((price*(100.2/100))-(@last_sold)).abs
	end
	puts "====="
	@usd_balance=0
	@trades+=1
end

def sell(price)
	@last_sold=price
	@last_action="sold"
	puts "Sold at #{price}"
	puts @usd_balance+=(@btc_balance*price)*(99.8/100)
	if @last_bought>price*(99.8/100)
		puts "LOSS: Last-Bought: #{@last_bought}".red
		@loss_trades+=1
		@loss-=((price*(99.8/100))-(@last_sold)).abs
		if ((price*(99.8/100))-(@last_sold)).abs>5
			sleep(10)
		end
	else
		puts "GAIN: Last-Bought: #{@last_bought}".green
		@gain_trades+=1
		@gain+=((price*(99.8/100))-(@last_sold)).abs
	end
	puts "====="
	@btc_balance=0
	@trades+=1
end

@buy_stop_loss_activated=false
@sell_stop_loss_activate=false
@trades=0

#Parameters
stochastic_period=5
stochastic_k=3
stochastic_d=2
macd_short=5
macd_long=15
atr_ma=9
open_ema=6
close_ema=5
main_ema=50

puts (@five_min_prices.count-50)

(@five_min_prices.count-50).times do
	@five_min_raw_data.shift
	@five_min_prices.shift
	@short_raw_data=@five_min_raw_data.first(50)
	@short_prices=@five_min_prices.first(50)

if @short_prices.count == 50
	open_prices=[]
	@short_raw_data.each do |data|
		open_prices << data["open"].to_f
	end

	if stochastic(@short_raw_data.last(50), stochastic_period, stochastic_k, stochastic_d)["k"]<20
		@crossed_lower_line=true
		@crossed_upper_line=false
	elsif stochastic(@short_raw_data.last(50), stochastic_period, stochastic_k, stochastic_d)["k"]>80
		@crossed_upper_line=true
		@crossed_lower_line=false
	end

	# puts "O:#{@short_raw_data.last["open"]} C:#{@short_raw_data.last["close"]} L:#{@short_raw_data.last["low"]} H:#{@short_raw_data.last["high"]}"

	begin
		@crossover_time+=1
	rescue Exception => e
		puts e
	end

	begin
		if @stop_loss>=@short_raw_data.last
			if @stop_loss*((100-0.5)/100)>@short_raw_data.last
				sell(@stop_loss*((100-0.5)/100))
			else
				sell(@short_raw_data.last)
			end
		end
	rescue Exception => e
		
	end

	#CROSS-OVER SIGNAL
	# 1. The 34 Period EMA must be increasing from one candle to the next (this is visually
	# easy to see when the line is represented as a dot.
	# 2. The 8 Period SMA must be above the 34 Period EMA on the signal candle.
	# 3. The Stochastic must crossover and begin increasing.
	if @short_prices.last(34).ema>@short_prices.last(35).first(34).ema && 
		@short_prices.last(8).sma>@short_prices.last(34).ema &&
		stochastic(@short_raw_data, 8, 3, 3)["k"]>stochastic(@short_raw_data, 8, 3, 3)["d"] &&
		stochastic(@short_raw_data, 8, 3, 3)["k"]>stochastic(@short_raw_data.first(@short_raw_data.count-1), 8, 3, 3)["k"]
		buy(@short_prices.last.to_f)
		if @crossover_time==nil || @crossover_time>4
			@crossover_time=0
			@entry=@short_raw_data.last["high"].to_f+0.01
		end
	end

	#CANCEL ENTRY
	# 4. The crossover candle must be broken within four candles of the crossover (if the low of
	# the crossover candle is broken first then you must delete the trade).
	# TODO: Check that I understood the candle break (delete if on first)
	if @crossover_time==1 && @entry<@short_prices.last
		# "deletes trade entry"
		@entry=Float::INFINITY
	end

	#BUY SIGNAL
	# 5. Your entry is placed above the high of the crossover candle (you need to make sure you
	# add the spread plus 1-2 pips.
	if @crossover_time>1 && @crossover_time<=4 && 
		@entry<@short_prices.last &&
		@last_action=="sold"
		buy(@short_prices.last.to_f)
		#SET STOP-LOSS
		@stop_loss=@short_raw_data.last
	end

	#SELL
	if stochastic(@short_raw_data, 8, 3, 3)["k"]<stochastic(@short_raw_data, 8, 3, 3)["d"] &&
		stochastic(@short_raw_data, 8, 3, 3)["k"]>20 &&
		@last_action=="bought"
		sell(@short_prices.last.to_f)
	end

end
end