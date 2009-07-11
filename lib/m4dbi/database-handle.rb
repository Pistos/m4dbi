require 'dbi'
require 'thread'

module DBI

  class DatabaseHandle
    attr_reader :transactions

    alias old_initialize initialize
    def initialize( *args )
      @mutex = Mutex.new
      @transactions = Array.new
      old_initialize( *args )
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

  end
end




