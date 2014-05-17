require 'gv/bedrock/service'
require 'gv/bedrock/config'
require 'gv/common/host_helper'
require 'goliath/api'
require 'goliath/runner'
require 'uri' 

module GV
  module Valley
    
    class FileServer < GV::Bedrock::Service
      
      include GV::Common::HostHelper
      
      class FileSystem
        CHUNKSIZE = 65536

        def initialize(path)
          @path  = path
        end

        def get
          open(@path, 'rb') do |file|
            yield file.read(CHUNKSIZE) until file.eof?
          end
        end
  
      end
      
      class Api < Goliath::API
  
        use Goliath::Rack::DefaultMimeType
        use Goliath::Rack::Render, 'json'
        use Goliath::Rack::Heartbeat

        use Goliath::Rack::Validation::RequestMethod, %w(GET PUT DELETE)

        def on_headers(env, headers)
          env['async-headers'] = headers
        end

        def on_body(env, data)
          (env['async-body'] ||= '') << data
        end

        def response(env)
    
          path = "#{ENV['GV_HOME']}/#{env['REQUEST_PATH']}"
    
          case env['REQUEST_METHOD']
      
          when 'GET'
    
            headers = {'X-filename' => path}

            raise Goliath::Validation::NotFoundError unless File.file?(path)

            operation = proc do
              FileSystem.new(path).get { |chunk| env.chunked_stream_send(chunk) }
            end

            callback = proc do |result|
              env.chunked_stream_close
            end

            EM.defer operation, callback

            headers.merge!( 'X-Stream' => 'Goliath')
            chunked_streaming_response(200, headers)
      
          when 'PUT'
            
            File.delete(path) rescue nil
            result = File.open(path, File::RDWR|File::CREAT){ |f| f.puts env['async-body'] }
            [ 200, {}, {body: "OK"} ]        
    
          when 'DELETE'  
            result = File.delete(path)
            [ 200, {}, {body: result } ]                
          end
        end

      end 
            
      def url
        "http://#{self.external_ip}:#{self.port}"
      end
    
      def port
        ENV['PORT'] ||= '9000'
      end
  
      def initialize
        super
        ENV['GV_HOME'] ||= GV::Bedrock::Config.service.get("home")
        runner = Goliath::Runner.new(ARGV, nil)
        runner.api = Api.new
        runner.app = Goliath::Rack::Builder.build(Api, runner.api)
        runner.port = self.port
        runner.log_file = "/var/log/gv-file_server.log"
        runner.pid_file = "/var/run/gv-file_server.pid"        
        runner.daemonize = true
        runner.run
        at_exit { 
          pid = File.read("/var/run/gv-file_server.pid").chomp.to_i
          Process.kill("TERM",pid) rescue nil
          File.delete("/var/run/gv-file_server.pid")          
          File.delete("/var/log/gv-file_server.log")
          File.delete("/var/log/gv-file_server.log_stdout.log")          
        }
      end
      
    end
  end
end
