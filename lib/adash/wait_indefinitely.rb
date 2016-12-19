require 'uri'
require 'erb'
require 'launchy'
require 'adash/client'
require 'adash/config'

module Adash
  class WaitIndefinitely
    attr_reader :redirect_uri

    def initialize(device_model, serial, is_test: false)
      require 'webrick'
      @device_model = device_model
      @serial = serial
      @is_test = is_test
      @redirect_uri = "http://localhost:#{Adash::Config.redirect_port}/"
      @code_box = Queue.new
      @code_cv = ConditionVariable.new
      @code_mutex = Mutex.new
      @server = WEBrick::HTTPServer.new({ :BindAddress => '127.0.0.1', :Port => Adash::Config.redirect_port })
      @server.mount_proc('/getting_started', proc { |req, res|
        res.content_type = 'text/html'
        content = %Q`<p>Please go to <a href="#{ERB::Util.html_escape(amazon_authorization_url(@device_model, @serial))}">initial tour</a>.</p>`
        res.body = render(content)
      })
      @server.mount_proc('/', proc { |req, res|
        res.content_type = 'text/html'
        if req.query.include?('code')
          content = '<p>Done. Please close this tab.</p>'
          @code_mutex.synchronize {
            @code_box.push(req.query['code'].to_s)
            @code_cv.signal
          }
        else
          content = "<dl>\n" + req.query.map { |k, v| "<dt>#{k}</dt><dd>#{v}</dd>" }.join("\n") + "\n</dl>"
        end
        res.body = render(content)
      })
    end

    def render(content)
      "<html><body>\n#{content}\n</body></html>"
    end

    def amazon_authorization_url(device_model, serial)
      base = 'https://www.amazon.com/ap/oa?'
      params = {
        client_id: Adash::Config.client_id,
        scope: 'dash:replenish',
        response_type: 'code',
        # redirect_uri must exact-match with escaped it when access_token is requested
        redirect_uri: URI.encode_www_form_component(@redirect_uri),
        scope_data: %Q`{"dash:replenish":{"device_model":"#{device_model}","serial":"#{serial}"#{ ',"is_test_device":true' if @is_test }}}`
      }
      "#{base}#{params.map{ |k, v| "#{k}=#{v}" }.join(?&)}"
    end

    def get_code
      t = Thread.new do
        @code_mutex.synchronize {
          # TODO: wait for WEBrick launch
          Launchy.open("http://localhost:#{Adash::Config.redirect_port}/getting_started")
          while @code_box.size == 0
            @code_cv.wait(@code_mutex)
            sleep 1
            @server.shutdown
          end
        }
      end
      @server.start
      @code_box.pop
    end

    def shutdown
      @server.shutdown
    end
  end
end
