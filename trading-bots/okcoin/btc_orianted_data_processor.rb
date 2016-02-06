require_relative "indicators/rsi.rb"
require_relative "indicators/stochastic.rb"
require_relative "indicators/macd.rb"
require_relative "indicators/atr.rb"
require 'colorize'

ActiveRecord::Base.connection_pool.with_connection do #Fixed too many connections to database error
	puts "Processing Data"

	if @raw_data!=nil && @previous_date!=@raw_data.last["date"].to_i
		#Calculate all Variables
		last_close = @prices.last.to_f
		last_open = @raw_data.last["open"].to_f
		last_high = @raw_data.last["high"].to_f
		main_ema_val = @prices.last(@main_ema).ema.to_f
		last_main_ema_val = @prices.last(@main_ema+1).first(@main_ema).ema.to_f
		short_ema_val = @prices.last(@short_ema).ema.to_f
		k_stochastic = stochastic(@raw_data, @stochastic_period, @stochastic_k, @stochastic_d)["k"].to_f
		macd_val = macd(@prices, @macd_short, @macd_long, 1).to_f
		last_macd_val = macd(@prices.first(@prices.count-1), @macd_short, @macd_long, 1).to_f
		atr_val = atr(@raw_data, @atr_ma).to_f
		close_ema_val = @prices.last(@close_ema).ema.to_f
		open_ema_val = @prices.last(@open_ema).ema.to_f
		@previous_date = @raw_data.last["date"].to_i

		unless atr_val.nil?
			@atr=atr_val
		end

		#SELL
		if last_close < last_open && #Closes lower than it opened
			20 < k_stochastic && #Stochastic over 20 line
			k_stochastic < 80 && #Stochastic under 80 line
			macd_val < last_macd_val && #Macd going down
			@atr > 1 && #Atr above 1
			close_ema_val < open_ema_val && #closing ema is below open ema
			@btc >= 0.001 #has enough BTC balance to trade

			#Placing spot sell order
			order = Okcoin.trade( "sell", @btc, @buy)
			#Set estimated sold price and amount
			sold_price = @buy
			sold_amount = @btc
			#If not placed retry to place spot buy order 10 times
			index = 0
			until order["result"]
				order = Okcoin.trade( "sell", @btc, @buy)
				index += 1
				break if index > 10
			end
			#Make sure order is completed properly
			check_order_completion( order["order_id"] )
			#Place different % in take profits based on factors
			if @sell < main_ema_val && @sell < short_ema_val && last_close < short_ema_val && main_ema_val < last_main_ema_val
				#Place 1/2 of BTCs in take order at bought price + 1/2 ATR.
				place_take_buy_order(sold_amount*0.5, sold_price-@atr*0.5)
				#Set stop-loss at last low
				@stop_loss = last_high
			else
				#Place all of BTCs in take order at bought price + 1/2 ATR
				place_take_buy_order(sold_amount, sold_price-@atr*0.5)
				#Set stop-loss at bought price - 1/2 ATR
				@stop_loss = sold_price+@atr*0.5
			end

		end

		#CHECK FOR EXISTING STOP-LOSS
		if @stop_loss!=nil
			#UPDATE STOP-LOSS
			if @stop_loss > last_high
				@stop_loss = last_high
			end

			#CHECK STOP-LOSS ACTIVATION
			if @stop_loss < last_close || @stop_loss < @sell
				#Cancel all active orders to place stoploss buy order
				cancel_all_open_orders
				#Buy back into BTC
				order = Okcoin.trade( "buy", @cny/@sell, @sell)
				#If not placed retry to place spot buy order 10 times
				index = 0
				until order["result"]
					order = Okcoin.trade( "buy", @cny/@sell, @sell)
					index += 1
					break if index > 10
				end
				#Make sure order is completed properly
				check_order_completion( order["order_id"] )
			end
		end

	end

end