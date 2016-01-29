require 'rest-client'
require 'openssl'
require 'addressable/uri'
require 'active_record'
require 'csv_hasher'

def period_to_interval(period)
  if period=="30s"
    interval=1
  elsif period=="1m"
    interval=2
  elsif period=="5m"
    interval=5*2
  elsif period=="10m"
    interval=10*2
  elsif period=="15m"
    interval=15*2
  elsif period=="20m"
    interval=20*2
  elsif period=="30m"
    interval=30*2
  elsif period=="1h"
    interval=60*2
  elsif period=="2h"
    interval=60*2*2
  elsif period=="2h30m"
    interval=60*2*2+30*2
  elsif period=="3h"
    interval=3*60*2
  elsif period=="4h"
    interval=(4*60)*2
  elsif period=="6h"
    interval=(6*60)*2
  end
  return interval
end

def okcoin_raw_data(period, amount) #period = 5m, 30m, 1h, 2h, 6h \ amount=int : amount of datapoints needed
  interval = period_to_interval(period)
  raw_data = []
  @volume = 0
  @low_prices = []
  @high_prices = []
  open=nil
  historical_data = CSVHasher.hashify('okcoin_historical_data.csv')
  historical_data.last(amount*interval).each_slice(interval).to_a.each do |data_split_array|
    data_split_array.each do |data|
      if @open==nil
        @open=data[:open].to_f
      end
      @low_prices << data[:low].to_f
      @high_prices << data[:high].to_f
      @close=data[:close].to_f
      @volume+=data[:volume].to_f
      @date=data[:date].to_i
    end
    raw_data << {"date" => @date, "open" => @open, "close" => @close, "high" => @high_prices.max, "low" => @low_prices.min, "volume" => @volume}
    @open=nil
    @low_prices = []
    @high_prices = []
    @volume=0
  end
  return raw_data
end

def okcoin_prices(period, amount)
  prices = []
  raw_data = okcoin_raw_data(period, amount)
  raw_data.last(amount).each do |data|
    prices << data["close"]
  end
  return prices
end