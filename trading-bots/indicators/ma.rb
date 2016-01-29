require 'moving_average'

def ema(data, period=20) #data as prices only
	prices=[]
	data.last(period).each do |price|
		prices << price
	end
	return prices.ema
end

def sma(data, period=20) #data as prices only
	prices=[]
	data.last(period).each do |price|
		prices << price.to_f
	end
	return prices.sma
end