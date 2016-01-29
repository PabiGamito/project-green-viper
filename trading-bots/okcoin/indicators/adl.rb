# Accumulation/Distribution Line
# How much cash is going in/out

# The CLV can be calculated as follows:

# CLV = ([(C-L) - (H - C)] / (H - L))
# Where:

# C = the closing price
# H = the high of the price range
# L = the low of the price range
# The CLV is then multiplied by the corresponding period's volume, and the total will form the A/D line. 

def adl(close, low, high, volume)
	close=close.to_f
	puts clv = ((close-low)-(high-close))/(high-low)
	adl = clv*volume
	return adl
end