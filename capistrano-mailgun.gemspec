# -*- encoding: utf-8 -*-
$:.unshift File.expand_path('../lib', __FILE__)
require 'capistrano-mailgun/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Spike Grobstein"]
  gem.email         = ["spike@ticketevolution.com"]
  gem.description   = %q{Send emails using the Mailgun API from your Capistrano recipes. Simple configuration using Capistrano variables along with direct access to the API.}
  gem.summary       = %q{Capistrano plugin for sending emails via the Mailgun API.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "capistrano-mailgun"
  gem.require_paths = ["lib"]
  gem.version       = Capistrano::Mailgun::VERSION

  gem.add_dependency "capnotify", '~> 0.2.0'
  gem.add_dependency "rest-client"

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'awesome_print'
end
