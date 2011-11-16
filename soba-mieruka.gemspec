# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "soba/mieruka/version"

Gem::Specification.new do |s|
  s.name        = "soba-mieruka"
  s.version     = Soba::Mieruka::VERSION
  s.authors     = ["Takuji Shimokawa"]
  s.email       = ["takuji.shimokawa@gmail.com"]
  s.homepage    = "http://web-api.soba-project.com"
  s.summary     = %q{SOBA mieruka Web API's client library}
  s.description = %q{This library is for developing web sites which publish command files to create new sessions or to join them for SOBA mieruka Client application.}
  s.rubyforge_project = "soba-mieruka"

  s.files         = `git ls-files`.split("\n").delete_if{|e| e =~ /^spec\//}
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
