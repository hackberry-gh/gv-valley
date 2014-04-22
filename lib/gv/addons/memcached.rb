require 'gv/valley'
require 'gv/valley/addon'

module GV
  module Addons
    class Memcached < GV::Valley::Addon
  
      PORT = 4001
  
      CONTAINER_DIR="/data/db"    
  
      def image; "bacongobbler/memcached" end
  
  
      def url app_name
        @app_name = app_name
        self.class.space.read([@name.to_sym,@app_name,nil,nil],0) rescue nil
      end
  
      def create app_name
        super app_name
        self.class.space.write([@name.to_sym,@app_name,"#{self.external_ip}:#{port(app_name)}",self.external_ip])    
      end
  
      def destroy app_name
        super app_name
        tuple = [@name.to_sym,@app_name,nil,nil]
        (self.class.space.take(tuple,0) rescue nil) while (self.class.space.read(tuple,0) rescue nil)
      end


    end
  end
end