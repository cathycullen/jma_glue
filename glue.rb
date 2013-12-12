require 'sinatra'
require 'dotenv'
Dotenv.load

# Note: These endpoints should all be 'post', not 'get' to handle a form submission.
# Left as 'get' for easy testing until we deploy.
get '/constant_contact' do
  # use params[:email_adddress] to access email from form submission
  'Hello from Constant Contact endpoint'
end

get '/podio_contact' do
  'Hello from Podio Contact endpoint'
end
