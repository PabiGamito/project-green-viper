require_relative "okcoin.rb"

def update_data_points
	ActiveRecord::Base.connection_pool.with_connection do #Fixed too many connections to database error
		puts "Updating Data Points\n"
		last_data = HistoricalData.last

		userinfo = Okcoin.userinfo

		if userinfo["result"]
			@cny = userinfo["info"]["funds"]["free"]["cny"].to_f
			@btc = userinfo["info"]["funds"]["free"]["btc"].to_f
		end

		#Set/reset @raw_data and @prices if it isn't set or array is too long to save RAM.
		if (@raw_data==nil || @raw_data.count>500) && last_data.id%2==0
			@raw_data = okcoin_raw_data("1m", 100)
			@prices = okcoin_prices("1m", 100)
		end

		if @raw_data.last["date"].to_i < last_data["date"].to_i && last_data.id%2==0
			@volume = 0
			@high_prices = []
			@low_prices = []
			HistoricalData.last(2).each do |data|
				@date = data["date"]
				@close = data["close"]
				@volume += data["volume"]
				if @open == nil
					@open = data["open"]
				end
				@high_prices << data["high"]
				@low_prices << data["low"]
			end
			@raw_data << {"date" => @date, "open" => @open, "close" => @close, "high" => @high_prices.max, "low" => @low_prices.min, "volume" => @volume}
			@prices << @close
			@open = nil
		end
		puts "Data Points Updated\n"
	end
end