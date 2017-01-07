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
      assert_match(/^[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12}$/, ret.request_id)
      assert_kind_of(Time, ret.date)
      assert_kind_of(Hash, ret.slots)
      key = ret.slots.keys.first
      value = ret.slots[key]
      assert_kind_of(String, key)
      assert_boolean(value)
    end
  end
end

