require 'rufus-scheduler'
require 'open-uri'
require 'json'
require 'openssl'
require 'net/http'
require 'active_record'

scheduler = Rufus::Scheduler.new

ActiveRecord::Base.establish_connection( 
 :adapter => "mysql2",
 :host => "localhost",
 :username=>"root",
 :password=>"mouse16081999",
 :database => "bitfinex"
)

class HistoricalData < ActiveRecord::Base
end

@last_time = Time.now.to_i

scheduler.every '5m' do
	prices = []
	@volume = 0
	data = JSON.parse(open("https://api.bitfinex.com/v1/trades/BTCUSD", :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE).read)
	@time = Time.now.to_i
	n=0
	data.each do |data|
		if data["timestamp"].to_i>@last_time
			prices << data["price"].to_f
			@volume += data["amount"].to_f
			@open = data["price"].to_f
		end
	end

	@close=prices.first

	# determine low
	@low=@close
	prices.each do |price|
		if @low>price
			@low=price
		end
	end

	# determine high
	@high=prices.first
	prices.each do |price|
		if @high<price
			@high=price
		end
	end

	@last_time=data.first["timestamp"].to_f

	#Add data to database
	HistoricalData.create(:open => @open.to_f, :close => @close.to_f, :low => @low.to_f, :high => @high.to_f, :volume => @volume.to_f, :date => @time) #timestamp...
	puts "Data added to Database"

end

#TODO: HAVE THIS WORKING SO THAT IT GET INFO IF THERE WAS A FAIL IN GETTING IT.
scheduler.every '12m' do
	raw_data = JSON.parse(open("https://api.bitfinex.com/v1/trades/BTCUSD", :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE).read)
	HistoricalData.all.last(50).each do |data|
		if data["open"].to_f==0 || data["close"].to_f==0
			if raw_data.last["timestamp"].to_i<data["date"].to_i-300
				raw_data["date"]
			end
		end
	end
end

scheduler.every '1d' do
	HistoricalData.all.each do |data|
		if data.date < (Time.now.to_i-(6*30*24*60*60))
			data.destroy
		end
	end
end

scheduler.join