require 'rdbi/driver/postgresql'
require 'm4dbi'

$dbh = M4DBI.connect(
  :PostgreSQL,
  :database => 'm4dbi',
  :username => 'm4dbi',
  :hostname => 'localhost',
  :password => 'm4dbi'
)

def test_code(&block)
  threads = []
  threads << Thread.new {
    puts "Thread 1 start"
    block.call
    puts "Thread 1 end"
  }
  threads << Thread.new {
    puts "Thread 2 start"
    block.call
    puts "Thread 2 end"
  }

  threads.each { |thr| thr.join }
end

test_code do
  # Moderately long-running query
  $dbh.execute "SELECT COUNT(*) FROM has_many_rows h1, has_many_rows h2;"
end

test_code do
  $dbh.select "SELECT COUNT(*) FROM has_many_rows h1, has_many_rows h2"
end

test_code do
  $dbh.select_column "SELECT COUNT(*) FROM has_many_rows h1, has_many_rows h2"
end

test_code do
  stm = $dbh.prepare "SELECT COUNT(*) FROM has_many_rows h1, has_many_rows h2"
  row = stm.select_one
  stm.finish
end
