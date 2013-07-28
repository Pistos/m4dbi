require 'rdbi/driver/postgresql'
require 'm4dbi'

dbh = M4DBI.connect(
  :PostgreSQL,
  :database => 'm4dbi',
  :username => 'm4dbi',
  :hostname => 'localhost',
  :password => 'm4dbi'
)

threads = []
threads << Thread.new {
  puts "Thread 1 start"
  # Moderately long-running query
  dbh.execute "SELECT COUNT(*) FROM has_many_rows h1, has_many_rows h2;"
  puts "Thread 1 end"
}
threads << Thread.new {
  puts "Thread 2 start"
  # Moderately long-running query
  dbh.execute "SELECT COUNT(*) FROM has_many_rows h1, has_many_rows h2;"
  puts "Thread 2 end"
}

threads.each { |thr| thr.join }
