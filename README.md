# Adash

It's a CLI for Amazon Dash Replenishment Service.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'adash'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install adash

## Usage

### `adash init`

You can initialize with `adash init` sub-command. It takes `name` and `device_model` what likes `01234567-89ab-cdef-0123-456789abcdef`.

```bash
$ adash init lozenge 01234567-89ab-cdef-0123-456789abcdef
[2016-12-23 00:11:44] INFO  WEBrick 1.3.1
[2016-12-23 00:11:44] INFO  ruby 2.3.3 (2016-11-21) [x86_64-linux]
[2016-12-23 00:11:44] INFO  WEBrick::HTTPServer#start: pid=11687 port=55582
...
```

WEBrick web server runs intenally, and a browser is opened for it.
You are requested OAuth authorization and DRS initialization.

### `adash list`

### `adash list-slot`

### `adash replenish`

### `adash deregistrate`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/adash.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

