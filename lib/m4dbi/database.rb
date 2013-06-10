module M4DBI

  class Database

    def initialize( rdbi_dbh )
      @dbh = rdbi_dbh
    end

    def prepare( *args )
      Statement.new( @dbh.prepare(*args) )
    end

    def execute( *args )
      result = @dbh.execute(*args)
      result.finish
      result
    end

    def select( sql, *bindvars )
      result = @dbh.execute( sql, *bindvars )
      rows = result.fetch( :all, RDBI::Result::Driver::Struct )
      result.finish
      rows
    end

    def select_one( sql, *bindvars )
      select( sql, *bindvars )[0]
    end

    def select_column( sql, *bindvars )
      result = @dbh.execute( sql, *bindvars )
      rows = result.fetch( 1, RDBI::Result::Driver::Array )
      result.finish
      if rows.any?
        rows[0][0]
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
