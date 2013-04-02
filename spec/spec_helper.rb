require 'rubygems'
require 'bundler/setup'

require 'awesome_print'

$: << File.dirname(__FILE__) + '/../lib'

require 'capistrano'
require 'capistrano-mailgun'
require 'pry'

def fixture_path(filename)
  File.join( File.dirname(__FILE__), 'fixtures', filename )
end

