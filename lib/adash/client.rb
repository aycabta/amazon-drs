require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'adash/config'

module Adash
  class Client
    attr_accessor :access_token
    attr_writer :user_agent

    def initialize(device_model)
      @drs_host = 'dash-replenishment-service-na.amazon.com'
      @amazon_host = 'api.amazon.com'
      @device_model = device_model
      @serial = nil
      @authorization_code = nil
      @redirect_uri = nil
      @access_token = nil
      @refresh_token = nil
      credentials = get_credentials
      i = credentials['authorized_devices'].find_index { |d| d['device_model'] == @device_model }
      if i
        device = credentials['authorized_devices'][i]
        @serial = device['serial']
        @authorization_code = device['authorization_code']
        @redirect_uri = device['redirect_uri']
        @access_token = device['access_token']
        @refresh_token = device['refresh_token']
      end
    end

    def user_agent
      @user_agent ||= "AdashRubyGem/#{Adash::VERSION}/#{RUBY_DESCRIPTION}"
    end

    def deregistrate_device(device_model, serial)
      headers = {
        'x-amzn-accept-type': 'com.amazon.dash.replenishment.DrsDeregisterResult@1.0',
        'x-amzn-type-version': 'com.amazon.dash.replenishment.DrsDeregisterInput@1.0'
      }
      request(:delete, "https://#{@drs_host}/deviceModels/#{device_model}/devices/#{serial}/registration", headers: headers)
    end

    def get_token
      if @access_token
        @access_token
      else
        resp = request_token
        resp_json = JSON.parse(resp.body)
        if resp_json['error']
          puts resp_json['error']
          puts resp_json['error_description']
          nil
        else
          credentials = get_credentials
          device = get_device_from_credentials(credentials, @device_model)
          @access_token = resp_json['access_token']
          @refresh_token = resp_json['refresh_token']
          device['access_token'] = @access_token
          device['refresh_token'] = @refresh_token
          save_credentials_with_device(credentials, device)
          @access_token
        end
      end
    end

    def request_token
      params = {
        grant_type: 'authorization_code',
        code: @authorization_code,
        client_id: Adash::Config.client_id,
        client_secret: Adash::Config.client_secret,
        redirect_uri: "http://localhost:#{Adash::Config.redirect_port}/"
      }
      request(:post, "https://#{@amazon_host}/auth/o2/token", params: params)
    end

  private

    def get_credentials
      if File.exist?(Adash::Config.credentials_path)
        credentials = YAML.load_file(Adash::Config.credentials_path)
      else
        { 'authorized_devices' => [] }
      end
    end

    def save_credentials(credentials)
      open(Adash::Config.credentials_path, 'w') do |f|
        f.write(credentials.to_yaml)
      end
    end

    def get_device_from_credentials(credentials, device_model)
      i = credentials['authorized_devices'].find_index { |d| d['device_model'] == device_model }
      if i
        credentials['authorized_devices'][i]
      else
        nil
      end
    end

    def save_credentials_with_device(credentials, device)
      i = credentials['authorized_devices'].find_index { |d| d['device_model'] == @device_model }
      if i
        credentials['authorized_devices'][i] = device
      else
        credentials['authorized_devices'] << device
      end
      open(Adash::Config.credentials_path, 'w') do |f|
        f.write(credentials.to_yaml)
      end
    end

    def request(method, url, headers: {}, params: {})
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
      headers.each do |key, value|
        request[key] = value
      end
      if not @access_token.nil?
        request["Authorization"] = "Bearer #{@access_token}"
      end
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.request(request)
    end
  end
end
