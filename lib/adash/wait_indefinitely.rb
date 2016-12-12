require 'launchy'

module Adash
  class WaitIndefinitely
    def initialize
      require 'webrick'
      @port = 55582
      @code_box = Queue.new
      @code_cv = ConditionVariable.new
      @code_mutex = Mutex.new
      @server = WEBrick::HTTPServer.new({ :BindAddress => '127.0.0.1', :Port => @port })
      @server.mount_proc('/getting_started', proc { |req, res|
        res.content_type = 'text/html'
        content = %Q`<p>Please go <a href="#{amazon_authorization_url('sample device model', 'aaaa00001')}">initial tour</a>.</p>`
        res.body = "<html><body>\n#{content}\n</body></html>"
      })
      @server.mount_proc('/', proc { |req, res|
        res.content_type = 'text/html'
        if req.query.include?('code')
          content = '<p>Done. Please close this tab.</p>'
          @code_mutex.synchronize {
            @code_box.push(req.query['code'])
            @code_cv.signal
          }
        else
          content = "<dl>\n" + req.query.map { |k, v| "<dt>#{k}</dt><dd>#{v}</dd>" }.join("\n") + "\n</dl>"
        end
        res.body = "<html><body>\n#{content}\n</body></html>"
      })
      @server
    end

    def amazon_authorization_url(device_model, serial)
      base = 'https://www.amazon.com/ap/oa?'
      params = {
        client_id: 'amzn1.application-oa2-client.b5c87429af104636bd7ae83df68383e1',
        scope: 'dash:replenish',
        response_type: 'code',
        redirect_uri: "http://localhost:#{@port}/",
        scope_data: %Q`{"dash:replenish":{"device_model":"#{device_model}","serial":"#{serial}","is_test_device":true}}`
      }
      "#{base}#{params.map{ |k, v| "#{k}=#{v}" }.join(?&)}"
    end

    def get_code
      t = Thread.new do
        @code_mutex.synchronize {
          # TODO: wait for WEBrick launch
          Launchy.open('http://localhost:55582/getting_started')
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
