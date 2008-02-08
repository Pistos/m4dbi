require 'dbi'
require 'metaid'

module DBI
  class Model
    #attr_reader :row
    ancestral_trait_reader :dbh, :table, :pk
    ancestral_trait_class_reader :dbh, :table, :pk, :columns
    
    def self.[]( pk_value )
      row = dbh.select_one(
        "SELECT * FROM #{table} WHERE #{pk} = ?",
        pk_value
      )
      
      if row
        self.new( row )
      end
    end
    
    def self.from_rows( rows )
      rows.map { |r| self.new( r ) }
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
      
      self.from_rows(
        dbh.select_all(
          sql,
          *params
        )
      )
    end
    
    def self.all
      self.from_rows(
        dbh.select_all( "SELECT * FROM #{table}" )
      )
    end
    
    def self.create( hash = nil )
      if block_given?
        row = DBI::Row.new( columns.collect { |c| c[ 'name' ] } )
        yield row
      else
        keys = hash.keys
        values = keys.collect { |k| hash[ k ] }
        row = DBI::Row.new( keys.collect { |k| k.to_s }, values )
      end
      
      new_record = self.new( row )
      
      cols = row.column_names.join( ',' )
      values = row.column_names.map { |col| row[ col ] }
      value_placeholders = values.map { |v| '?' }.join( ',' )
      dbh.do(
        "INSERT INTO #{table} ( #{cols} ) VALUES ( #{value_placeholders} )",
        *values
      )
      
      new_record
    end
    
    def self.select_all( *args )
      self.from_rows(
        dbh.select_all( *args )
      )
    end
    
    def self.select_one( *args )
      row = dbh.select_one( *args )
      if row
        self.new( row )
      end
    end
    
    # ------------------- :nodoc:
    
    def initialize( row )
      if row.nil?
        raise DBI::Error.new( "Attempted to instantiate DBI::Model with a nil DBI::Row." )
      end
      @row = row
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
    
    # Returns true iff the record and only the record was successfully deleted.
    def delete
      num_deleted = dbh.do(
        "DELETE FROM #{table} WHERE #{pk_column} = ?",
        pk
      )
      num_deleted == 1
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
      
      klass.trait( {
        :dbh => h,
        :table => table,
        :pk => pk_,
        :columns => h.columns( table.to_s ),
      } )
      
      klass.trait[ :columns ].each do |col|
        colname = col[ 'name' ]
        
        class_def( colname.to_sym ) do
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