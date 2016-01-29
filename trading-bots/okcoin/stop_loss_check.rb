def full_stop_loss_check
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
			until order["result"]
				order = Okcoin.trade( "sell", @btc, @buy)
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
			until order["result"]
				order = Okcoin.trade( "buy", @cny/@sell, @sell)
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

def stop_loss_sell_check
	
end