require 'rest-client'
require 'openssl'
require 'addressable/uri'
require 'json'

module Okcoin

  class << self
    attr_accessor :configuration
  end

  def self.setup
    @configuration ||= Configuration.new
    yield( configuration )
  end

  class Configuration
    attr_accessor :key, :secret

    def intialize
      @key    = ''
      @secret = ''
    end
  end

  def self.ticker( symbol="btc_cny" )
    JSON.parse(get 'ticker', symbol: symbol)["ticker"]
  end

  def self.depth( symbol="btc_cny" )
    JSON.parse(get 'depth', symbol: symbol)
  end

  def self.userinfo
    JSON.parse(post 'userinfo')
  end

  def self.trade( type, amount, price, symbol="btc_cny")
    JSON.parse(post 'trade', type: type, price: price, amount: amount, symbol: symbol)
  end

  def self.order_info( order_id, symbol="btc_cny")
    JSON.parse(post 'order_info', order_id: order_id, symbol: symbol)
  end

  def self.cancel_order( order_id, symbol="btc_cny")
    JSON.parse(post 'cancel_order', order_id: order_id, symbol: symbol)
  end

  def self.order_history( status, current_page, page_length, symbol="btc_cny")
    JSON.parse(post 'order_history', status: status, current_page: current_page, page_length: page_length, symbol: symbol)
  end

  def lend_depth( sybmol="btc_cny" )
    JSON.parse(post 'lend_depth', symbol: symbol)
  end

  def borrows_info( sybmol="btc_cny" )
    JSON.parse(post 'borrows_info', symbol: symbol)
  end

  def borrow_money( days, amount, rate, symbol="btc_cny" )
    JSON.parse(post 'borrow_money', days: days, amount: amount, rate: rate, symbol: symbol)
  end

  def cancel_borrow( borrow_id, symbol="btc_cny" )
    JSON.parse(post 'cancel_borrow', borrow_id: borrow_id, symbol: symbol)
  end

  def borrow_order_info( borrow_id )
    JSON.parse(post 'borrow_order_info', borrow_id: borrow_id)
  end

  def repayment( borrow_id )
    JSON.parse(post 'repayment', borrow_id: borrow_id)
  end

  def self.unrepayments_info( current_page, page_length, symbol="btc_cny")
    JSON.parse(post 'unrepayments_info', status: status, current_page: current_page, page_length: page_length, symbol: symbol)
  end

  protected

  def self.resource
    @@resouce ||= RestClient::Resource.new( 'https://www.okcoin.cn/api/v1/' )
  end

  def self.get( command, params = {} )
    resource[ "#{command}.do?" ].get params: params
  end

  def self.post( command, params = {} )
    params[:api_key] = configuration.key
    params[:sign]   = create_sign( params )
    resource[ "#{command}.do?" ].post params
  end

  def self.create_sign( data )
    sorted_data = data.sort.to_h
    encoded_data = Addressable::URI.form_encode( sorted_data )
    encoded_data += "&secret_key=#{configuration.secret}"
    sign = Digest::MD5.hexdigest(encoded_data).to_s.upcase
    return sign
  end

end

Okcoin.setup do | config |
  config.key = "214e1a41-d8b0-486e-8bb9-4098e01bfb1c"
  config.secret = "D7D83413FE96BBD15829F866EB5CADC6"
end

 # @key="214e1a41-d8b0-486e-8bb9-4098e01bfb1c"
 #  @secret="D7D83413FE96BBD15829F866EB5CADC6"
  # @key = "ef3d820b-a4c4-4732-8086-fbbf5b01e4c2"
  # @secret = "03209CE588DF0DF343DB2BFF7196D6F1"