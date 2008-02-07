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
    
    def self.create( hash )
      if block_given?
      else
        keys = hash.keys
        values = keys.collect { |k| hash[ k ] }
        row = DBI::Row.new( keys, values )
        self.new( row )
      end
    end
    
    # ------------------- :nodoc:
    
    def initialize( row )
      @row = row
      $stderr.puts "setting @row to #{@row.inspect}"
    end
    
    def method_missing( method, *args )
      @row.send( method, *args )
    end
    
    def pk
      @row[ self.class.pk ]
    end
    
    def pk_column
      self.class.pk
    end
    
    def ==( other )
      other and ( pk == other.pk )
    end
    
    def set( hash )
      set_clause = hash.keys.map { |key|
        "#{key} = ?"
      }.join( ', ' )
      params = hash.values + [ pk ]
      dbh.do(
        "UPDATE #{table} SET #{set_clause} WHERE #{pk_column} = ?",
        *params
      )
    end
    
  end
  
  # Define a new DBI::Model like this:
  #   class Post < DBI::Model( :posts ); end
  # You can specify the primary key column like so:
  #   class Author < DBI::Model( :authors, 'id' ); end
  def self.Model( table, pk_ = 'id' )
    Class.new( DBI::Model ) do |klass|
      h = DBI::DatabaseHandle.last_handle
      if h.nil?
        raise DBI::Error.new( "Attempted to create a Model class without first connecting to a database." )
      end
      
      klass.trait[ :dbh ] = h
      klass.trait[ :table ] = table
      klass.trait[ :pk ] = pk_
      
      h.columns( table.to_s ).each do |col|
        colname = col[ 'name' ]
        
        class_def( colname.to_sym ) do
          $stderr.puts "foo from #{colname} (#{colname.class}): '#{@row[ colname ]}' at " +  caller.find { |s| s !~ /bacon/ }
          $stderr.puts "@row is |#{@row.column_names}| #{@row.inspect} (#{@row.class})"
          @row[ colname ]
        end
        
        class_def( "#{colname}=".to_sym ) do |new_value|
          num_changed = dbh.do(
            "UPDATE #{table} SET #{colname} = ? WHERE #{pk_column} = ?",
            new_value,
            pk
          )
          if num_changed > 0
            @row[ colname ] = new_value
          end
        end
      end
    end
  end
  
end