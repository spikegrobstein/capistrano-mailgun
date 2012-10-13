require 'rubygems'
require 'bundler/setup'

require 'awesome_print'

$: << File.dirname(__FILE__) + '/../lib'

require 'capistrano'
require 'capistrano-mailgun'

Rspec.configure do |config|
  # config
end

