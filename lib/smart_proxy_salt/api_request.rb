require 'json'
require 'net/http'
require 'net/https'
require 'uri'

module Proxy::Salt
  class ApiError < RuntimeError; end

  class ApiRequest
    attr_reader :url, :username, :password, :auth

    def initialize
      @url = Proxy::Salt::Plugin.settings.api_url
      @auth = Proxy::Salt::Plugin.settings.api_auth
      @username = Proxy::Salt::Plugin.settings.api_username
      @password = Proxy::Salt::Plugin.settings.api_password

      begin
        URI.parse(url)
      rescue URI::InvalidURIError => e
        raise ConfigurationError.new("Invalid Salt api_url setting: #{e}")
      end
    end

    def post(path, options = {})
      uri              = URI.parse(url)
      http             = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl     = uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      path = [uri.path, path].join('/') unless uri.path.empty?

      request = Net::HTTP::Post.new(URI.join(uri.to_s, path).path)
      request.add_field('Accept', 'application/json')
      request.set_form_data(options.merge(:username => username, :password => password, :eauth => auth))

      response = http.request(request)

      if response.is_a? Net::HTTPOK
        JSON.load(response.body)
      else
        raise ApiError.new("Failed to query Salt API (#{response.code}): #{response.body}")
      end
    end
  end
end
