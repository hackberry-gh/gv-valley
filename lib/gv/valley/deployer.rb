require 'yaml'
require 'gv/bedrock/service'
require 'gv/valley/app'
require 'gv/valley/runner'
require 'gv/common/pipe_helper'


module GV
  module Valley
    
    class Deployer < GV::Bedrock::Service
      
      include GV::Common::PipeHelper
      
      ##
      # deploys app
      
      def deploy name, &block
        
        # find or create app
        unless app = App.find(name)
          app = App.create(name)
        end
        
        # set block for output helpers
        @block = block
          
        indicate "Deploying App"
        
        # read procfile  
        host = GV::Valley::Runner.random_service
        procfile = host.run(app["name"], "cat /app/Procfile")
        procfile_types = YAML.load(procfile).keys
        
        stop app
          
        # add new Procfile process types or reset jobs array for existing types
        procfile_types.each do |type|
          unless app["ps"].keys.include? type
            app["ps"][type] = {"scale" => 1, "containers" => []}
          else
            app["ps"][type]["containers"] = []
          end
        end
        
        app.save
          
        # remove the old types
        app["ps"].keys.each do |type|
          unless procfile_types.include? type
            app["ps"].delete(type)
          end
        end
        
        app.save
        
        start app
          
        app.save
          
      end
      
      ##
      # stops all running procfile processes
      
      def stop app, &block
        # stop and remove all running procfile processes
        tuple = [:ps, /#{app['name']}\./, nil, nil ]
        while (self.class.space.read(tuple,0) rescue nil) do
          if host = (self.class.space.take(tuple,0)[2] rescue nil)
            host.remove app["name"]
          end
        end
      end
      
      ##
      # starts all procfile processes
            
      def start app, &block
        # run available process types
        app["ps"].each do |type,ps|
          ps["scale"].times do |index|
            host = GV::Valley::Runner.random_service                
            app["ps"][type]["containers"] << host.start(app["name"], type, index, &block)
          end
        end
      end
      
      private
      
      def indicate string
        say %(-----> #{string}), &@block
      end

      def say string
        pipe %(echo '\e[1G#{string}'), &@block      
      end 
        
        
    end 
      
  end
    
end