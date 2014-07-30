# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-mysql/version"

Gem::Specification.new do |s|
  s.name        = 'knife-mysql'
  s.version     = Knife::Mysql::VERSION
  s.authors     = ['Logan Koester']
  s.email       = ['logan@logankoester.com']
  s.homepage    = 'http://github.com/logankoester/knife-mysql'
  s.summary     = %q{Knife plugin to interact with MySQL on your nodes}
  s.description = %q{`knife-mysql` contains a utilities working with your database nodes, such as copying databases from one node or environment to another.}

  s.rubyforge_project = 'knife-mysql'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_runtime_dependency 'chef'
  s.add_runtime_dependency 'net-scp'
  s.add_runtime_dependency 'ruby-progressbar'
end
