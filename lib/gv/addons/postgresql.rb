require 'gv/valley'
require 'gv/valley/addon'

module GV
  module Addons
    class Postgresql < GV::Valley::Addon
  
      PORT = 5432
  
      CONTAINER_DIR="/var/lib/postgresql/9.3/main"    
  
      def image; "valley/postgresql" end
  
      def params 
        ["-v #{@home}/#{@name}/#{@app_name}:#{CONTAINER_DIR} -w #{CONTAINER_DIR}",
          "-e POSTGRESQL_USER=#{@app_name}", 
          "-e POSTGRESQL_PASS=#{@pass=rand(2**64).to_s(36)}", 
          "-e POSTGRESQL_DB=#{@app_name}"
        ].join(" ")
      end
  
      def url app_name
        @app_name = app_name
        self.class.space.read([@name.to_sym,@app_name,nil,nil],0)[2] rescue nil
      end
  
      def create app_name
        if super(app_name)
          self.class.space.write([@name.to_sym,@app_name,"postgres://#{@app_name}:#{@pass}@#{self.external_ip}:#{port(app_name)}/#{@app_name}",self.external_ip])    
        end
      end
  
      def destroy app_name
        super app_name
        tuple = [@name.to_sym,@app_name,nil,nil]
        (self.class.space.take(tuple,0) rescue nil) while (self.class.space.read(tuple,0) rescue nil)
      end


    end
  end
end