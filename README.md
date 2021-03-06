# AmazonDrs

It's for Amazon Dash Replenishment Service.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'amazon-drs'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install amazon-drs

## Usage

```ruby
# Please use access_token what is prepared beforehand:
# https://rubygems.org/gems/omniauth-amazon
client = AmazonDrs::Client.new('device_model') do |c|
  c.authorization_code = 'authorization_code'
  c.serial = 'serial'
  c.redirect_uri = 'http://redirect_uri/'
  c.access_token = 'access_token'
  c.refresh_token = 'refresh_token'
  c.client_id = 'aaa'
  c.client_secret = 'secret'
end
@drs.subscription_info
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aycabta/amazon-drs.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Badges

- [![Build Status](https://travis-ci.org/aycabta/amazon-drs.svg)](https://travis-ci.org/aycabta/amazon-drs)
- [![Build Status](https://ci.appveyor.com/api/projects/status/github/aycabta/amazon-drs?branch=master&svg=true)](https://ci.appveyor.com/project/aycabta/amazon-drs)
