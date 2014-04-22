require 'gv/bedrock/service'
require 'gv/valley/app'
require 'gv/common/pipe_helper'

module GV
  module Valley
    
    class Balancer < GV::Bedrock::Service
      
      include GV::Common::PipeHelper
      INDENT = "        "      
      
      ##
      # reloads haproxy config
      
      def reload &block
        
        @block = block
        
        indicate "Loading Haproxy config"
        
        config = File.read("#{GV::Valley.root}/scripts/haproxy.cfg")
        target_file = "/etc/haproxy/haproxy.cfg"
        acl = ""
        backend = ""
        
        App.all.each do |app|
          
          app["domains"].each do |domain|
            acl << "#{INDENT}use_backend b_#{app["name"]} if { hdr(host) -i #{domain} }\n"
          end
          
          backend << "backend b_#{app["name"]}\n"
          app["ps"]["web"]["containers"].each do |container|
            host = container['HostConfig']['PortBindings']["#{App::PORT}/tcp"].first
            backend << "#{INDENT}server srv_#{container['ID'][0..6]} #{host['HostIp']}:#{host['HostPort']}\n"
          end
          
        end
        
        config.gsub!(/^\#FRONT$/,acl) 
        config.gsub!(/^\#BACK$/,backend) 
        
        pipe "rm #{target_file}"
        File.open(target_file,File::RDWR|File::CREAT){|f| f.puts config }
    
        pipe "chmod 0770 #{target_file}"
        pipe "chgrp haproxy #{target_file}"
        pipe "service haproxy reload", &block
        
      end
      
      private
        
      
        
    end 
      
  end
    
end