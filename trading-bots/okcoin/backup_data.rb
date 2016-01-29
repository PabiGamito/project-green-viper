require 'csv'
require 'active_record'

database="okcoin"

ActiveRecord::Base.establish_connection( 
 :adapter => "mysql2",
 :host => "localhost",
 :username=>"root",
 :password=>"mouse16081999",
 :database => database
)

class HistoricalData < ActiveRecord::Base

end

file="#{database}_historical_data.csv"

#Remove all data from file, so I get a blank file
File.open(file, 'w') {|file| file.truncate(0) }

CSV.open(file, "wb") do |csv|
  csv << ["date", "open", "close", "high", "low", "volume"]
end

#Get all database info into arrays
full_data=[]
HistoricalData.all.each do |data|
	full_data<<[data["date"], data["open"], data["close"], data["high"], data["low"], data["volume"]]
end

#Add all data to cvs file
CSV.open(file, "a+") do |csv|
	full_data.each do |data_row|
  	csv << data_row
  end
end