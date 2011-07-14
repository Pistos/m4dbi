require 'rubygems'
require 'rake'
require 'rake/clean'

$:.unshift File.join( File.dirname(__FILE__), "lib" )

root = File.expand_path( File.dirname(__FILE__) )

# ------------------

task :default => ['spec']
task :test => ['spec']

desc 'Run all specs'
task 'spec' do
  exec "bacon #{root}/spec/*.rb"
end
