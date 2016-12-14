require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'adash/config'

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
      headers = {
        'x-amzn-accept-type': 'com.amazon.dash.replenishment.DrsDeregisterResult@1.0',
        'x-amzn-type-version': 'com.amazon.dash.replenishment.DrsDeregisterInput@1.0'
      }
      request(:delete, "https://#{@drs_host}/deviceModels/#{device_model}/devices/#{serial}/registration", headers: headers)
    end

    def get_token(device_model)
      config_path = "#{Dir.home}/.config/adash/config"
      if File.exist?(config_path)
        data = YAML.load_file(open(config_path, 'r'))
        i = data['authorized_devices'].find_index { |d| d['device_model'] == device_model }
        device = data['authorized_devices'][i]
        if device['access_token']
          device['access_token']
        elsif device['authorization_code']
          resp = request_token(device['authorization_code'])
          resp_json = JSON.parse(resp.body)
          if resp_json['error']
            puts resp_json['error']
            puts resp_json['error_description']
            nil
          else
            device['access_token'] = resp_json['access_token']
            device['refresh_token'] = resp_json['refresh_token']
            data['authorized_devices'][i] = device
            open(config_path, 'w') do |f|
              f.write(data.to_yaml)
            end
            device['access_token']
          end
        end
      else
        nil
      end
    end

    def request_token(authorization_code)
      params = {
        grant_type: 'authorization_code',
        code: authorization_code,
        client_id: Adash::Config.client_id,
        client_secret: Adash::Config.client_secret,
        redirect_uri: "http://localhost:#{Adash::Config.redirect_port}/"
      }
      request(:post, "https://#{@amazon_host}/auth/o2/token", params: params)
    end

  private

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
