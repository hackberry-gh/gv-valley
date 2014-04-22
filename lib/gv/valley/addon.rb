require 'gv/bedrock/service'
require 'gv/bedrock/config'
require 'gv/common/docker_helper'
require 'gv/common/host_helper'

module GV
  module Valley
  
    ##
    # Addon Service
    #
  
    class Addon < GV::Bedrock::Service
      
      include GV::Common::HostHelper      
      include GV::Common::DockerHelper      
      
      PORT = nil
      
      attr_reader :image, :params, :cmd
      
      def initialize
        super
        
        pull_image_if_does_not_exists self.image
        
        @home = GV::Bedrock::Config.service.get("home")
        @name ||= File.basename(self.image) 
        
      end
      
      def create app_name
        @app_name = app_name
        addon_name = "#{@name}.#{app_name}"
        return nil if ps? addon_name
        pipe "docker run --name #{addon_name} -d -p #{self.external_ip}::#{self.class::PORT} -e PORT=#{self.class::PORT} #{self.params} #{self.image} #{self.cmd}"
      end
      
      def destroy app_name
        @app_name = app_name
        addon_name = "#{@name}.#{app_name}"
        batch addon_name, "stop", true
        batch addon_name, "rm", true        
      end
      
      def info app_name
        @app_name = app_name
        addon_name = "#{@name}.#{app_name}"
        info(container_id(addon_name))
      end
      
      def port app_name
        @app_name = app_name
        addon_name = "#{@name}.#{app_name}"
        container_port addon_name, self.external_ip, self.class::PORT
      end
      
      
    end
    
  end
end