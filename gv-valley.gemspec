# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gv/valley/version'

Gem::Specification.new do |spec|
  spec.name          = "gv-valley"
  spec.version       = GV::Valley::VERSION
  spec.authors       = ["Onur Uyar"]
  spec.email         = ["me@onuruyar.com"]
  spec.summary       = %q{Micro Private PaaS with Ruby}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_dependency 'goliath'
  spec.add_dependency 'etcd'      
  spec.add_dependency 'gv-common'    
  spec.add_dependency 'gv-bedrock'    
end
