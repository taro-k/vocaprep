require 'rubygems'
require 'nokogiri'
require 'net/http'
require 'uri'

# The following function adopts redirect.
def fetch(uri_str, limit = 10)
  # You should choose better exception.
  raise ArgumentError, 'HTTP redirect too deep' if limit == 0
  response = Net::HTTP.get_response(URI.parse(uri_str))
  case response
  when Net::HTTPSuccess
    response
  when Net::HTTPRedirection
    fetch(response['location'], limit - 1)
  else
    response.value
  end
end
