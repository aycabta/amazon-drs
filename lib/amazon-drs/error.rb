require 'amazon-drs/base'

module AmazonDrs
  class Error < Base
    attr_accessor :message, :error_description, :error

    def parse_body(body)
      json = JSON.parse(body)
      @message = json['message'] if json['message']
      @error = json['error'] if json['error']
      @error_description = json['error_description'] if json['error_description']
    end

    def inspect
      resp = 'ERROR'
      resp += " #{@error}" if instance_variable_defined?(:@error) && @error
      resp += ': '
      resp += @message if instance_variable_defined?(:@message) && @message
      resp += @error_description if instance_variable_defined?(:@error_description) && @error_description
      resp
    end

    def to_s
      inspect
    end
  end
end

