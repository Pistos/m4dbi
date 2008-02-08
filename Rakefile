require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'time'
require 'pp'

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

# Stolen from Ramaze  http://ramaze.net
desc 'Run all specs'
task 'spec' do
  non_verbose, non_fatal = ENV['non_verbose'], ENV['non_fatal']
  require 'scanf'

  root = File.expand_path( File.dirname(__FILE__) )
  libpath = root + '/lib'

  specs = Dir[ root + '/spec/**/*.rb' ]

  config = RbConfig::CONFIG
  bin = config['bindir'] + '/' + config['ruby_install_name']

  result_format = '%d tests, %d assertions, %d failures, %d errors'

  list = specs.sort
  names = list.map{|l| l.sub(root + '/', '') }
  width = names.sort_by{|s| s.size}.last.size
  total = names.size

  list.zip(names).each_with_index do |(spec, name), idx|
    print '%2d/%d: ' % [idx + 1, total]
    print name.ljust(width + 2)

    stdout = `#{bin} -I#{libpath} #{spec} 2>&1`

    status = $?.exitstatus
    tests, assertions, failures, errors =
      stdout[/.*\Z/].to_s.scanf(result_format)

    if stdout =~ /Usually you should not worry about this failure, just install the/
      lib = stdout[/^no such file to load -- (.*?)$/, 1] ||
            stdout[/RubyGem version error: (.*)$/, 1]
      puts "requires #{lib}"
    elsif status == 0
      puts "all %3d passed" % tests
    else
      out = result_format % [tests, assertions, failures, errors].map{|e| e.to_s.to_i}
      puts out
      puts stdout unless non_verbose
      exit status unless non_fatal
    end
  end

  puts "All specs pass!"
end
