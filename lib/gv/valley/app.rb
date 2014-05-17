require 'gv/bedrock/config'
require 'gv/valley/etcd'
require 'gv/valley/file_server'
require 'gv/common/docker_helper'
require 'json'
require 'etcd'

module GV
  module Valley
    
    class App
      
      PORT = 5000
      
      class << self
        
        def etcd_clt
          @@etcd_clt ||= begin
            server = GV::Valley::Etcd.service  
            ::Etcd.client(config = {
              host: server.external_ip, 
              port: server.port
            })
          end
        end
        
        def all
          etcd_clt.get("/apps").children.map{ |node| find(File.basename(node.key)) }
        end
        
        def find name
          begin
            find! name
          rescue ::Etcd::KeyNotFound
            nil
          end
        end
        
        def find! name
          value = etcd_clt.get("/apps/#{name}").value
          new(ensure_defaults(JSON.load(value))) 
        end        
        
        def create name
          save name, {"name" => name, "config" => default_config(name), "ps" => {}, "domains" => [default_domain(name)]}
          find name
        end
        
        def save name, data
          etcd_clt.set("/apps/#{name}", { value: JSON.dump(ensure_defaults(data)) })
        end
        
        def delete name
          etcd_clt.delete("/apps/#{name}",{recursive: true}) rescue nil
        end
        
        def domain
          GV::Bedrock::Config.service.get("domain")
        end
        
        def default_config name
          config = {
            "SLUG_URL" => "#{GV::Valley::FileServer.service.url}/#{name}/slug.tgz",
            "PORT" => PORT,
            "RACK_ENV" => "production"
          }
        end
        
        def default_domain name
          "#{name}.#{self.domain}"
        end
        
        def ensure_defaults data
          data["config"] ||= {}
          data["config"].update(default_config(data["name"]))
          
          data["domains"] ||= []
          data["domains"] << default_domain(data["name"]) unless data["domains"].include? default_domain(data["name"])
          data
        end
        
      end
      
      def initialize attributes = {}
        @attributes = attributes
        @name = @attributes['name']
        @attributes = attributes
      end
      
      def save
        self.class.save(@name,@attributes)
      end
      
      def delete
        self.class.delete @name
      end
      
      def [](key)
        @attributes[key]
      end
      
      def []=(key,value)
        @attributes[key]=value
      end  
      
    end
    
  end
end