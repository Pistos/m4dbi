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
      self.new(
        @dbh.select_one(
          "SELECT * FROM #{@table} WHERE #{@pk} = ?",
          pk_value
        )
      )
    end
    
    def self.where( conditions, *args )
      case conditions
        when String
          sql = "SELECT * FROM #{@table} WHERE #{conditions}"
          params = args
        when Hash
          cond = conditions.keys.map { |field|
            "#{field} = ?"
          }.join( " AND " )
          sql = "SELECT * FROM #{@table} WHERE #{cond}"
          params = conditions.values
      end
      
      @dbh.select_all(
        sql,
        *params
      ).map { |r| self.new( r ) }
    end
    
    def initialize( row )
      @row = row
    end
    
    def method_missing( method, *args )
      @row.send( method, *args )
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