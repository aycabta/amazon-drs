require 'json'
require 'amazon-drs/base'

module AmazonDrs
  class SubscriptionInfo < Base
    attr_accessor :slots

    def parse_body(body)
      json = JSON.parse(body)
      @slots = {}
      json['slotsSubscriptionStatus'].each_pair do |slot_id, available|
        @slots[slot_id] = available
      end
    end
  end
end
