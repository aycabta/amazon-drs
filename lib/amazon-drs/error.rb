require 'amazon-drs/base'

module AmazonDrs
  class Error < Base
    attr_accessor :message

    def parse_body
      json = JSON.parse(body)
      @message = json['message'] if json['message']
    end
  end
end

