require 'dbi'
require 'metaid'

module DBI
  class Model
    def self.dbh
      from = self
      while !(d = from.instance_variable_get("@dbh")) && from != Object
        from = from.superclass
      end
      d
    end
    
    def self.[]( pk_value )
      dbh.select_one( "SELECT * FROM #{@table} WHERE #{@pk} = ?", pk_value )
    end
    
    def self.pk=( col )
      @pk = col
    end
    def self.table=( t )
      @table = t
    end
    
  end
  
  def self.Model( table )
    c = Class.new( DBI::Model )
    h = c.instance_variable_set( '@dbh', DBI::DatabaseHandle.last_handle )
    if h.nil?
      raise DBI::Error.new( "Attempted to create a Model class without first connecting to a database." )
    end
    c
  end
  
end