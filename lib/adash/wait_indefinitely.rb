
module Adash
  class WaitIndefinitely
    def initialize
      require 'webrick'
      @port = 55582
      @code_box = Queue.new
      @code_cv = ConditionVariable.new
      @code_mutex = Mutex.new
      @server = WEBrick::HTTPServer.new({ :BindAddress => '127.0.0.1', :Port => @port })
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

    def get_code
      t = Thread.new do
        @code_mutex.synchronize {
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
