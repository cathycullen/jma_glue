require 'sinatra'
require 'sinatra/cookies'
require 'dotenv'
require 'podio'
require 'rubygems'
require 'json'
require 'data_mapper'
require 'net/http'
require 'rack'

require './podio_wrapper'
require './hubspot_wrapper'

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

get '/' do
  'Hello from jma-glue'
end

def hubspot_field(property)
  begin
    property["value"] unless property.nil?
  rescue Exception => e
    puts "glue.rb:  rescue caught in /hubspot_field #{e.message}"
    puts e.backtrace 
  end
end

post '/current_post_hubspot_contact' do
json_data = JSON.parse(request.body.read)
  puts "***********************************************************************************"
  puts "json_data #{json_data}"
  puts "***********************************************************************************"
  xx = JSON.parse (json_data.to_json)
  puts "xx #{xx.to_s}"
  puts "***********************************************************************************"
  puts "first_name #{xx["first_name"]}"
  puts "***********************************************************************************"
end

post '/post_hubspot_contact' do
  # this should only get called by someone who said contact us from the ebook download.
  # this is called from hubspot PPC workflow.
  json_data = JSON.parse(request.body.read)
  props = json_data["properties"]
  puts "***********************************************************************************"
  puts "props.keys #{props.keys}"
  puts "***********************************************************************************"
  firstname = hubspot_field (props["firstname"])
  lastname = hubspot_field (props["lastname"])
  email = hubspot_field(props["email"])
  phone = hubspot_field(props["phone"])
  message = hubspot_field(props["message"])
  puts "/post_hubspot_contact  firstname: #{firstname} lastname: #{lastname} email: #{email} message:  #{message}"
  name = podio_name(firstname, lastname)

  submit_podio_contact(name, 
      email, 
      phone,
      message,
      "jma")

end

# Note: These endpoints should all be 'post', not 'get' to handle a form submission.
# Left as 'get' for easy testing until we deploy.
get '/cc_form' do
 
  erb :cc_form 
end

get '/constant_contact' do
  # use params[:email_adddress] to access email from form submission
  'Hello from Constant Contact endpoint'
end

post '/podio_contact' do

  puts "/podio_contact "
  if params['name'] && (params['email'] || params['phone'])
    begin
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

    rescue Exception => e
      puts "glue.rb:  rescue caught in /podio_contact #{e.message}"
      puts e.backtrace 
    end
  end

  redirect to(params['redirect'] || "http://www.jodymichael.com/thank-you") 
end

def podio_name(first, last)
   first + " " + last
 end

post '/new_jma_contact' do
  # this is called by the contact us jodymichael.com/contact-us
  puts "/new_jma_contact: this is called by jodymichael.com/contact-us params:  #{params}"

  if params['first_name'] && params['last_name'] && params['page_name'] && params['form_id'] && (params['email'] || params['phone'])
    name = podio_name(params['first_name'], params['last_name'])

    submit_podio_contact(name, 
      params['email'], 
      params['phone'],
      params['message'],
      params['contact_db'] || "jma")

    # add hubspot submission here 

    submit_hubspot_contact(
      params['first_name'], 
      params['last_name'],
      params['email'], 
      params['phone'],
      params['message'],
      params['page_name'],
      params['form_id'],
      cookies[:hubspotutk])
  else
    puts "insufficient information for contact: params:  #{params}"
  end

  redirect to(params['redirect'] || "http://www.jodymichael.com/thank-you") if Sinatra::Base.production?
end

def submit_podio_contact(name, email, phone, message, contact_db)
  if message.nil?
    message = "hubspot contact us: no message"
  else
    message = "hubspot contact us: " + message
  end
  puts "submit_podio_contact : #{name} #{email} #{phone} #{message}"
    Submission.create!(name: name,
                       email: email,
                       phone: phone,
                       message: message,
                       created_at: Time.now,
                       contact_db: contact_db)

    Podio.setup(:api_key => ENV['PODIO_CLIENT_ID'],
                :api_secret => ENV['PODIO_CLIENT_SECRET'])
    Podio.client.authenticate_with_credentials(ENV['PODIO_USERNAME'],
                                               ENV['PODIO_PASSWORD'])

    w = PodioWrapper.new(params['contact_db'] || "jma")
    w.log_new_contact(name,
                      email,
                      phone,
                      message).to_json

end

def submit_hubspot_contact (first_name, last_name, email, phone, message, page_name, form_id, hubspotutk)
  wrapper = HubspotWrapper.new(
    # These are mandatory
    portal_id: ENV['HUBSPOT_PORTAL_ID'],
    form_guid: form_id,
    # These are optional
    request_ip: request.ip,
    hutk: hubspotutk,
    page_url: request.url,
    page_title: page_name
  )
  
  my_params = {
      :firstname => first_name,
      :lastname => last_name,
      :email => email, 
      :phone => phone,
      :message => message
  }
  wrapper.submit my_params

end

