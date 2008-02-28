require 'dbi'
require 'thread'

module DBI
  class DatabaseHandle
    alias old_initialize initialize
    def initialize( handle )
      DBI::DatabaseHandle.last_handle = self
      old_initialize( handle )
      @mutex = Mutex.new
    end
    
    # Atomically disable autocommit, do transaction, and reenable.
    # Used for a single transaction when autocommit is normally left on.
    # Only one thread can execute one_transaction at a time,
    # since we need to thread protect the AutoCommit property of the
    # database handle.
    def one_transaction
      if @mutex_holder == Thread.current
        # No need to start another transaction.
        # This permits us to use one_transaction in recursive or
        # nested calls (otherwise we have thread deadlock waiting on
        # the mutex).
        # TODO: This stuff may be premature optimization.  We may take it out.
        yield self
      else
        t = Thread.new do
          @mutex.synchronize do
            @mutex_holder = Thread.current
            auto_commit = self[ 'AutoCommit' ]
            self[ 'AutoCommit' ] = false
            result = transaction do
              yield self
            end
            self[ 'AutoCommit' ] = auto_commit
            @mutex_holder = nil
            result
          end
        end
        t.value
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




