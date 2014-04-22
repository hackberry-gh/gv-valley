require "gv/common/logging"
require "gv/valley/version"

module GV
  module Valley
    def self.root
      @@root ||= File.expand_path("../../../",__FILE__)
    end
  end
end
