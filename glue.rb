require 'sinatra'
require 'dotenv'
require 'podio'
require 'json'
require 'data_mapper'
require './podio_wrapper'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/glue.db")

class Submission
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :email, String
  property :phone, String
  property :message, Text
  property :contact_db, String

  property :created_at, DateTime
end

# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the post table
Submission.auto_upgrade!

Dotenv.load
set :protection, :except => [:http_origin]
use Rack::Protection::HttpOrigin, :origin_whitelist => ['http://jodymichael.com',
                                                        'http://www.jodymichael.com',
                                                        'http://www.careercheetah.net',
                                                        'http://careercheetah.net',
                                                        'http://localhost:8000']

# Note: These endpoints should all be 'post', not 'get' to handle a form submission.
# Left as 'get' for easy testing until we deploy.
get '/constant_contact' do
  # use params[:email_adddress] to access email from form submission
  'Hello from Constant Contact endpoint'
end

post '/podio_contact' do
  if params['name'] && (params['email'] || params['phone'])

    Submission.create!(name: params['name'],
                       email: params['email'],
                       phone: params['phone'],
                       message: params['message'],
                       created_at: Time.now,
                       contact_db: params['contact_db'] || "jma")

    Podio.setup(:api_key => ENV['PODIO_CLIENT_ID'],
                :api_secret => ENV['PODIO_CLIENT_SECRET'])
    Podio.client.authenticate_with_credentials(ENV['PODIO_USERNAME'],
                                               ENV['PODIO_PASSWORD'])

    w = PodioWrapper.new(params['contact_db'] || "jma")
    w.log_new_contact(params['name'],
                      params['email'],
                      params['phone'],
                      params['message']).to_json
  end

  redirect to(params['redirect'] || "http://www.jodymichael.com/thank-you") if Sinatra::Base.production?
end
