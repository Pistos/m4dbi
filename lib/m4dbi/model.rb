require 'dbi'
require 'metaid'

module DBI
  class Model
    ancestral_trait_reader :dbh, :table, :pk
    ancestral_trait_class_reader :dbh, :table, :pk
    
    def self.[]( pk_value )
      self.new(
        dbh.select_one(
          "SELECT * FROM #{table} WHERE #{pk} = ?",
          pk_value
        )
      )
    end
    
    def self.where( conditions, *args )
      case conditions
        when String
          sql = "SELECT * FROM #{table} WHERE #{conditions}"
          params = args
        when Hash
          cond = conditions.keys.map { |field|
            "#{field} = ?"
          }.join( " AND " )
          sql = "SELECT * FROM #{table} WHERE #{cond}"
          params = conditions.values
      end
      
      dbh.select_all(
        sql,
        *params
      ).map { |r| self.new( r ) }
    end
    
    # ------------------- :nodoc:
    
    def initialize( row )
      @row = row
      @row.column_names.each do |col|
        self.class.send( :define_method, col.to_sym ) do
          @row[ col ]
        end
        self.class.send( :define_method, "#{col}=".to_sym ) do |new_value|
          num_changed = dbh.do(
            "UPDATE #{table} SET #{col} = ?", new_value
          )
          if num_changed > 0
            @row[ col ] = new_value
          end
        end
      end
    end
    
    def method_missing( method, *args )
      @row.send( method, *args )
    end
    
    def pk
      @row[ self.class.pk ]
    end
  end
  
  # Define a new DBI::Model like this:
  #   class Post < DBI::Model( :posts ); end
  # You can specify the primary key column like so:
  #   class Author < DBI::Model( :authors, 'id' ); end
  def self.Model( table, pk = 'id' )
    Class.new( DBI::Model ) do |klass|
      h = DBI::DatabaseHandle.last_handle
      if h.nil?
        raise DBI::Error.new( "Attempted to create a Model class without first connecting to a database." )
      end
      
      klass.trait[ :dbh ] = h
      klass.trait[ :table ] = table
      klass.trait[ :pk ] = pk
    end
  end
  
end