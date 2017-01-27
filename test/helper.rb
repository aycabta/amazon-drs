require 'webmock/test_unit'
include WebMock::API

def fixture_path
  File.expand_path('../fixtures', __FILE__)
end

def fixture(file)
  data = File.new(File.join(fixture_path, file)).read
  data.instance_eval do
    def json
      @json ||= JSON.parse(self)
    end
  end
  data
end

def create_client()
  device = fixture('device.json')
  jaga = device.json['jaga']
  client = AmazonDrs::Client.new(jaga['device_model']) do |c|
    c.authorization_code = device['authorization_code']
    c.serial = jaga['serial']
    c.redirect_uri = device['redirect_uri']
    c.access_token = device['access_token']
    c.refresh_token = device['refresh_token']
    c.client_id = 'aaa'
    c.client_secret = 'secret'
    c.redirect_uri = device['redirect_uri']
  end
  client
end

WebMock.enable!
