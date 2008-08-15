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
