require 'moving_average'
# MACD Line: (12-day EMA - 26-day EMA)

# Signal Line: 9-day EMA of MACD Line

# MACD Histogram: MACD Line - Signal Line

def macd(data, short, long, signal)
	macds=[]
	data=data.last(long+signal)
	signal.times do
		short_ema = data.first(long).last(short).ema
		long_ema = data.first(long).ema
		macds << short_ema-long_ema
		data.shift
	end
	return macds.last#-macds.ema
end