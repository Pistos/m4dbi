require 'spec/helper'

$dbh = DBI.connect( "DBI:Pg:m4dbi", "m4dbi", "m4dbi" )
# See test-schema.sql and test-data.sql

describe 'DBI::DatabaseHandle#select_column' do
  
  it 'selects one column' do
    name = $dbh.select_column(
      "SELECT name FROM authors LIMIT 1"
    )
    name.class.should.not.equal Array
    name.should.equal 'author1'
    
    null = $dbh.select_column(
      "SELECT c4 FROM many_col_table WHERE c3 = 40"
    )
    null.should.be.nil
    
    should.raise( DBI::DataError ) do
      $dbh.select_column( "SELECT name FROM authors WHERE FALSE" )
    end
  end
  
  it 'selects one column of first row' do
    name = $dbh.select_column(
      "SELECT name FROM authors ORDER BY name DESC"
    )
    name.should.equal 'author3'
  end
  
  it 'selects first column of first row' do
    name = $dbh.select_column(
      "SELECT name, id FROM authors ORDER BY name DESC"
    )
    name.should.equal 'author3'
  end
end

describe 'DBI::DatabaseHandle#one_transaction' do
  
  it 'turns off autocommit for the duration of a single transaction' do
    $dbh.d( "DELETE FROM many_col_table;" )
    $dbh.i( "INSERT INTO many_col_table ( id, c1 ) VALUES ( 1, 10 );" )
    
    # Here we will attempt to increment a value two times in parallel.
    # If each multi-operation transaction is truly atomic, we expect that
    # the final value will reflect two increments.
    # If atomicity is not respected, the value should only reflect one
    # increment.
    
    # First, we test the non-transactional case, to show failure.
    
    thread1 = Thread.new do
      value = $dbh.sc "SELECT c1 FROM many_col_table WHERE id = 1;"
      value.should.equal 10
      sleep 2 # seconds
      $dbh.u "UPDATE many_col_table SET c1 = ?", ( value + 1 )
    end
    
    thread2 = Thread.new do
      value = $dbh.sc "SELECT c1 FROM many_col_table WHERE id = 1;"
      value.should.equal 10
      # Update right away
      $dbh.u "UPDATE many_col_table SET c1 = ?", ( value + 1 )
    end
    
    thread2.join
    thread1.join
    
    value = $dbh.sc "SELECT c1 FROM many_col_table WHERE id = 1;"
    # Failure; two increments should give a final value of 12.
    value.should.equal( 10 + 1 )
    
    # Now, we show that transactions keep things sane.
    
    thread1 = Thread.new do
      $dbh.one_transaction do |dbh|
        value = dbh.sc "SELECT c1 FROM many_col_table WHERE id = 1;"
        sleep 2 # seconds
        dbh.u "UPDATE many_col_table SET c1 = ?", ( value + 1 )
      end
    end
    
    thread2 = Thread.new do
      $dbh.one_transaction do |dbh|
        value = dbh.sc "SELECT c1 FROM many_col_table WHERE id = 1;"
        # Update right away
        dbh.u "UPDATE many_col_table SET c1 = ?", ( value + 1 )
      end
    end
    
    thread2.join
    thread1.join
    
    value = $dbh.sc "SELECT c1 FROM many_col_table WHERE id = 1;"
    value.should.equal( 11 + 1 + 1 )
  end
  
end

describe 'DBI::Row accessors' do
  
  it 'provide read access via #fieldname' do
    row = $dbh.select_one(
      "SELECT * FROM posts ORDER BY author_id DESC LIMIT 1"
    )
    row.should.not.equal nil
    
    row._id.should.be.same_as row[ 'id' ]
    row.id_.should.be.same_as row[ 'id' ]
    row.author_id.should.be.same_as row[ 'author_id' ]
    row.text.should.be.same_as row[ 'text' ]
    
    row.text.should.equal 'Second post.'
  end
  
  it 'provide in-memory (non-syncing) write access via #fieldname=' do
    row = $dbh.select_one(
      "SELECT * FROM posts ORDER BY author_id DESC LIMIT 1"
    )
    row.should.not.equal nil
    
    old_id = row._id
    row.id = old_id + 1
    row._id.should.not.equal old_id
    row._id.should.equal( old_id + 1 )
    
    old_text = row.text
    new_text = 'This is the new post text.'
    row.text = new_text
    row.text.should.not.equal old_text
    row.text.should.equal new_text
  end
  
end