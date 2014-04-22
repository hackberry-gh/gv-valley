require 'minitest_helper'
require 'gv/valley/etcd'
require 'gv/valley/app'

module GV
  module Valley
    class TestApp < Minitest::Test
      
      def setup
        start_server
      end
  
      def teardown
        stop_server
      end
  
      def test_app_methods
        pid = provide GV::Bedrock::Config
        pid2 = provide GV::Valley::Etcd
        pid3 = provide GV::Valley::FileServer        
        
        DRb.start_service
    
        name = "testapp"
        
        App.delete(name)
        
        app = App.create(name)
        refute_nil app
        
        app = App.find(name)
        refute_nil app
        
        saved = app.save
        refute_nil saved
        
        empty_hash = {}
        assert_equal name, app['name']
        assert_equal ["SLUG_URL","PORT"], app['config'].keys
        assert_equal empty_hash, app['ps']
        assert_equal ["#{name}.greenvalley.local"], app['domains']
        
        refute_nil app.delete
        
        assert_nil App.find(name)
        
        # clear all services
        GV::Bedrock::Service.space.read_all([nil,nil,nil,nil]).each do |t|
          GV::Bedrock::Service.space.take(t)
        end
        
        DRb.stop_service


        kll pid3
        kll pid2      
        kll pid                
    
      end
      
      
    end
  end
end