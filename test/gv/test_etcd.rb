require 'minitest_helper'
require 'gv/bedrock/config'
require 'gv/valley/etcd'

module GV
  module Valley
    class TestEtcd < Minitest::Test
      
      def setup
        start_server
      end
      
      def stop
        stop_server
      end
      
      def test_discovery
        pid = provide GV::Bedrock::Config
        pid2 = provide GV::Valley::Etcd
        
        DRb.start_service
        
        refute_nil GV::Valley::Etcd.service
        
        # clear all services
        GV::Bedrock::Service.space.read_all([nil,nil,nil,nil]).each do |t|
          GV::Bedrock::Service.space.take(t)
        end
        
        DRb.stop_service
        
        kll pid2        
        kll pid
        
      end
      
    end
  end
end