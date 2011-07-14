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

puts "M4DBI version: #{M4DBI_VERSION}"

# See test-schema*.sql and test-data.sql
def connect_to_spec_database( database = ( ENV[ 'M4DBI_DATABASE' ] || 'm4dbi' ) )
  driver = ENV[ 'M4DBI_DRIVER' ] || "PostgreSQL"
  # puts "\nUsing RDBI driver: '#{driver}'"
  case driver.downcase
  when 'postgresql', 'sqlite3', 'mysql'
    require "rdbi/driver/#{driver.downcase}"
  else
    raise "Unrecognized RDBI driver: #{driver}"
  end

  M4DBI.connect(
    driver,
    :database => database,
    :username => 'm4dbi',
    :hostname => 'localhost',
    :password => 'm4dbi'
  )
end

def reset_data( dbh = $dbh, datafile = "test-data.sql" )
  dir = File.dirname( __FILE__ )
  File.read( "#{dir}/#{datafile}" ).split( /;/ ).each do |command|
    if ! command.strip.empty?
      dbh.execute command
    end
  end
end
