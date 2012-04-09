# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "brittany_ferries/version"

Gem::Specification.new do |s|
  s.name        = "brittany_ferries"
  s.version     = BrittanyFerries::VERSION
  s.authors     = ["James Mead"]
  s.email       = ["james@floehopper.org"]
  s.homepage    = ""
  s.summary     = %q{Programmatic ferry bookings}

  s.rubyforge_project = "brittany_ferries"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "mechanize"
  s.add_runtime_dependency "tidy_ffi"
  s.add_runtime_dependency "activesupport"
  s.add_runtime_dependency "tzinfo"
end
