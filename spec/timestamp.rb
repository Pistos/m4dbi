require 'spec/helper'

$dbh = DBI.connect( "DBI:Pg:m4dbi", "m4dbi", "m4dbi" )
# See test-schema.sql and test-data.sql

describe 'a DBI::Timestamp object' do
  before do
    @ts = $dbh.sc "SELECT ts FROM many_col_table WHERE ts IS NOT NULL LIMIT 1"
  end
  it 'acts like a Time object' do
    should.raise( NoMethodError ) do
      @ts.no_such_method_on_time_objects
    end
    should.not.raise( NoMethodError ) do
      @ts.strftime "%H:%M"
    end
  end
end