require 'sinatra'
require 'dotenv'
require 'podio'
require 'json'

require './podio_wrapper'

Dotenv.load
Podio.setup(:api_key => ENV['PODIO_CLIENT_ID'],
            :api_secret => ENV['PODIO_CLIENT_SECRET'])
Podio.client.authenticate_with_credentials(ENV['PODIO_USERNAME'],
                                           ENV['PODIO_PASSWORD'])

# Note: These endpoints should all be 'post', not 'get' to handle a form submission.
# Left as 'get' for easy testing until we deploy.
get '/constant_contact' do
  # use params[:email_adddress] to access email from form submission
  'Hello from Constant Contact endpoint'
end

post '/podio_contact' do
  content_type :json
  PodioWrapper.log_new_contact(params[:name],
                               params[:email],
                               params[:phone]).to_json

  redirect to("http://www.jodymichael.com/thank-you")
end

