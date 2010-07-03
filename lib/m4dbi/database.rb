module M4DBI

  class Database < RDBI::Database

    def initialize( rdbi_dbh )
      @dbh = rdbi_dbh
      super
    end

    def execute( *args )
      @dbh.execute *args
    end

    def select( sql, *bindvars )
      execute( sql, *bindvars ).fetch( :all, RDBI::Result::Driver::Struct )
    end

    def select_one( sql, *bindvars )
      select( sql, *bindvars )[ 0 ]
    end

    def select_column( sql, *bindvars )
      rows = execute( sql, *bindvars ).fetch( 1, RDBI::Result::Driver::Array )
      if rows.any?
        rows[ 0 ][ 0 ]
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




