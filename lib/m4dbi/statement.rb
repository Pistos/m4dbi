module M4DBI
  class Statement
    def initialize( rdbi_statement )
      @st = rdbi_statement
    end

    def execute( *args )
      @st.execute *args
    end

    def select( *bindvars )
      @st.execute( *bindvars ).fetch( :all, RDBI::Result::Driver::Struct )
    end

    def select_one( *bindvars )
      select( *bindvars )[0]
    end

    def select_column( *bindvars )
      rows = @st.execute( *bindvars ).fetch( 1, RDBI::Result::Driver::Array )
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
