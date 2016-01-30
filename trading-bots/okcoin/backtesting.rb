require_relative "get_csv_data.rb"
require 'colorize'
require 'csv'
require_relative "indicators/rsi.rb"
require_relative "indicators/stochastic.rb"
require_relative "indicators/macd.rb"
require_relative "indicators/atr.rb"

# require_relative "../indicators/rsi.rb"
# require_relative "../indicators/stochastic.rb"
# require_relative "../indicators/macd.rb"
# require_relative "../indicators/atr.rb"

# TODO: Add parameter for only trading when price is above longer ema 30m+.

require 'active_record'
ActiveRecord::Base.establish_connection( 
 :adapter => "mysql2",
 :host => "localhost",
 # :host => "128.199.144.250",
 :username=>"root",
 :password=>"mouse16081999",
 :database => "okcoin"
)

class HistoricalData < ActiveRecord::Base
end

@file="backtesting.csv"

#Remove all data from file, so I get a blank file
File.open(@file, 'w') {|file| file.truncate(0) }

CSV.open(@file, "wb") do |csv|
  csv << ["date", "bought", "sold", "profit", "stochastic", "ema", "atr", "macd"]
end

# BUY
# Last candle is green (last close > last open) 
# EMA < last price
# Stochastic: 20 < k < 80
# Crossed 20 stochastic line and back up
# MACD > last MACD
# MACD > 0
# ATR > x
# Short data close EMA > short data open EMA 
# SET STOP-LOSS
# Stop-loss = bought price - ATR%

# SELL
# Candle is red (last close < last open) #TODO: Try and remove this and see how it works.
# Stochastic : 20 < k < 80
# Crossed 80 stochastic line and back down
# Macd < last macd
# Close EMA < Open EMA
# stop_loss_buy = price + ART%

# STOP-LOSS-SELL
# Stop-loss auto update to low if higher then previous sell stop-loss
# Close price <= stop-loss
# ATR(short_raw_data, 1) > x
# Stochastic: k>20
# OR
# Simple stop-loss at ATR%

# STOP-LOSS-BUY (if needed)
# Stop-loss auto update to high if lower then previous buy stop-loss
# Last low >= stop_loss 
# ATR > x
# Stochastic : 20 < k < 80 
# close > open 
# close ema > open ema
# Crossed 20 stochastic line and back up 
# ema < last price 

#Methods
def csv(row)
	CSV.open(@file, "a+") do |csv|
	  csv << row
	end
end

def buy(price, amount=nil)
	puts "buying"
	if amount==nil
		amount=@usd/price
	end
	@btc+=amount
	@usd-=amount*price
	@last_bought=price
end

@n=0

def sell(price, amount=@btc, extra_data)
	@n+=1
	puts "selling"
	@usd+=amount*price
	@btc-=amount
	if @last_bought <= price
		puts "Gain".green
	else
		puts "Loss".red
	end
	csv([@short_raw_data.first(50).last["date"], @last_bought, price, ((price-@last_bought)/@last_bought)*100].push(*extra_data))
end

#Get data
require 'CSV'
@short_raw_data = okcoin_raw_data("1m", 1*1440 )
@short_prices = okcoin_prices("1m", 1*1440 )

#Setup
@btc = 1.0
@usd = 0.0
@start_usd = @short_prices.first(50).last*@btc + @usd
@start_time = @short_raw_data.first(50).last["date"]
@last_bought = @short_prices.first(50).last

#Parameters
stochastic_period=5
stochastic_k=3
stochastic_d=2
macd_short=8
macd_long=17
atr_ma=12
open_ema=6#2
close_ema=5#1
main_ema=155
short_ema=17

#Run main scrypt
(@short_prices.count-500).times do
	#Shift all data points by one
	@short_raw_data.shift
	@short_prices.shift
	#Set needed arrays
	short_raw_data = @short_raw_data.first(500)
	short_prices = @short_prices.first(500)
	#Get open prices array
	@open_prices=[]
	short_raw_data.each {|data| @open_prices << data["open"]}
	#Display data
	"O:#{short_raw_data.last["open"]} C:#{short_raw_data.last["close"]} L:#{short_raw_data.last["low"]} H:#{short_raw_data.last["high"]}"
	#Calculate all Variables
	last_close = short_prices.last.to_f
	last_open = short_raw_data.last["open"].to_f
	main_ema_val = short_prices.last(main_ema).ema.to_f
	last_main_ema_val = short_prices.last(main_ema+1).first(main_ema).ema.to_f
	short_ema_val = short_prices.last(short_ema).ema.to_f
	k_stochastic = stochastic(short_raw_data, stochastic_period, stochastic_k, stochastic_d)["k"].to_f
	macd_val = macd(short_prices, macd_short, macd_long, 1).to_f
	last_macd_val = macd(short_prices.first(short_prices.count-1), macd_short, macd_long, 1).to_f
	atr_val = atr(short_raw_data, atr_ma).to_f
	close_ema_val = short_prices.last(close_ema).ema.to_f
	open_ema_val = @open_prices.last(open_ema).ema.to_f

	extra_data=[k_stochastic, main_ema_val, atr_val, macd_val]

	begin
		if @short_raw_data.last["high"]>@last_bought+1
		sell(@last_bought+1)
	end
	rescue Exception => e
		
	end

	# BUY
	# TODO: add #crossed over 20 stochastic line
	if last_close > last_open &&
		main_ema_val < last_close &&
		short_ema_val < last_close &&
		20 < k_stochastic &&
		k_stochastic < 80 &&
		macd_val > last_macd_val &&
		macd_val > 0 &&
		atr_val>1 &&
		close_ema_val > open_ema_val &&
		# main_ema_val > last_main_ema_val && #README: Line addes
		@usd!=0

		buy(last_close)
		@stop_loss_sell = last_close-atr_val*0.5

	end

	# SELL
	# TODO: add crossed over 80 stochastic line
	if last_close < last_open &&
		20 < k_stochastic &&
		k_stochastic < 80 &&
		macd_val < last_macd_val &&
		close_ema_val > open_ema_val &&
		@btc != 0

		sell(last_close, extra_data)
		@stop_loss_buy = last_close+atr_val*0.5
		
	end

	#Stop-loss Update
	begin
		if short_raw_data.last["low"].to_f>=@stop_loss_sell
			@stop_loss_sell=short_raw_data.last["low"].to_f-atr_val*0.1
		elsif short_raw_data.last["high"].to_f<=@stop_loss_buy
			@stop_loss_buy=short_raw_data.last["high"].to_f+atr_val*0.1
		end
	rescue Exception => e
		puts "Update stop-loss #{e}"
	end

	#Run stop-losses
	begin
		# Stop-loss auto update to low if higher then previous sell stop-loss
# Close price <= stop-loss
# ATR(short_raw_data, 1) > x
# Stochastic: k>20
		if last_close <= @stop_loss_sell &&
			k_stochastic > 20 &&
			@btc!=0
			
			sell(last_close, extra_data)

	# TODO: add Crossed 20 stochastic line and back up 
		elsif last_close >= @stop_loss_buy &&
			last_close > last_open &&
			main_ema_val < last_close && #TODO: Test with only one or the other: main_ema_val or short_ema_val
			short_ema_val < last_close &&
			20 < k_stochastic &&
			k_stochastic < 80 &&
			close_ema_val > open_ema_val &&
			@usd!=0
			
			buy(last_close)

		end
	rescue Exception => e
		puts "Proccess stop-loss #{e}"
	end
	
end

puts @btc
puts @usd

3.times {csv([])}
csv(["Parameters"])
csv(["stochastic_period", stochastic_period])
csv(["stochastic_k", stochastic_k])
csv(["stochastic_d", stochastic_d])
csv(["macd_short", macd_short])
csv(["macd_long", macd_long])
csv(["atr_ma", atr_ma])
csv(["open_ema", open_ema])
csv(["close_ema", close_ema])
csv(["main_ema", main_ema])
csv(["short_ema", short_ema])

# Intial convertion=0.1537
# Now=0.1516

puts @start_usd
@final_balance=@btc*@short_prices.last(50).first+@usd
puts ((@final_balance-@start_usd)/(@final_balance))*100
puts @start_time
puts @n