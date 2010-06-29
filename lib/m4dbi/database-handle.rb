module M4DBI

  class Database < RDBI::Database

    def initialize( rdbi_dbh )
      @dbh = rdbi_dbh
    end

    def execute( *args )
      @dbh.execute *args
    end

    def select( sql, *bindvars )
      execute( sql, *bindvars ).fetch( :all )
    end

    def select_one( sql, *bindvars )
      select( sql, *bindvars )[ 0 ]
    end

    def select_column( statement, *bindvars )
      row = select_one( statement, *bindvars )
      if row
        row[ 0 ]
      else
        raise RDBI::Error.new( "Query returned no rows.  SQL: #{last_query}" )
      end
    end

    alias select_all select
    alias s select
    alias s1 select_one
    alias sc select_column
    alias update execute
    alias u execute
    alias insert execute
    alias i execute
    alias delete execute
    alias d execute

  end
end




