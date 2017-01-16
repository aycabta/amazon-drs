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
      resp = ''
      resp += "ERROR @error: " if @error
      resp += @message if @message
      resp += @error_description if @error_description
    end

    def to_s
      inspect
    end
  end
end

