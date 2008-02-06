require 'dbi'

module DBI
  class DatabaseHandle
    alias old_initialize initialize
    def initialize( handle )
      DBI::DatabaseHandle.last_handle = handle
      old_initialize( handle )
    end
    
    def select_column( statement, *bindvars )
      row = select_one( statement, *bindvars )
      if row
        row[ 0 ]
      end
    end
    
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




