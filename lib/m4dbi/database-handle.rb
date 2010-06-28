require 'dbi'
require 'thread'

module DBI

  class DatabaseHandle

    def select_column( statement, *bindvars )
      row = select_one( statement, *bindvars )
      if row
        row[ 0 ]
      else
        raise DBI::DataError.new( "Query returned no rows.  #{last_statement}" )
      end
    end

    alias s select_all
    alias s1 select_one
    alias sc select_column
    alias u do
    alias i do
    alias d do

  end
end




