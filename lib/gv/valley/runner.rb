require 'gv/bedrock/service'
require 'gv/common/host_helper'
require 'gv/common/docker_helper'
require 'gv/valley/app'
require 'yaml'

module GV
  module Valley
    
    class Runner < GV::Bedrock::Service
      
      include GV::Common::HostHelper
      include GV::Common::DockerHelper
      
      def initialize
        super
        pull_image_if_does_not_exists "flynn/slugrunner"
        register_all
      end
      
      
      ##
      # runs one-off job
      
      def run name, cmd, &block
        app = App.find!(name)  
                      
        cleanup
 
        params =  %(--rm -a stdout -a stderr ) #note that space at the end!
        params << %(-i -a stdin) if cmd =~ Sticks::Pipe::INTERACTIVE_COMMANDS
        cmd    =  %(docker run --name=#{app[:name]}.run.#{genuuid()} #{params} #{getenv(app)} flynn/slugrunner #{cmd})

        debug "Runner#run name:#{name}, cmd:#{cmd}"     
    
        result = pipe cmd, &block
        
        sleep 2
        
        cleanup
        result
      end 
      
      
      ##
      # force removes all matching jobs
      
      def remove name, type = nil, &block
        debug "Runner#remove name:#{name}, type:#{type}"     
        
        batch "#{name}.#{type}", "kill", true
        batch "#{name}.#{type}", "rm", true   
        unregister_all(/#{name}\.#{type}\./)
      end 
      
      
      ##
      # starts process
      
      def start name, type, index, &block
        raise "AppNotFound" unless app = App.find(name) 
        
        info "Starting #{name}.#{type}.#{index}"
        
        cleanup
    
        params = %(-d -p #{self.external_ip}::#{App::PORT})
        cmd = %(docker run --name=#{name}.#{type}.#{index} #{params} #{getenv(app)} flynn/slugrunner start #{type})
        
        debug "Runner#start name:#{name}, type:#{type} index:#{index}"     
                
        container_id = pipe(cmd)
        
        if container_id =~ /^[a-zA-Z0-9]{64}$/
          
          register "#{name}.#{type}.#{index}"
          info(container_id)
          
        elsif container_id.include? "Error: Conflict"
          error "Container name conflict: #{name}.#{type}.#{index}, docker service reloading..." 
    
          restart_docker!

          remove name, type
          start name, type, index, &block
        else
          raise container_id
        end
        
      end 
      
      
      ## 
      # retrives logs
      
      def logs name, follow = false, &block
        debug "Runner#logs name:#{name}, follow:#{follow}"     
        
        pipe "docker logs #{follow ? "-f" : nil} #{container_id(name)}", &block
      end
      
      
      private
      
      def getenv app
        app['config'].map{ |k,v| "-e #{k}=#{v}" }.join(" ")
      end
      
      def genuuid
        rand(2**64).to_s(36) # from heroku/slugcompiler
      end 

      def register_all
        pipe("docker ps | grep runner/init").chomp.split("\n").each{|l| 
          cols = l.split(/\s{3,}/)
          name = cols.last
          unregister_all(/#{name}/)
          register name
        }
      end
      
      def unregister_all name
        unregister name while (self.class.space.read([:ps, name, nil, self.external_ip],0) rescue nil)
      end
      
      def register name
        self.class.space.write [:ps, name, self, self.external_ip ]
      end
      
      def unregister name
        self.class.space.take([:ps, name, nil, self.external_ip],0) rescue nil
      end
       
      
    end
    
  end
end