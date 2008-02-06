require 'dbi'
require 'metaid'

module DBI
  class Model
    def self.dbh=( handle )
      @dbh = handle
    end
    def self.pk=( col )
      @pk = col
    end
    def self.table=( t )
      @table = t
    end
    
    def self.[]( pk_value )
      @dbh.select_one(
        "SELECT * FROM #{@table} WHERE #{@pk} = ?",
        pk_value
      )
    end
    
    def self.where( conditions, *args )
      case conditions
        when String
          @dbh.select_all(
            "SELECT * FROM #{@table} WHERE #{conditions}",
            *args
          )
        when Hash
          cond = conditions.keys.map { |field|
            "#{field} = ?"
          }.join( " AND " )
          @dbh.select_all(
            "SELECT * FROM #{@table} WHERE #{cond}",
            *( conditions.values )
          )
      end
    end
  end
  
  def self.Model( table, pk = 'id' )
    Class.new( DBI::Model ) do
      h = DBI::DatabaseHandle.last_handle
      if h.nil?
        raise DBI::Error.new( "Attempted to create a Model class without first connecting to a database." )
      end
      
      meta_def( :inherited ) do |c|
        c.dbh = h
        c.table = table
        c.pk = pk
      end
    end
  end
  
end