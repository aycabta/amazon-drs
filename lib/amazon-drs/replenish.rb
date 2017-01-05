require 'amazon-drs/base'

module AmazonDrs
  class Replenish < Base
    attr_accessor :event_instance_id, :detail_code, :message

    def parse_body(body)
      json = JSON.parse(body)
      @event_instance_id = json['eventInstanceId'] if json['eventInstanceId']
      if json['detailCode']
        # STANDARD_ORDER_PLACED, TEST_ORDER_PLACED or ORDER_INPROGRESS
        @detail_code = json['detailCode']
      else
        @detail_code = 'ERROR'
      end
      @message = json['message'] if json['message']
    end
  end
end

