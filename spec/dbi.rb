require 'spec/helper'

$dbh = DBI.connect( "DBI:Pg:m4dbi", "m4dbi", "m4dbi" )
# See test-schema.sql and test-data.sql

describe 'select_column' do
  
  it 'should select one column' do
    name = $dbh.select_column(
      "SELECT name FROM authors LIMIT 1"
    )
    name.class.should.not.equal Array
    name.should.equal 'author1'
  end
  
  it 'should select one column of first row' do
    name = $dbh.select_column(
      "SELECT name FROM authors ORDER BY name DESC"
    )
    name.should.equal 'author3'
  end
  
  it 'should select first column of first row' do
    name = $dbh.select_column(
      "SELECT name, id FROM authors ORDER BY name DESC"
    )
    name.should.equal 'author3'
  end
  
end

describe 'accessors' do
  
  it 'should provide read access via #fieldname' do
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
  
  it 'should provide in-memory (non-syncing) write access via #fieldname=' do
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