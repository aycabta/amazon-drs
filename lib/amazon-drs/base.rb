require 'time'

module AmazonDrs
  class Base
    attr_accessor :status_code, :request_id, :date, :error_type, :error_description_url

    def initialize(response)
      @response = response
      @status_code = response.code.to_i
      parse_header(response)
      parse_body(response.body)
    end

    private def parse_header(response)
      response.each do |key, value|
        case key.downcase
        when 'x-amzn-errortype'
          # Examples:
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

    private def parse_body(body)
      # abstract
    end

    def inspect
      if @status_code == 200
        self.class.name
      else
        resp = "ERROR #{@status_code} : "
        resp += @message if instance_variable_defined?(:@message) && @message
        resp += @error_description if instance_variable_defined?(:@error_description) && @error_description
        resp
      end
    end
  end
end
