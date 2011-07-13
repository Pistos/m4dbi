require_relative 'helper'

$dbh = connect_to_spec_database
reset_data

describe 'M4DBI.last_dbh' do
  it 'provides the last database handle connected to' do
    M4DBI.last_dbh.should.equal $dbh
  end
end

describe 'M4DBI::Database#select_column' do

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

    should.raise( RDBI::Error ) do
      $dbh.select_column( "SELECT name FROM authors WHERE 1+1 = 3" )
    end

    begin
      $dbh.select_column( "SELECT name FROM authors WHERE 1+1 = 3" )
    rescue RDBI::Error => e
      e.message.should.match /SELECT name FROM authors WHERE 1\+1 = 3/
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

describe 'row accessors' do

  it 'provide read access via #fieldname' do
    row = $dbh.select_one(
      "SELECT * FROM posts ORDER BY author_id DESC LIMIT 1"
    )
    row.should.not.equal nil

    row.author_id.should.be.same_as row[ 'author_id' ]
    row.text.should.be.same_as row[ 'text' ]

    row.text.should.equal 'Second post.'
  end

  it 'provide in-memory (non-syncing) write access via #fieldname=' do
    row = $dbh.select_one(
      "SELECT * FROM posts ORDER BY author_id DESC LIMIT 1"
    )
    row.should.not.equal nil

    old_id = row[ :id ]
    row[ :id ] = old_id + 1
    row[ :id ].should.not.equal old_id
    row[ :id ].should.equal( old_id + 1 )

    old_text = row.text
    new_text = 'This is the new post text.'
    row.text = new_text
    row.text.should.not.equal old_text
    row.text.should.equal new_text
  end

end