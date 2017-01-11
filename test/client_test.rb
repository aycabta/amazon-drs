require 'helper'
require 'amazon-drs'

class AmazonDrs::Client::Test < Test::Unit::TestCase
  sub_test_case '#subscription_info' do
    setup do
      @drs = create_client
      subscription_info = fixture('subscription_info.json')
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
      assert_equal(200, ret.status_code)
      assert_match(/^[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12}$/, ret.request_id)
      assert_kind_of(Time, ret.date)
      assert_kind_of(Hash, ret.slots)
      key = ret.slots.keys.first
      value = ret.slots[key]
      assert_kind_of(String, key)
      assert_boolean(value)
    end
  end
  sub_test_case '#get_token' do
    setup do
      jaga = fixture('device.json').json['jaga']
      @access_token = 'test'
      @drs = AmazonDrs::Client.new(jaga['device_model']) do |c|
        c.access_token = @access_token
      end
    end
    test 'is correct' do
      ret = @drs.get_token
      assert_equal(@access_token, ret)
    end
  end
  sub_test_case '#get_token' do
    setup do
      jaga = fixture('device.json').json['jaga']
      @drs = AmazonDrs::Client.new(jaga['device_model']) do |c|
        c.client_id = 'aaa'
        c.client_secret = 'secret'
      end
      access_token_error = fixture('access_token_error.json')
      stub_request(:post, "https://api.amazon.com/auth/o2/token")
        .to_return(
          body: access_token_error,
          status: 400,
          headers: {
            'X-Amzn-Requestid' => 'd296d296-d1d1-1111-8c8c-0b43820b4382',
            'X-Amz-Date' => 'Mon, 02 Jan 2017 22:35:53 GMT',
            'X-Amzn-Errortype' => 'OA2InvalidRequestException:http://internal.amazon.com/coral/com.amazon.panda/'
          }
        )
    end
    test 'is invalid token' do
      ret = @drs.get_token
      assert_kind_of(AmazonDrs::Error, ret)
      assert_equal(400, ret.status_code)
      assert_match(/^[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12}$/, ret.request_id)
      assert_kind_of(Time, ret.date)
      assert_equal('OA2InvalidRequestException', ret.error_type)
      assert_equal('http://internal.amazon.com/coral/com.amazon.panda/', ret.error_description_url)
    end
  end
end

