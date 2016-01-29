require_relative "indicators/rsi.rb"
require_relative "indicators/stochastic.rb"
require_relative "indicators/macd.rb"
require_relative "indicators/atr.rb"
require 'colorize'

# def process_data
	ActiveRecord::Base.connection_pool.with_connection do #Fixed too many connections to database error
		puts "Processing Data"

		if @raw_data!=nil && @previous_date!=@raw_data.last["date"].to_i
			#Calculate all Variables
			p last_close = @prices.last.to_f
			p last_open = @raw_data.last["open"].to_f
			p main_ema_val = @prices.last(@main_ema).ema.to_f
			p short_ema_val = @prices.last(@short_ema).ema.to_f
			p k_stochastic = stochastic(@raw_data, @stochastic_period, @stochastic_k, @stochastic_d)["k"].to_f
			p macd_val = macd(@prices, @macd_short, @macd_long, 1).to_f
			p last_macd_val = macd(@prices.first(@prices.count-1), @macd_short, @macd_long, 1).to_f
			p atr_val = atr(@raw_data, @atr_ma).to_f
			p close_ema_val = @prices.last(@close_ema).ema.to_f
			p open_ema_val = @prices.last(@open_ema).ema.to_f
			p @previous_date = @raw_data.last["date"].to_i

			unless atr_val.nil?
				puts @atr=atr_val
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
				@atr>1 &&
				close_ema_val > open_ema_val &&
				@cny>=0.001*@sell

				puts "Attempting to buy at #{@sell}".green
				order = Okcoin.trade( "buy", @cny/@sell, @sell)
				index = 0
				until order["result"]
					order = Okcoin.trade( "buy", @cny/@sell, @sell)
					index += 1
					break if index > 10
				end
				check_order_completion( order["order_id"] )
				@logger.info "Buying at #{@sell}"
				@stop_loss_sell = last_close-@atr*0.5
				# send_email("pablogamito@gmail.com", "Buying at #{@sell}")

			end

			# SELL
			# TODO: add crossed over 80 stochastic line
			if last_close < last_open &&
				20 < k_stochastic &&
				k_stochastic < 80 &&
				macd_val < last_macd_val &&
				close_ema_val > open_ema_val &&
				@btc >= 0.001

				puts "Attempting to sell at #{@buy}".red
				order = Okcoin.trade( "sell", @btc, @buy)
				index = 0
				until order["result"]
					order = Okcoin.trade( "sell", @btc, @buy)
					index += 1
					break if index > 10
				end
				check_order_completion(order["order_id"])
				@logger.info "Selling at #{@buy}"
				@stop_loss_buy = last_close+@atr*0.5
				# send_email("pablogamito@gmail.com", "Selling at #{@buy}")
				
			end

			#Stop-loss Update
			#TODO: Test with different atr% values
			begin
				if @raw_data.last["low"].to_f>=@stop_loss_sell
					@stop_loss_sell=@raw_data.last["low"].to_f-@atr*0.1
				elsif @raw_data.last["high"].to_f<=@stop_loss_buy
					@stop_loss_buy=@raw_data.last["high"].to_f+@atr*0.1
				end
			rescue Exception => e
				puts "Update stop-loss #{e}"
				@logger.error "Update stop-loss #{e}"
			end

			#Run stop-losses
			begin
				# Stop-loss auto update to low if higher then previous sell stop-loss
				# Close price <= stop-loss
				# ATR(@raw_data, 1) > x
				# Stochastic: k>20
				if last_close <= @stop_loss_sell &&
					k_stochastic > 20 &&
					@btc!=0
					
					puts "Attempting to sell at #{@buy}".red
					order = Okcoin.trade( "sell", @btc, @buy)
					index = 0
					until order["result"]
						order = Okcoin.trade( "sell", @btc, @buy)
						index += 1
						break if index > 10
					end
					check_order_completion( order["order_id"] )
					# send_email("pablogamito@gmail.com", "Selling at #{@buy}")
					@logger.info "Selling at #{@buy}"

			# TODO: add Crossed 20 stochastic line and back up 
				elsif last_close >= @stop_loss_buy &&
					last_close > last_open &&
					main_ema_val < last_close && #TODO: Test with only one or the other: main_ema_val or short_ema_val
					short_ema_val < last_close &&
					20 < k_stochastic &&
					k_stochastic < 80 &&
					close_ema_val > open_ema_val &&
					@cny!=0
					
					puts "Attempting to buy at #{@sell}".green
					order = Okcoin.trade( "buy", @cny/@sell, @sell)
					index = 0
					until order["result"]
						order = Okcoin.trade( "buy", @cny/@sell, @sell)
						index += 1
						break if index > 10
					end
					check_order_completion( order["order_id"] )
					# send_email("pablogamito@gmail.com", "Buying at #{@sell}")
					@logger.info "Buying at #{@sell}"

				end
			rescue Exception => e
				puts "Proccessing stop-loss: #{e}"
				@logger.error "Proccessing stop-loss: #{e}"
			end

		end

		puts @stop_loss_sell
		puts @stop_loss_buy

		puts "Data Processing Done"
	end
# end