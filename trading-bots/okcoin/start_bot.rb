# require_relative 'okcoin_client.rb'
# Okcoin.establish_connection

# # Never Ending Script
# loop do
# end

#Setup logger
require 'logging'
#Make logs directory unless it exists
Dir.mkdir("logs") unless File.exists?("logs")

#Get all files from log folder and only select correct log files.
logs = Dir.entries("logs").sort.select { |file_name| /bot-log\w+.log/.match(file_name) }.sort
#Get next id of log file
logs.count>0 ? next_id = /\d/.match(logs.last).to_s.to_i + 1 : next_id = 1
#Creates new file to write log into
File.new("logs/bot-log#{next_id}.log", "w") 
@logger = Logging.logger['OkcoinBot']
@logger.add_appenders \
    Logging.appenders.stdout,
    Logging.appenders.file("logs/bot-log#{next_id}.log")

#Get required dependencies
require_relative 'okcoin_rest_client'
require 'rufus-scheduler'
require 'active_record'
require 'pony'

#Setup a scheduler
#Prevent connection errors to database
class Rufus::Scheduler::Job

  alias_method :old_do_call, :do_call
  def do_call(time, do_rescue)
    args = [ self, time ][0, @callable.arity]
    @callable.call(*args)
  rescue StandardError => se
    raise se unless do_rescue
    return if se.is_a?(KillSignal) # discard
    @scheduler.on_error(self, se)
  ensure
    ActiveRecord::Base.clear_active_connections!
  end

end

#Define the scheduler
scheduler = Rufus::Scheduler.new

@logger.debug 'Bot Started'

#Establish connection with Mysql database
ActiveRecord::Base.establish_connection( 
 :adapter => "mysql2",
 :host => "localhost",
 :username=>"root",
 :password=>"mouse16081999",
 :database => "okcoin"
)
class HistoricalData < ActiveRecord::Base

end

#Make a method to send an email
def send_email(email, message)
	Pony.mail({
	  :to => email,
	  :via => :smtp,
	  :via_options => {
	    :address              => 'smtp.gmail.com',
	    :port                 => '587',
	    :enable_starttls_auto => true,
	    :user_name            => 'pablogamito@gmail.com',
	    :password             => 'mofleties16081999',
	    :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
	    :domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
	  },
	  :subject => 'Bot Message', 
	  :body => message
	})
end

#What to do on error in Schedualed Job
def scheduler.on_error(job, err)
  @logger.error "error in scheduled job: #{job.class}: #{job.original}: #{err.message}: #{err.stacktrace}"
end

#Require all needed files
require_relative "live_processing.rb"
require_relative "data_point_updater.rb"

#Setup Needed Variables
@stop_loss_sell = 0.0
@stop_loss_buy = 99999999999.0
@previous_date = 0

#Parameters
@stochastic_period=5
@stochastic_k=3
@stochastic_d=2
@macd_short=8
@macd_long=17
@atr_ma=12
@open_ema=6
@close_ema=5
@main_ema=160
@short_ema=17

update_data_points

#Setup schedualed tasks
scheduler.every '1s' do
  @last_ticker = Okcoin.ticker
  @buy = @last_ticker["buy"].to_f
  @sell = @last_ticker["sell"].to_f
  @price =  @last_ticker["last"].to_f
  check_stop_loss_sell
end

scheduler.every '30s' do
  update_data_points
  load 'data_processor.rb'
  # @logger.info "running"
end

#Connect to schedualed task to run in loop forever.
scheduler.join