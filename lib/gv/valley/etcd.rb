require 'gv/bedrock/service'
require 'gv/bedrock/config'
require 'gv/common/docker_helper'
require 'gv/common/host_helper'

module GV
  module Valley
  
    ##
    # Etcd Service
    #
  
    class Etcd < GV::Bedrock::Service
      
      include GV::Common::HostHelper      
      include GV::Common::DockerHelper      
      
      PORT = 4001
      
      def initialize
        super
        
        pull_image_if_does_not_exists "flynn/etcd"
        
        home = GV::Bedrock::Config.service.get("home")
        
        unless ps? 'etcd'
          cleanup
          pipe "docker run --name etcd -d -p #{self.external_ip}::#{PORT} -v #{home}/etcd:/data/db:rw flynn/etcd --name=greenvalley -data-dir=/data/db"
        end
      end
      
      def port
        container_port 'etcd', self.external_ip, PORT
      end
      
    end
    
  end
end