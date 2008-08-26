require 'spec/helper'

$dbh = connect_to_spec_database

describe 'a DBI::Timestamp object' do
  before do
    @ts = $dbh.sc "SELECT ts FROM many_col_table WHERE ts IS NOT NULL LIMIT 1"
  end
  it 'acts like a Time object' do
    # Only test this if the resultant column is actually a timestamp as returned by the DBD.
    # Not all DBDs can return timestamp columns.
    if @ts.class == DBI::Timestamp
      should.raise( NoMethodError ) do
        @ts.no_such_method_on_time_objects
      end
      should.not.raise( NoMethodError ) do
        @ts.strftime "%H:%M"
      end
    end
  end
end