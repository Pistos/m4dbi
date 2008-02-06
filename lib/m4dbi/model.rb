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
      ancestral_trait[ :dbh ].select_one(
        "SELECT * FROM #{ancestral_trait[ :table ]} WHERE #{pk} = ?",
        pk_value
      )
    end
    
    def self.pk
      @pk || 'id'
    end
    def self.pk=( col )
      @pk = col
    end
    
    def self.table=( t )
      @table = t
    end
    
  end
  
  def self.Model( table, pk = 'id' )
    c = Class.new( DBI::Model )
    
    h = DBI::DatabaseHandle.last_handle
    if h.nil?
      raise DBI::Error.new( "Attempted to create a Model class without first connecting to a database." )
    end
    
    c.trait[ :dbh ] = h
    c.trait[ :table ] = table
    c.pk = pk
    c
  end
  
end