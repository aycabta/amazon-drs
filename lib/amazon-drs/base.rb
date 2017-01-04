require 'time'

module AmazonDrs
  class Base
    attr_accessor :request_id, :date, :error_type, :error_description_url

    def initialize(response)
      @response = response
      parse_header(response.header)
      parse_body(response.body)
    end

    def parse_header(headers)
      headers.each_pair do |key, value|
        case key.downcase
        when 'x-amzn-errortype'
          # Value examples:
          #   InvalidTokenException:http://internal.amazon.com/coral/com.amazon.parkeraccioservice/
          #   OA2InvalidRequestException:http://internal.amazon.com/coral/com.amazon.panda/
          @error_type, @error_description_url = value.split(':', 2)
        when 'x-amzn-requestid'
          # Example:
          #   X-Amzn-Requestid: d296d296-d1d1-1111-8c8c-0b43820b4382
          @request_id = value
        when 'x-amz-date'
          # Example:
          #   X-Amz-Date: Mon, 02 Jan 2017 22:35:53 GMT
          @date = Time.rfc2822(value)
        end
      end
    end
    private :parse_header

    def parse_body(body)
      # abstract
    end
    private parse_body
  end
end
