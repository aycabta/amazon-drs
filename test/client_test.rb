require 'helper'
require 'amazon-drs'

class AmazonDrs::Client::Test < Test::Unit::TestCase
  sub_test_case '#subscription_info' do
    setup do
      device = fixture('device.json')
      @jaga = device.json['jaga']
      @drs = AmazonDrs::Client.new(@jaga['device_model']) do |c|
        c.authorization_code = device['authorization_code']
        c.serial = @jaga['serial']
        c.redirect_uri = device['redirect_uri']
        c.access_token = device['access_token']
        c.refresh_token = device['refresh_token']
        c.client_id = 'aaa'
        c.client_secret = 'secret'
        c.redirect_uri = device['redirect_uri']
      end
      subscription_info = fixture('subscription_info.json')
      # TODO: Add header for response
      stub_request(:get, "https://dash-replenishment-service-na.amazon.com/subscriptionInfo")
        .to_return(
          body: subscription_info,
          status: 200,
          headers: {
            'X-Amzn-Requestid' => 'd296d296-d1d1-1111-8c8c-0b43820b4382',
            'X-Amz-Date' => 'Mon, 02 Jan 2017 22:35:53 GMT'
          }
        )
    end
    test 'requests the correct resource' do
      ret = @drs.subscription_info
      assert_kind_of(AmazonDrs::SubscriptionInfo, ret)
    end
  end
end

