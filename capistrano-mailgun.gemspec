# -*- encoding: utf-8 -*-
require File.expand_path('../lib/capistrano-mailgun/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Spike Grobstein"]
  gem.email         = ["spike@ticketevolution.com"]
  gem.description   = %q{Notify of deploys and other actions using mailgun}
  gem.summary       = %q{Notify of deploys and other actions using mailgun}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "capistrano-mailgun"
  gem.require_paths = ["lib"]
  gem.version       = Capistrano::Mailgun::VERSION

  gem.add_dependency "capistrano"
  gem.add_dependency "rest-client"
end
