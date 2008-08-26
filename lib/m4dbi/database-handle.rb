require 'dbi'
require 'thread'

module DBI
  
  # Here, we engage in some hackery to get database handles to provide us
  # with the name of the database connected to.  For mystical reasons, this
  # is hidden in normal DBI.
  # Retrieve the database name with DatabaseHandle#dbname.
  module DBD; module Pg
    module ConnectionDatabaseNameAccessor
      def dbname
        @connection.db
      end
    end
    module DatabaseNameAccessor
      def dbname
        @handle.dbname
      end
    end
  end; end
  
  module DBD; module Mysql
    module DatabaseNameAccessor
      def dbname
        select_column( "SELECT DATABASE()" )
      end
    end
  end; end
  
  module DBD; module SQLite3
    module DatabaseNameAccessor
      def dbname
        select_one( "PRAGMA database_list" )[ 2 ]
      end
    end
  end; end
  
  class DatabaseHandle
    attr_reader :transactions
    
    alias old_initialize initialize
    def initialize( *args )
      DBI::DatabaseHandle.last_handle = self
      handle = old_initialize( *args )
      @mutex = Mutex.new
      @transactions = Array.new
      
      # Hackery to expose dbname.
      if defined?( DBI::DBD::Pg::Database ) and ( DBI::DBD::Pg::Database === @handle )
        @handle.extend DBI::DBD::Pg::ConnectionDatabaseNameAccessor
        extend DBI::DBD::Pg::DatabaseNameAccessor
      elsif defined?( DBI::DBD::Mysql::Database ) and ( DBI::DBD::Mysql::Database === @handle )
        extend DBI::DBD::Mysql::DatabaseNameAccessor
      elsif defined?( DBI::DBD::SQLite3::Database ) and ( DBI::DBD::SQLite3::Database === @handle )
        extend DBI::DBD::SQLite3::DatabaseNameAccessor
      end
      # TODO: more DBDs
      
      handle
    end
    
    # Atomically disable autocommit, do transaction, and reenable.
    # Used for a single transaction when autocommit is normally left on.
    # Only one thread can execute one_transaction at a time,
    # since we need to thread protect the AutoCommit property of the
    # database handle.
    def one_transaction
      @mutex.synchronize do
        # Keep track of transactions for debugging purposes
        transaction = { :time => ::Time.now, :stack => caller }
        @transactions << transaction
        
        auto_commit = self[ 'AutoCommit' ]
        self[ 'AutoCommit' ] = false
        result = transaction do
          yield self
        end
        self[ 'AutoCommit' ] = auto_commit
        
        @transactions.delete transaction
        result
      end
    end
    
    def select_column( statement, *bindvars )
      row = select_one( statement, *bindvars )
      if row
        row[ 0 ]
      else
        raise DBI::DataError.new( "Query returned no rows." )
      end
    end
    
    alias s select_all
    alias s1 select_one
    alias sc select_column
    alias u do
    alias i do
    alias d do
    
    class << self
      def last_handle
        @handle# ||= create_handle
      end
      
      def last_handle=( handle )
        @handle = handle
      end
    end
    
  end
end




