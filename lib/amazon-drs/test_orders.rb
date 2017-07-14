require 'json'
require 'amazon-drs/base'

module AmazonDrs
  class TestOrders < Base
    attr_accessor :slot_order_statuses
    SlotOrderStatus = Struct.new(:order_status, :slot_id)

    def parse_body(body)
      json = JSON.parse(body)
      @slot_order_statuses = []
      json['slotOrderStatuses'].each do |item|
        @slot_order_statuses << SlotOrderStatus.new(item['orderStatus'], item['slotId'])
      end
    end
  end
end
