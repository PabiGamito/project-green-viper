require_relative "../bitfinex/bitfinex.rb"
require 'colorize'
require_relative "../indicators/rsi.rb"
require_relative "../indicators/stochastic.rb"
require_relative "../indicators/macd.rb"
require_relative "../indicators/atr.rb"
require_relative "ema_stochastic_strategy.rb"
# require_relative "simple_ema.rb"

@raw_data = bitfinex_raw_data("5m", 999999)
@prices = bitfinex_prices("5m", 999999)
@last_bought=@prices.first(50).last
@btc_balance = 1.0
@usd_balance = 0.0
@initial_balance=@btc_balance*@prices.first(50).last + @usd_balance
@last_sold=0
@gain=0
@gain_trades=0
@loss=0
@loss_trades=0
final_price=@prices.last
initial_price=@prices.first(50).last

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

def buy(price, amount=@usd_balance/price)
	@last_bought=price
	puts "Bought at #{price}"
	puts @btc_balance+=amount*(99.8/100)
	# if @last_bought*(100.2/100)<price*(99.8/100)
	# 	puts "LOSS: Last-Sold: #{@last_sold}".red
	# 	# @loss_trades+=1
	# 	# @loss-=((price*(100.2/100))-(@last_sold)).abs
	# 	# sleep(5)
	# else
	# 	puts "GAIN".green
	# 	# @gain_trades+=1
	# 	# @gain+=((price*(100.2/100))-(@last_sold)).abs
	# end
	puts "====="
	@usd_balance-=amount*price
	# @trades+=1
end

def sell(price, amount=@btc_balance)
	if amount<@btc_balance
		@take_profit=true
	else
		@take_profit=false
	end
	@last_sold=price
	puts "Sold at #{price}"
	puts @usd_balance+=amount*price*(99.8/100)
	if @last_bought*(100.2/100)>price*(99.8/100)
		puts "LOSS: Last-Bought: #{@last_bought}".red
		@loss_trades+=1
		@loss-=(price*(99.8/100)-@last_bought*(100.2/100)).abs
		# sleep(5)
	else
		puts "GAIN".green
		@gain_trades+=1
		@gain+=(price*(99.8/100)-@last_bought*(100.2/100)).abs
	end
	puts "====="
	@btc_balance-=amount
	# @trades+=1
end

@stop_loss=@raw_data.last["low"]
@take_profit=false

(@prices.count-50).times do
	@raw_data.shift
	@prices.shift
	raw_data=@raw_data.first(50)
	prices=@prices.first(50)

	if @stop_loss<@raw_data.last["low"]
		@stop_loss=@raw_data.last["low"]
	end

	# Take Profit- 1/4 a certain price 1/2 at other
	if (@last_bought*(100.25/100))/(99.8/100)<raw_data.last["high"].to_f && @btc_balance>=0.2
		#Sell at (@last_bought*(100.25/100))/(99.8/100) or close price
		sell((@last_bought*(100.25/100))/(99.8/100))
		@last_sell_time=raw_data.last["date"].to_f
	end

	# Stop-loss Sell
	# if @btc_balance!=0 && ((@take_profit && (@last_bought*(100.21/100))/(99.8/100)>prices.last)) || prices.last <= @stop_loss)
	# 	sell(prices.last)
	# 	# sleep(5)
	# end

	if prices.count == 50

		open_prices=[]
		raw_data.each do |data|
			open_prices << data["open"].to_f
		end

		puts "O:#{raw_data.last["open"]} C:#{raw_data.last["close"]} L:#{raw_data.last["low"]} H:#{raw_data.last["high"]}"

		if prices.last<prices.last(50).ema
			@above_ema=false
			@below_ema=true
		end

		if raw_data.last["high"]>prices.last(50).ema && @below_ema && atr(raw_data, 1)>1.5
			buy(prices.last.to_f)
			@stop_loss=prices.last.to_f
			@above_ema=true
			@below_ema=false
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