require 'rufus-scheduler'
require 'pony'

scheduler = Rufus::Scheduler.new

scheduler.cron '0 18 * * * *' do
  # do something every day, five minutes after midnight
  # (see "man 5 crontab" in your terminal)
end

# html_message=""\
#   "<center>"\
# 	"<i>**This is an automatically generated email. Do not reply to this email. You will not receive a response.**</i>"\
# 	"<h3>Daily Results</h3>"\
# 	"<hr>"\
# 	"<p style='box-sizing: border-box; margin: 0px 0px 10px; font-family: Helvetica, Arial, sans-serif; color: rgb(33, 33, 33); font-size: 9px; line-height: 12px;'>"\
# 	"This e-mail message contains confidential and legally privileged information that is intended only for the use of the intended recipient(s). Any unauthorized disclosure, dissemination, distribution, copying or the taking of any action in reliance on the information herein is prohibited. E-mail transmission cannot be guaranteed to be error free nor secure as they can be intercepted, corrupted, amended, or contain viruses."\
# 	"</p>"\
# 	"</center>"

html_message="<style>body { margin: 0; } td, p { font-size: 13px; color: #878787; font-family: 'Lucida Grande', 'Lucida Sans Unicode', Verdana, sans-serif; } ul { margin: 0 0 10px 25px; padding: 0; } li { margin: 0 0 3px 0; } blockquote { margin: 10px; font-style: italic; } h1, h2 { color: black; } h1 { font-size: 25px; line-height: 1.4; } h2 { font-size: 20px; } a { color: #2F82DE; font-weight: bold; text-decoration: none; } .entire-page { background: #C7C7C7; width: 100%; padding: 20px 0; font-family: 'Lucida Grande', 'Lucida Sans Unicode', Verdana, sans-serif; line-height: 1.5; } .email-body { max-width: 600px; min-width: 320px; margin: 0 auto; background: white; border-collapse: collapse; } .email-header { background: #CB4A43; padding: 30px; font-family: 'Ubuntu', sans-serif;} .email-header img { max-width: 100%; } .news-section { padding: 20px 30px; } .news-section img { width: 100%; } .best-of-thumb { width: 40%; vertical-align: top; } .best-of-thumb img { width: 100%; } .best-of-about { padding-left: 20px; vertical-align: top; } .best-of-thumb, .best-of-about { border-bottom: 1px solid #ddd; padding-top: 20px; padding-bottom: 20px; } .advertiser-row td { border: 10px solid #F7F8F9; } .advertiser-row img { width: 100%; display: block; } .block-ad { display: block; } .double-ads td { width: 50%; text-align: center; vertical-align: top; } .double-ads td p { font-size: 11px; margin: 5px 0; } .double-ads td h3 { margin: 10px 0 0; } .double-ads td:nth-child(1) { padding-right: 10px; } .double-ads td:nth-child(2) { padding-left: 10px; } .double-ads td img { display: block; } .feature-row { border-collapse: separate; } .feature-row img { width: 100%; display: block; margin: 0 0 10px 0; } .feature-row td { text-align: center; } .feature-row td:nth-child(1) { border-right: 10px solid white; } .feature-row td:nth-child(2) { border-left: 10px solid white; } .footer { background: #eee; padding: 10px; font-size: 10px; text-align: center; }</style>"\
	"<table class='entire-page'> <tr> <td> <table class='email-body'> <tr> <td class='news-section'>"\
	"<h2>Today's Trading Summary</h2>"\
	"<p>Today this is your trading recap...</p>"\
	"<table class='best-of-table'> <tr> <td class='best-of-thumb'> <img src='http://4.bp.blogspot.com/_CHG2GRbeET8/SS3f-tcSNiI/AAAAAAAAJEk/qVdRYu1MLMs/s320/missing-715826.gif' alt=''> </td> <td class='best-of-about'>"\
	"<h3>Essentials</h3> <p>BTC/USD: <br>BTC/CNY: <br>LTC/USD: <br>LTC/BTC: <br></p>"\
	"</td> </tr> <tr> <td class='best-of-thumb'> <p></p> </td> <td class='best-of-about'>"\
	"<h3>Todays Trades</h3> <p>More Stuff.</p>"\
	"</td> </table> </td> </tr> <tr> <td class='footer'>"\
	"This e-mail message contains confidential or legally privileged information that is intended only for the use of the intended recipient(s). Any unauthorized disclosure, dissemination, distribution, copying or the taking of any action in reliance on the information herein is prohibited. E-mail transmission cannot be guaranteed to be error free nor secure as they can be intercepted, corrupted, amended, or contain viruses."\
	"</td> </tr> </table>"

message="This is generted incase your client can not ready html"\
	"Daily Results:"

emails=["pablogamito@gmail.com", "sgamito@zanniergroup.com"]

Pony.mail({
	:to => "pablogamito@gmail.com",
	:cc => "sgamito@zanniergroup.com",
  :subject => "TEST: Trading Daily Update",
  :html_body => html_message,
  :body => message,
  :via => :smtp,
  :via_options => {
    :address              => 'smtp.gmail.com',
    :port                 => '587',
    :enable_starttls_auto => true,
    :user_name            => 'pabi.vps@gmail.com',
    :password             => 'mouse16081999',
    :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
    :domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
  }
})


# scheduler.join