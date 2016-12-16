require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'time'
require 'date'
require 'adash/config'

class Net::HTTPResponse
    attr_accessor :json
end

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

    def deregistrate_device
      headers = {
        'x-amzn-accept-type': 'com.amazon.dash.replenishment.DrsDeregisterResult@1.0',
        'x-amzn-type-version': 'com.amazon.dash.replenishment.DrsDeregisterInput@1.0'
      }
      path = "/deviceModels/#{@device_model}/devices/#{@serial}/registration"
      response = request_drs(:delete, path, headers: headers)
      save_credentials_without_device_model(@device_model)
      response
    end

    def device_status(most_recently_active_date)
      headers = {
        'x-amzn-accept-type': 'com.amazon.dash.replenishment.DrsDeviceStatusResult@1.0',
        'x-amzn-type-version': 'com.amazon.dash.replenishment.DrsDeviceStatusInput@1.0'
      }
      path = '/deviceStatus'
      request_drs(:post, path, headers: headers, params: { 'mostRecentlyActiveDate' =>  convert_to_iso8601(most_recently_active_date) })
    end

    def subscription_info
      headers = {
        'x-amzn-accept-type': 'com.amazon.dash.replenishment.DrsSubscriptionInfoResult@1.0',
        'x-amzn-type-version': 'com.amazon.dash.replenishment.DrsSubscriptionInfoInput@1.0'
      }
      path = '/subscriptionInfo'
      request_drs(:get, path, headers: headers)
    end

    def slot_status(slot_id, expected_replenishment_date, remaining_quantity_in_unit, original_quantity_in_unit, total_quantity_on_hand, last_use_date)
      headers = {
        'x-amzn-accept-type': 'com.amazon.dash.replenishment.DrsSlotStatusResult@1.0',
        'x-amzn-type-version': 'com.amazon.dash.replenishment.DrsSlotStatusInput@1.0'
      }
      path = "/slotStatus/#{slot_id}"
      params = {
        'expectedReplenishmentDate' => convert_to_iso8601(expected_replenishment_date),
        'remainingQuantityInUnit' => remaining_quantity_in_unit,
        'originalQuantityInUnit' => original_quantity_in_unit,
        'totalQuantityOnHand' => total_quantity_on_hand,
        'lastUseDate' => convert_to_iso8601(last_use_date)
      }
      request_drs(:post, path, headers: headers, params: params)
    end

    def replenish(slot_id)
      headers = {
        'x-amzn-accept-type': 'com.amazon.dash.replenishment.DrsReplenishResult@1.0',
        'x-amzn-type-version': 'com.amazon.dash.replenishment.DrsReplenishInput@1.0'
      }
      path = "/replenish/#{slot_id}"
      response = request_drs(:post, path, headers: headers, params: params)
      # TODO: imprement response processing
      # https://developer.amazon.com/public/solutions/devices/dash-replenishment-service/docs/dash-replenish-endpoint
    end

    def get_token
      if @access_token
        @access_token
      else
        resp = request_token
        process_token_response(resp)
      end
    end

  private

    def convert_to_iso8601(input)
      case input
      when Date, Time
        input.iso8601
      when String
        input
      else
        input.to_s
      end
    end

    def process_token_response(resp)
      if resp.json['error']
        puts resp.json['error']
        puts resp.json['error_description']
        nil
      else
        credentials = get_credentials
        device = get_device_from_credentials(credentials, @device_model)
        @access_token = resp.json['access_token']
        @refresh_token = resp.json['refresh_token']
        device['access_token'] = @access_token
        device['refresh_token'] = @refresh_token
        save_credentials_with_device(credentials, device)
        @access_token
      end
    end

    def request_drs(method, path, headers: {}, params: {})
      url = "https://#{@drs_host}#{path}"
      if @authorization_code.nil?
        raise 'Authorization Code is not set'
      end
      if @access_token.nil?
        token = get_token
        if token.nil?
          raise 'Failed to get token'
        end
      end
      resp = request(method, url, headers: headers, params: params)
      if resp.code == '400' && resp.json['message'] == 'Invalid token' && @refresh_token
        resp = refresh_access_token
        process_token_response(resp)
      end
    end

    def refresh_access_token
      params = {
        grant_type: 'refresh_token',
        refresh_token: @refresh_token,
        client_id: Adash::Config.client_id,
        client_secret: Adash::Config.client_secret
      }
      @access_token = nil
      request(:post, "https://#{@amazon_host}/auth/o2/token", params: params)
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
      save_credentials(credentials)
    end

    def save_credentials_without_device_model(device_model)
      credentials = get_credentials
      credentials['authorized_devices'] = credentials['authorized_devices'].delete_if { |d| d['device_model'] == @device_model }
      save_credentials(credentials)
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
      response.json = JSON.parse(response.body)
      response
    end
  end
end
