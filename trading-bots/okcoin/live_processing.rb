require_relative "indicators/stochastic.rb"

def check_stop_loss_sell
	begin
	# @atr ||= 1
	k_stochastic = stochastic(@raw_data, @stochastic_period, @stochastic_k, @stochastic_d)["k"].to_f
	if @buy <= @stop_loss_sell-@atr*0.5 &&
	k_stochastic > 20 &&
	@btc!=0
						
		puts "Attempting to sell at #{@buy}".red
		order = Okcoin.trade( "sell", @btc, @buy)
		check_order_completion( order["order_id"] )
		# send_email("pablogamito@gmail.com", "Selling at #{@buy}")
		@logger.info "Selling at #{@buy}"

	end
	rescue Exception => e
		puts e
	end
end


def check_order_completion(order_id)
	#Gets the orderinfo and makes sure got data
	order = Okcoin.order_info( order_id )
	index = 0
	until order["result"] #==true
		order = Okcoin.order_info( order_id )
		index += 1
		break if index > 10
	end

	order_complete=false
	
	#Set order type
	order_type ||= order["orders"].first["type"]

	#Run this in loop until order is complete.
	start_time=Time.now.to_i
	until order_complete
		#Updates order Data
		if Time.now.to_i>start_time+2*60
			Okcoin.cancel_order(order_id) rescue Okcoin.cancel_order(order_id)
			order_complete=true
			break
		end
		order = Okcoin.order_info( order_id )
		until order["result"] #Makes sure data has been received
			order = Okcoin.order_info( order_id )
			if Time.now.to_i>start_time+2*60
				Okcoin.cancel_order(order_id) rescue Okcoin.cancel_order(order_id)
				break
			end
		end

		# status: -1 = cancelled, 0 = unfilled, 1 = partially filled, 2 = fully filled, 4 = cancel request in process
		if order["orders"].first["status"]==2 #If order is full filled
			order_complete=true
		elsif order["orders"].first["status"]==1 || order["orders"].first["status"]==0 #If order partially filled run the following
			sleep(3)
			Okcoin.cancel_order(order_id) rescue Okcoin.cancel_order(order_id)
			trade_success=false
			until trade_success
				if Time.now.to_i>start_time+2*60
					Okcoin.cancel_order(order_id) rescue Okcoin.cancel_order(order_id)
					break
				end
				#Get available balances
				userinfo = Okcoin.userinfo
				unless userinfo["result"]
					userinfo = Okcoin.userinfo
				end
				@cny = userinfo["info"]["funds"]["free"]["cny"].to_f
				@btc = userinfo["info"]["funds"]["free"]["btc"].to_f
				#Perform Trade
				if order_type=="buy" 
					trade = Okcoin.trade( order_type , @cny/@sell, @sell )
				elsif order_type=="sell"
					trade = Okcoin.trade( order_type , @btc, @buy )
				end
				#Check if order was successful
				if trade["result"]
					#Update Varibles
					order_id = trade["order_id"]
					order = Okcoin.order_info( order_id )
					trade_success=true
				end
			end
		end

		#Wait 2 seconds before reproccessing data.
		sleep(2)
		#If there are no orders left exit loop.
		if Okcoin.order_info( "-1" )["orders"].count == 0
			order_complete=true
		else

		end
	end
end

# Response
# {
#     "result": true,
#     "orders": [
#         {
#             "amount": 0.1,
#             "avg_price": 0,
#             "create_date": 1418008467000,
#             "deal_amount": 0,
#             "order_id": 10000591,
#             "orders_id": 10000591,
#             "price": 500,
#             "status": 0,
#             "symbol": "btc_usd",
#             "type": "sell"
#         },
#         {
#             "amount": 0.2,
#             "avg_price": 0,
#             "create_date": 1417417957000,
#             "deal_amount": 0,
#             "order_id": 10000724,
#             "orders_id": 10000724,
#             "price": 0.1,
#             "status": 0,
#             "symbol": "btc_usd",
#             "type": "buy"
#         }
#     ]
# }