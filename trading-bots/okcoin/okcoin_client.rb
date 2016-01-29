require 'websocket-client-simple'
require 'zlib'
require 'json'
require 'digest/md5'
require 'active_record'
require 'yaml'

ActiveRecord::Base.establish_connection( 
 :adapter => "mysql2",
 :host => "localhost",
 # :host => "128.199.144.250",
 :username=>"root",
 :password=>"mouse16081999",
 :database => "okcoin"
)

class HistoricalData < ActiveRecord::Base
end

module Okcoin

  keys=File.read("../../keys.yaml")
  @key=key["okcoin"]["key"]
  @secret=key["okcoin"]["secret"]

  #Module configuration and setup
  class << self
    attr_accessor :key, :secret, :buy, :sell
  end

  Okcoin.key=@key
  Okcoin.secret=@secret

  #All Websocket Stuff
  def self.establish_connection
    ws = WebSocket::Client::Simple.connect 'wss://real.okcoin.cn:10440/websocket/okcoinapi'

    ws.on :message do |msg|
      if msg.to_s.include? "errorcode"
        puts msg
      elsif msg.to_s.include? "channel"
        puts msg
      else
        parsed_message = JSON.parse(Okcoin.inflate(msg.data))
        Okcoin.process_data(parsed_message)
      end
    end

    ws.on :open do
      puts "connection opened"
      ws.send "{'event':'addChannel','channel':'ok_btccny_ticker','binary':'true'}"
      # params = {api_key: "#{Okcoin.key}"}
      # ws.send "{'event':'addChannel', 'channel':'ok_usd_realtrades', 'parameters':{ #{Okcoin.parse_params(params)} }}"
      puts "addChannel sent"
    end

    ws.on :close do |e|
      p e
      exit 1
    end

    ws.on :error do |e|
      p e
    end

  end

  def self.inflate(deflated_string)
    zstream = Zlib::Inflate.new(-Zlib::MAX_WBITS)
    buf = zstream.inflate(deflated_string)
    zstream.finish
    zstream.close
    buf
  end

  protected

  def self.parse_params(params)
    sign = Okcoin.sign(params)
    parsed_params = ""
    params.each {|param, value| parsed_params+="'#{param}':'#{value}',"}
    parsed_params+="'sign':'#{sign}'"
    return parsed_params
  end

  def self.sign(params)
    sorted_data = params.sort.to_h
    parsed_data = ""
    sorted_data.each do |param, value|
      parsed_data+="#{param}=#{value}&"
    end
    parsed_data += "secret_key=#{@secret}"
    sign = Digest::MD5.hexdigest(parsed_data).to_s.upcase
    return sign
  end

  #Send data to correct data proccessing method
  def self.process_data(data)
    Okcoin.send(data.first["channel"], data.first["data"])
  end

  #Data proccessing methods
  def self.ok_btccny_ticker(data)
    Okcoin.buy = data["buy"].to_f
    Okcoin.sell = data["sell"].to_f
    load 'data_processor.rb'
  end

end