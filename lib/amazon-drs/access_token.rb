require 'amazon-drs/base'

module AmazonDrs
  class AccessToken < Base
    attr_accessor :access_token, :refresh_token, :token_type, :expires_in

    def parse_body(body)
      json = JSON.parse(body)
      @access_token = json['access_token']
      @refresh_token = json['refresh_token']
      @token_type = json['token_type']
      @expires_in = json['expires_in']
    end
  end
end
