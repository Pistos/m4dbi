require 'dbi'

module DBI
  class DatabaseHandle
    alias old_initialize initialize
    def initialize( handle )
      DBI::DatabaseHandle.last_handle = self
      old_initialize( handle )
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




