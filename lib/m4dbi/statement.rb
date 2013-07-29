require 'thread'

module M4DBI
  class Statement
    def initialize( rdbi_statement )
      @st = rdbi_statement
      @mutex = Mutex.new
    end

    def execute( *args )
      @mutex.synchronize do
        @st.execute *args
      end
    end

    def finish
      @st.finish
    end

    def select( *bindvars )
      @mutex.synchronize do
        @st.execute( *bindvars ).fetch( :all, RDBI::Result::Driver::Struct )
      end
    end

    def select_one( *bindvars )
      select( *bindvars )[0]
    end

    def select_column( *bindvars )
      rows = nil
      @mutex.synchronize do
        rows = @st.execute( *bindvars ).fetch( 1, RDBI::Result::Driver::Array )
      end
      if rows.any?
        rows[0][0]
      else
        raise RDBI::Error.new( "Query returned no rows." )
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
