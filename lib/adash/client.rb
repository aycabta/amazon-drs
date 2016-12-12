require 'net/http'
require 'uri'
require 'json'

module Adash
  class Client
    attr_writer :user_agent

    def initialize
      @drs_host = 'dash-replenishment-service-na.amazon.com'
      @amazon_host = 'api.amazon.com'
    end

    def user_agent
      @user_agent ||= "AdashRubyGem/#{Adash::VERSION}/#{RUBY_DESCRIPTION}"
    end

    def deregistrate_device(device_model, serial)
      request(:delete, "https://#{@drs_host}/deviceModels/#{deviceModels}/devices/#{serial}/registration")
    end

    def get_token
      params = {
        grant_type: 'authorization_code',
        code: '',
        client_id: @@client_id,
        client_secret: @@client_secret,
        redirect_uri: 'http://localhost:55582/'
      }
      request(:post, "https://#{@amazon_host}/auth/o2/token", params)
    end

    open("#{File.expand_path('../../../data', __FILE__)}/client", 'r') do |f|
      @@client_id = f.readline.chomp
      @@client_secret = f.readline.chomp
    end

    def self.client_id
      @@client_id
    end

    def self.client_secret
      @@client_secret
    end

  private

    def request(method, url, params = {})
      uri = URI.parse(url)
      if params.any?{ |key, value| value.is_a?(Enumerable) }
        converted_params = []
        params.each do |key, value|
          if value.is_a?(Enumerable)
            value.each_index do |i|
              converted_params << ["#{key}[#{i}]", value[i]]
            end
          else
            converted_params << [key, value]
          end
        end
        params = converted_params
      end
      case method
      when :delete
        uri.query = URI.encode_www_form(params)
        request = Net::HTTP::Delete.new(uri)
      when :get
        uri.query = URI.encode_www_form(params)
        request = Net::HTTP::Get.new(uri)
      when :post
        request = Net::HTTP::Post.new(uri.path)
        request.body = URI.encode_www_form(params)
      end
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request['User-Agent'] = @user_agent
      request['x-amzn-accept-type'] = 'com.amazon.dash.replenishment.DrsReplenishResult@1.0'
      request['x-amzn-type-version'] = 'com.amazon.dash.replenishment.DrsReplenishInput@1.0'
      if not @access_token.nil?
        request["Authorization"] = "Bearer #{@access_token}"
      end
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.request(request)
    end
  end
end
