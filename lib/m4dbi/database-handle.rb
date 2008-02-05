require 'dbi'

module DBI
  class DatabaseHandle
    def select_column( statement, *bindvars )
      row = select_one( statement, *bindvars )
      if row
        row[ 0 ]
      end
    end
  end
end
