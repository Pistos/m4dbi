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
  
  class DatabaseHandle
    alias old_initialize initialize
    def initialize( handle )
      DBI::DatabaseHandle.last_handle = self
      handle = old_initialize( handle )
      @mutex = Mutex.new
      
      # Hackery to expose dbname.
      case @handle
        when DBI::DBD::Pg::Database
          @handle.extend DBI::DBD::Pg::ConnectionDatabaseNameAccessor
          extend DBI::DBD::Pg::DatabaseNameAccessor
        # TODO: more DBDs
      end
      
      handle
    end
    
    # Atomically disable autocommit, do transaction, and reenable.
    # Used for a single transaction when autocommit is normally left on.
    # Only one thread can execute one_transaction at a time,
    # since we need to thread protect the AutoCommit property of the
    # database handle.
    def one_transaction
      @mutex.synchronize do
        auto_commit = self[ 'AutoCommit' ]
        self[ 'AutoCommit' ] = false
        result = transaction do
          yield self
        end
        self[ 'AutoCommit' ] = auto_commit
        result
      end
    end
    
    def select_column( statement, *bindvars )
      row = select_one( statement, *bindvars )
      if row
        row[ 0 ]
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




