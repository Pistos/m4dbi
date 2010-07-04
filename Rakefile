require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'

$:.unshift File.join( File.dirname(__FILE__), "lib" )

root = File.expand_path( File.dirname(__FILE__) )

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
   exec( "rcov -o /var/www/localhost/htdocs/m4dbi/rcov -x '.gems' spec/*.rb" )
end

desc 'Run all specs'
task 'spec' do
  exec "bacon #{root}/spec/*.rb"
end

desc 'Run all specs against repo version of DBI'
task 'spec-dev' do
  exec "bacon -I/misc/git/rdbi/lib -I/misc/git/rdbi-driver-postgresql/lib -I/misc/git/rdbi-driver-sqlite3/lib #{root}/spec/*.rb"
end

desc 'Build nightly gem'
task 'nightly' do
  output = `gem build #{root}/gemspecs/m4dbi-nightly.gemspec`
  version = Time.now.strftime( "%Y.%m.%d" )
  `mv m4dbi-#{version}.gem m4dbi-nightly.gem`
end

desc 'Make release'
task 'release' do
  output = `gem build #{root}/gemspecs/m4dbi.gemspec`
end

desc 'Build examples from specs'
task 'examples' do
  Dir[ 'spec/*.rb' ].each do |specfile|
    next if specfile =~ /helper\.rb/
    base = File.basename( specfile, ".rb" )
    `ruby -I /misc/svn/specs2examples/lib /misc/svn/specs2examples/bin/specs2examples #{specfile} > /var/www/localhost/htdocs/m4dbi/examples/#{base}.html`
  end
end