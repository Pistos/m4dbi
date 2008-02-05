require 'spec/helper'

$dbh = DBI.connect( "DBI:Pg:m4dbi", "m4dbi", "m4dbi" )
# See test-schema.sql and test-data.sql

describe 'select_column' do
  
  it 'should select one column' do
    name = $dbh.select_column(
      "SELECT name FROM authors LIMIT 1"
    )
    name.should.equal 'author1'
  end
  
  it 'should select one column of first row' do
    name = $dbh.select_column(
      "SELECT name FROM authors ORDER BY name DESC"
    )
    name.should.equal 'author2'
  end
  
  it 'should select first column of first row' do
    name = $dbh.select_column(
      "SELECT name, id FROM authors ORDER BY name DESC"
    )
    name.should.equal 'author2'
  end
  
end

describe 'accessors' do
  
  it 'should provide access via ".fieldname" syntax' do
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
  
end