require 'faraday'
require 'uri'
require 'json'

class HubspotWrapper
  MyHubspotError = Class.new(StandardError)
  def initialize args
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
    @page_url ||= ''
    @request_ip ||= ''
    @hutk ||= ''
    @page_title ||= ''

    raise MyHubspotError.new(
      "MyHubspot API Error: Missing portal_id and/or form_guid"
      ) unless @portal_id && @form_guid

    base_url = "https://forms.hubspot.com/"
    puts "base_url: #{base_url}"
    @conn = Faraday.new(
      url:      base_url,
      ssl:      { verify: false },
      headers:  { accept: 'application/json' })
  end

  def submit params
    params[:hs_context] = hs_context

    puts "params:  #{params}"
    puts "url: uploads/form/v2/#{@portal_id}/#{@form_guid}"
    puts "body: #{URI.encode_www_form params}"

    response = @conn.post do |req|
      req.url "uploads/form/v2/#{@portal_id}/#{@form_guid}"
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
      req.body = URI.encode_www_form params
    end

    puts "response: #{response.status}"
    if response.status == 204 || 302 #302 is redirect with a location to the "thank you" page
      response
    else
      raise MyHubspotError.new("MyHubspot API Error: #{response.body} (status code #{response.status})")
    end
  end

  def hs_context
    values = {
      'hutk' => @hutk,
      'ipAddress' => @request_ip,
      'pageUrl' => @page_url,
      'pageName' => @page_title,
      'redirectUrl' => 'http://www.jodymichael.com/thank-you'
    }
    puts "hs_context: #{values}"
    values.to_json
  end
end