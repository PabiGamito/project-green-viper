require_relative 'okcoin_rest_client'

data_array=[]
Okcoin.order_history( 1, 1, 200)["orders"].each {|data| data_array << data}.reverse
data_array.shift(20)
if data_array.first["type"]=="sell" 
	@btc=0.0
	@cny=data_array.first["amount"].to_f*data_array.first["price"].to_f
elsif data_array.first["type"]=="buy"
	@cny=0.0 
	@btc=data_array.first["amount"].to_f
end
@btc
@cny
@initial_balance=@btc*data_array.first["price"].to_f+@cny
data_array.shift
data_array.each do |data|
	if data["type"]=="sell" && data["status"]==2
		puts @cny+=data["amount"].to_f*data["price"].to_f
		puts @btc-=data["amount"].to_f
		puts ""
	elsif data["type"]=="buy" && data["status"]==2
		puts @btc+=data["amount"].to_f
		puts @cny-=data["amount"].to_f*data["price"].to_f
		puts ""
	end
end

puts @btc
puts @cny
puts @final_balance=@btc*data_array.last["price"]+@cny
puts @initial_balance