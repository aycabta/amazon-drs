require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'time'
require 'date'
require 'amazon-drs/deregistrate_device'
require 'amazon-drs/subscription_info'
require 'amazon-drs/error'
require 'amazon-drs/slot_status'
require 'amazon-drs/access_token'

class Net::HTTPResponse
    attr_accessor :json
end

module AmazonDrs
  class Client
    attr_accessor :device_model, :serial, :authorization_code, :redirect_uri, :access_token, :refresh_token, :client_id, :client_secret
    attr_accessor :on_new_token
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
      @on_new_token = nil
      @client_id = nil
      @client_secret = nil
      yield(self) if block_given?
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
      if response.code == '200'
        ::AmazonDrs::DeregistrateDevice.new(response)
      else
        ::AmazonDrs::Error.new(response)
      end
    end

    def device_status(most_recently_active_date)
      headers = {
        'x-amzn-accept-type': 'com.amazon.dash.replenishment.DrsDeviceStatusResult@1.0',
        'x-amzn-type-version': 'com.amazon.dash.replenishment.DrsDeviceStatusInput@1.0'
      }
      path = '/deviceStatus'
      request_drs(:post, path, headers: headers, params: { 'mostRecentlyActiveDate' =>  convert_to_iso8601(most_recently_active_date) })
      if response.code == '200'
        ::AmazonDrs::DeviceStatus.new(response)
      else
        ::AmazonDrs::Error.new(response)
      end
    end

    def subscription_info
      headers = {
        'x-amzn-accept-type': 'com.amazon.dash.replenishment.DrsSubscriptionInfoResult@1.0',
        'x-amzn-type-version': 'com.amazon.dash.replenishment.DrsSubscriptionInfoInput@1.0'
      }
      path = '/subscriptionInfo'
      response = request_drs(:get, path, headers: headers)
      if response.code == '200'
        ::AmazonDrs::SubscriptionInfo.new(response)
      else
        ::AmazonDrs::Error.new(response)
      end
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
      response = request_drs(:post, path, headers: headers, params: params)
      if response.code == '200'
        ::AmazonDrs::SlotStatus.new(response)
      else
        ::AmazonDrs::Error.new(response)
      end
    end

    def replenish(slot_id)
      headers = {
        'x-amzn-accept-type': 'com.amazon.dash.replenishment.DrsReplenishResult@1.0',
        'x-amzn-type-version': 'com.amazon.dash.replenishment.DrsReplenishInput@1.0'
      }
      path = "/replenish/#{slot_id}"
      response = request_drs(:post, path, headers: headers)
      if response.code == '200'
        ::AmazonDrs::Replenish.new(response)
      else
        ::AmazonDrs::Error.new(response)
      end
    end

    def get_token
      if @access_token
        @access_token
      else
        resp = request_token
        process_token_response(resp)
        resp
      end
    end

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
    private :convert_to_iso8601

    def process_token_response(resp)
      if resp.kind_of?(AmazonDrs::Error)
        nil
      else
        @access_token = resp.access_token
        @refresh_token = resp.refresh_token
        @on_new_token.call(@access_token, @refresh_token) if @on_new_token
        @access_token
      end
    end
    private :process_token_response

    def request_drs(method, path, headers: {}, params: {})
      url = "https://#{@drs_host}#{path}"
      if @authorization_code.nil?
        raise 'Authorization Code is not set'
      end
      if @access_token.nil?
        token = get_token
        if resp.kind_of?(AmazonDrs::Error)
          raise 'Failed to get token'
        end
      end
      resp = request(method, url, headers: headers, params: params)
      if resp.code == '400' && resp.json['message'] == 'Invalid token' && @refresh_token
        resp = refresh_access_token
        process_token_response(resp)
        request(method, url, headers: headers, params: params)
      else
        resp
      end
    end
    private :request_drs

    def refresh_access_token
      params = {
        grant_type: 'refresh_token',
        refresh_token: @refresh_token,
        client_id: @client_id,
        client_secret: @client_secret
      }
      @access_token = nil
      request(:post, "https://#{@amazon_host}/auth/o2/token", params: params)
    end
    private :refresh_access_token

    def request_token
      params = {
        grant_type: 'authorization_code',
        code: @authorization_code,
        client_id: @client_id,
        client_secret: @client_secret,
        redirect_uri: @redirect_uri
      }
      response = request(:post, "https://#{@amazon_host}/auth/o2/token", params: params)
      if response.code == '200'
        ::AmazonDrs::AccessToken.new(response)
      else
        ::AmazonDrs::Error.new(response)
      end
    end
    private :request_token

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
    private :request
  end
end
