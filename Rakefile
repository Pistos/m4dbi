require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'

$:.unshift File.join( File.dirname(__FILE__), "lib" )

# ------------------

task :default => ['spec']
task :test => ['spec']

desc "generate rdoc"
Rake::RDocTask.new do |rdoc|
  files = [ 'lib/**/*.rb', 'spec/**/*.rb', 'HIM', 'READHIM' ]
  rdoc.rdoc_files.add( files )
  rdoc.main = "HIM" # page to start on
  rdoc.title = "M4DBI - Models For DBI"
  rdoc.template = "/misc/pistos/unpack/allison-2.3/allison.rb"
  rdoc.rdoc_dir = '/var/www/localhost/htdocs/m4dbi/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers' << '--inline-source'
end

desc 'Run coverage examiner (rcov)'
task 'rcov' do
   exec( "rcov -o /var/www/localhost/htdocs/m4dbi/rcov spec/*.rb" )
end

desc 'Run all specs'
task 'spec' do
  root = File.expand_path( File.dirname(__FILE__) )
  exec "bacon #{root}/spec/*.rb"
end
