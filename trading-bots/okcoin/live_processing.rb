require_relative "indicators/stochastic.rb"

def check_stop_loss_sell
	begin
	# @atr ||= 1
	k_stochastic = stochastic(@raw_data, @stochastic_period, @stochastic_k, @stochastic_d)["k"].to_f
	if (@buy <= @stop_loss_sell-@atr*0.8 || @buy <= @stop_loss_sell-1) &&
	k_stochastic > 20 &&
	@btc >= 0.001
						
		puts "Attempting to sell at #{@buy}".red
		order = Okcoin.trade( "sell", @btc, @buy)
		index = 0
		until order["result"]
			order = Okcoin.trade( "sell", @btc, @buy)
			index += 1
			break if index > 10
		end
		check_order_completion( order["order_id"] )
		@logger.info "Live Stoploss: Selling at #{@buy}"
		@full_sold=true
	end
	rescue Exception => e
		@logger.error "#{e.backtrace}: #{e.message} (#{e.class})"
	end
end

def check_stop_loss_buy
	if @stop_loss + @atr*0.1 < @buy
		save_stop_loss = @stop_loss
		#Cancel all active orders to place stoploss buy order
		cancel_all_open_orders
		#Buy back into BTC
		order = Okcoin.trade( "buy", @cny/@sell, @sell)
		#Disable stop_loss for it not to try and buy over & over without funds.
		@stop_loss=nil
		#If not placed retry to place spot buy order 10 times
		index = 0
		until order["result"]
			order = Okcoin.trade( "buy", @cny/@sell, @sell)
			index += 1
			if index > 10
				@stop_loss=save_stop_loss
				break
			end
		end
		#Make sure order is completed properly
		check_order_completion( order["order_id"] )
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
	# place_take_sell_order(amount, bought_price, atr)
end

def cancel_all_open_orders
	orders = Okcoin.order_info( "-1" )
	until orders["result"]
		orders = Okcoin.order_info( "-1" )
	end
	canceled_amount=0
	until orders["orders"].count == 0
		orders["orders"].each do |order|
			Okcoin.cancel_order(order["order_id"]) rescue Okcoin.cancel_order(order["order_id"])
			canceled_amount+=order["amount"]
		end
		orders = Okcoin.order_info( "-1" )
	end

	@logger.info "Canceled all active orders." if canceled_amount>0
	return canceled_amount
end

def place_take_sell_order(amount, sell_price)
	#Place Sell Order
	order=Okcoin.trade("sell", amount, sell_price)
	index=0
	#Tries up to 10 times if order not placed
	until order["result"]
		order = Okcoin.trade("sell", amount, sell_price)
		index += 1
		if index > 10
			sold=true
			break
		end
	end
	@logger.info "Attempted to Place Take Sell Order at #{sell_price}"
end

def place_take_buy_order(amount, buy_price)
	#Place Sell Order
	order=Okcoin.trade("buy", amount, buy_price)
	index=0
	#Tries up to 10 times if order not placed
	until order["result"]
		order = Okcoin.trade("buy", amount, buy_price)
		index += 1
		if index > 10
			sold=true
			break
		end
	end
	# @logger.info "Attempted to Place Take Sell Order at #{buy_price}"
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