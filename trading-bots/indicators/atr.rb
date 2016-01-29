require 'moving_average'
# h-l
# abs(h-pc)
# abs(l-pc)

# true_rang=max of the three things above
# atr=avg(n_period_true_range)

def atr(data, period)
	data=data.last(period+1)
	atr=[]
	period.times do
		current_data=data.first(2).last
		previous_data=data.first(2).last
		trs=[current_data["high"].to_f-current_data["low"].to_f, (current_data["high"].to_f-previous_data["close"].to_f).abs, (current_data["low"].to_f-previous_data["close"].to_f).abs]
		atr<<trs.max
		data.shift
	end
	return atr.last(period).sma
end