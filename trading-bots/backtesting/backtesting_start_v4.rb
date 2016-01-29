# require_relative "../bitfinex/bitfinex.rb"
require 'colorize'
require_relative "../indicators/rsi.rb"
require_relative "../indicators/stochastic.rb"
require_relative "../indicators/macd.rb"
require_relative "../indicators/atr.rb"
require_relative "ema_stochastic_strategy.rb"
# require_relative "simple_ema.rb"

@thirty_min_raw_data = bitfinex_raw_data("30m", 999999)
@thirty_min_prices = bitfinex_prices("30m", 999999)
@five_min_raw_data = bitfinex_raw_data("2h30m", 999999)
@five_min_prices = bitfinex_prices("2h30m", 999999)

@btc_balance = 1
@last_action="bought"
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
		if ((price*(100.2/100))-(@last_sold)).abs>1
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
		if ((price*(99.8/100))-(@last_sold)).abs>1
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

@stop_loss=@five_min_raw_data.last["low"]

(@five_min_prices.count-50).times do
	@five_min_raw_data.shift
	@five_min_prices.shift
	@short_raw_data=@five_min_raw_data.first(50)
	@short_prices=@five_min_prices.first(50)

	if @stop_loss<@five_min_raw_data.last["low"]
		@stop_loss=@five_min_raw_data.last["low"]
	end

	if @stop_loss>@short_prices.last && @last_action=="bought" && atr(@short_raw_data, 1)>2
		sell(@short_prices.last)
	end

	if @short_prices.count == 50
		if @short_prices.last(8).ema>@short_prices.last(17).ema && 
			stochastic(@short_raw_data, 8, 3, 3)["k"]>stochastic(@short_raw_data, 8, 3, 3)["d"] &&
			stochastic(@short_raw_data, 8, 3, 3)["k"]<80 &&
			@last_action=="sold"
			buy(@short_prices.last)
			@stop_loss=@five_min_raw_data.last["low"]
		elsif @short_prices.last(8).ema<@short_prices.last(17).ema && 
			stochastic(@short_raw_data, 8, 3, 3)["k"]<stochastic(@short_raw_data, 8, 3, 3)["d"] &&
			stochastic(@short_raw_data, 8, 3, 3)["k"]>20 &&
			@last_action=="bought"
			sell(@short_prices.last)
		end
	end
end