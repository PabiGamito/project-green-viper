require 'rufus-scheduler'
require 'open-uri'
require 'json'
require 'openssl'
require 'net/http'
require 'active_record'

@scheduler = Rufus::Scheduler.new

ActiveRecord::Base.establish_connection( 
 :adapter => "mysql2",
 :host => "localhost",
 :username=>"root",
 :password=>"mouse16081999",
 :database => "okcoin"
)

class HistoricalData < ActiveRecord::Base
end

@scheduler.every '30s' do
	ActiveRecord::Base.connection_pool.with_connection do #Fixed too many connections to database error

	full_data=JSON.parse(open("https://www.okcoin.cn/api/v1/trades.do?since=99999999", :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE).read)
	volume=0.0
	open=full_data.first["price"].to_f
	close=full_data.last["price"].to_f
	date=full_data.first["date"].to_i
	high=open
	low=open
	full_data.each do |data|
		volume+=data["amount"].to_f
		if data["price"].to_f > high
			high = data["price"].to_f
		elsif data["price"].to_f < low
			low = data["price"].to_f
		end
	end
	HistoricalData.create(:open => open, :close => close, :low => low, :high => high, :volume => volume, :date => date)
	puts "Data added to Database at #{Time.now}"
	
	end
end

@scheduler.join