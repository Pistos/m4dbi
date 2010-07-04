module M4DBI

  class Database

    def initialize( rdbi_dbh )
      @dbh = rdbi_dbh
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
        raise RDBI::Error.new( "Query returned no rows.  SQL: #{@dbh.last_query}" )
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

    def connected?
      @dbh.connected?
    end

    def disconnect
      @dbh.disconnect
    end

    def table_schema( *args )
      @dbh.table_schema( *args )
    end

    def database_name
      @dbh.database_name
    end

    def transaction( &block )
      @dbh.transaction &block
    end

    def last_query
      @dbh.last_query
    end

    def driver
      @dbh.driver
    end
  end
end




