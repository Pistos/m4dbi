require 'rubygems'
require 'bacon'

$LOAD_PATH.unshift(
  File.expand_path(
    File.join(
      File.dirname( __FILE__ ),
      "../lib"
    )
  )
)

require 'm4dbi'

puts "DBI version: #{DBI::VERSION}"
puts "M4DBI version: #{M4DBI_VERSION}"

# See test-schema*.sql and test-data.sql
def connect_to_spec_database( database = ( ENV[ 'M4DBI_DATABASE' ] || 'm4dbi' ) )
  driver = ENV[ 'M4DBI_DRIVER' ] || "DBI:Pg"
  puts "Using DBI driver: '#{driver}'"
  DBI.connect( "#{driver}:#{database}", "m4dbi", "m4dbi" )
end

def reset_data( dbh = $dbh, datafile = "test-data.sql" )
  dir = File.dirname( __FILE__ )
  File.read( "#{dir}/#{datafile}" ).split( /;/ ).each do |command|
    if not command.strip.empty?
      dbh.do command
    end
  end
end
