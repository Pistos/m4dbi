require 'thread'

module M4DBI

  class Database

    def initialize( rdbi_dbh )
      @dbh = rdbi_dbh
      @mutex = Mutex.new
    end

    def synchronize
      @mutex.synchronize do
        yield
      end
    end

    def prepare( *args )
      self.synchronize do
        Statement.new( @dbh.prepare(*args), self )
      end
    end

    def execute( *args )
      result = nil
      self.synchronize do
        result = @dbh.execute(*args)
      end
      if defined?( RDBI::Driver::PostgreSQL ) && RDBI::Driver::PostgreSQL === @dbh.driver
        result.finish
      end
      result
    end

    def select( sql, *bindvars )
      result = nil
      rows = nil
      self.synchronize do
        result = @dbh.execute( sql, *bindvars )
        rows = result.fetch( :all, RDBI::Result::Driver::Struct )
      end
      if defined?( RDBI::Driver::PostgreSQL ) && RDBI::Driver::PostgreSQL === @dbh.driver
        result.finish
      end
      rows
    end

    def select_one( sql, *bindvars )
      select( sql, *bindvars )[0]
    end

    def select_column( sql, *bindvars )
      result = nil
      rows = nil
      self.synchronize do
        result = @dbh.execute( sql, *bindvars )
        rows = result.fetch( 1, RDBI::Result::Driver::Array )
      end
      if defined?( RDBI::Driver::PostgreSQL ) && RDBI::Driver::PostgreSQL === @dbh.driver
        result.finish
      end
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
