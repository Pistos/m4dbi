require 'dbi'
require 'metaid'

module DBI
  class Model
    #attr_reader :row
    ancestral_trait_reader :dbh, :table
    ancestral_trait_class_reader :dbh, :table, :pk, :columns
    
    M4DBI_UNASSIGNED = '__m4dbi_unassigned__'
    
    extend Enumerable
    
    def self.[]( hash_or_pk_value )
      case hash_or_pk_value
        when Hash
          clause, values = hash_or_pk_value.to_where_clause
          row = dbh.select_one(
            "SELECT * FROM #{table} WHERE #{clause}",
            *values
          )
        else
          row = dbh.select_one(
            "SELECT * FROM #{table} WHERE #{pk} = ?",
            hash_or_pk_value
          )
      end
      
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
          cond, params = conditions.to_where_clause
          sql = "SELECT * FROM #{table} WHERE #{cond}"
      end
      
      self.from_rows(
        dbh.select_all( sql, *params )
      )
    end
    
    def self.one_where( conditions, *args )
      case conditions
        when String
          sql = "SELECT * FROM #{table} WHERE #{conditions} LIMIT 1"
          params = args
        when Hash
          cond, params = conditions.to_where_clause
          sql = "SELECT * FROM #{table} WHERE #{cond} LIMIT 1"
      end
      
      row = dbh.select_one( sql, *params )
      if row
        self.new( row )
      end
    end
    
    def self.all
      self.from_rows(
        dbh.select_all( "SELECT * FROM #{table}" )
      )
    end
    
    # TODO: Perhaps we'll use cursors for Model#each.
    def self.each( &block )
      self.all.each( &block )
    end
    
    def self.one
      row = dbh.select_one( "SELECT * FROM #{table} LIMIT 1" )
      if row
        self.new( row )
      end
    end
    
    def self.count
      dbh.select_column( "SELECT COUNT(*) FROM #{table}" )
    end
    
    def self.create( hash = {} )
      if block_given?
        row = DBI::Row.new(
          columns.collect { |c| c[ 'name' ] },
          [ M4DBI_UNASSIGNED ] * columns.size
        )
        yield row
        hash = row.to_h
        hash.to_a.each do |key,value|
          if value == M4DBI_UNASSIGNED
            hash.delete( key )
          end
        end
      end
      
      keys = hash.keys
      cols = keys.join( ',' )
      values = keys.map { |key| hash[ key ] }
      value_placeholders = values.map { |v| '?' }.join( ',' )
      rec = nil
      
      dbh.one_transaction do |dbh_|
        num_inserted = dbh_.do(
          "INSERT INTO #{table} ( #{cols} ) VALUES ( #{value_placeholders} )",
          *values
        )
        if num_inserted > 0
          pk_value = hash[ self.pk.to_sym ] || hash[ self.pk.to_s ]
          if pk_value
            rec = self.one_where( self.pk => pk_value )
          else
            begin
              rec = last_record( dbh_ )
            rescue NoMethodError => e
              # ignore
              #puts "not implemented: #{e.message}"
            end
          end
        end
      end
      
      rec
    end
    
    def self.find_or_create( hash = nil )
      item = nil
      error = nil
      item = self.one_where( hash )
      if item.nil?
        item =
          begin
            self.create( hash )
          rescue => error
            self.one_where( hash )
          end
      end
      if item
        item
      else
        raise error
      end
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
    
    class << self
      alias s select_all
      alias s1 select_one
    end
    
    def self.update( where_hash_or_clause, set_hash )
      where_clause = nil
      set_clause = nil
      where_params = nil
      
      if where_hash_or_clause.respond_to? :keys
        where_clause, where_params = where_hash_or_clause.to_where_clause
      else
        where_clause = where_hash_or_clause
        where_params = []
      end
      
      set_clause, set_params = set_hash.to_set_clause
      params = set_params + where_params
      dbh.do(
        "UPDATE #{table} SET #{set_clause} WHERE #{where_clause}",
        *params
      )
    end
    
    def self.update_one( pk_value, set_hash )
      set_clause, set_params = set_hash.to_set_clause
      params = set_params + [ pk_value ]
      dbh.do(
        "UPDATE #{table} SET #{set_clause} WHERE #{pk} = ?",
        *params
      )
    end
    
    # Example:
    #   DBI::Model.one_to_many( Author, :posts, Post, :author, :author_id )
    #   her_posts = some_author.posts
    #   the_author = some_post.author
    def self.one_to_many( the_one, the_many, many_as, one_as, the_one_fk )
      the_one.class_def( many_as.to_sym ) do
        DBI::Collection.new( self, the_many, the_one_fk )
      end
      the_many.class_def( one_as.to_sym ) do
        the_one[ @row[ the_one_fk ] ]
      end
      the_many.class_def( "#{one_as}=".to_sym ) do |new_one|
        send( "#{the_one_fk}=".to_sym, new_one.pk )
      end
    end
    
    # Example:
    #   DBI::Model.many_to_many(
    #     @m_author, @m_fan, :authors_liked, :fans, :authors_fans, :author_id, :fan_id
    #   )
    #   her_fans = some_author.fans
    #   favourite_authors = fan.authors_liked
    def self.many_to_many( model1, model2, m1_as, m2_as, join_table, m1_fk, m2_fk )
      model1.class_def( m2_as.to_sym ) do
        model2.select_all(
          %{
            SELECT
              m2.*
            FROM
              #{model2.table} m2,
              #{join_table} j
            WHERE
              j.#{m1_fk} = ?
              AND m2.id = j.#{m2_fk}
          },
          pk
        )
      end
      
      model2.class_def( m1_as.to_sym ) do
        model1.select_all(
          %{
            SELECT
              m1.*
            FROM
              #{model1.table} m1,
              #{join_table} j
            WHERE
              j.#{m2_fk} = ?
              AND m1.id = j.#{m1_fk}
          },
          pk
        )
      end
    end
    
    # ------------------- :nodoc:
    
    def initialize( row )
      if not row.respond_to?( "[]".to_sym ) or not row.respond_to?( "[]=".to_sym )
        raise DBI::Error.new( "Attempted to instantiate DBI::Model with an invalid argument (#{row.inspect}).  (Expecting DBI::Row.)" )
      end
      if caller[ 1 ] !~ %r{/m4dbi/model\.rb:}
        warn "Do not call DBI::Model#new directly; use DBI::create instead."
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
    
    def hash
      "#{self.class.hash}#{pk}".to_i
    end
    
    def eql?( other )
      hash == other.hash
    end
    
    def set( hash )
      set_clause, set_params = hash.to_set_clause
      set_params << pk
      dbh.do(
        "UPDATE #{table} SET #{set_clause} WHERE #{pk_column} = ?",
        *set_params
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
    
    # save does nothing.  It exists to provide compatibility with other ORMs.
    def save
      nil
    end
  end
  
  # Define a new DBI::Model like this:
  #   class Post < DBI::Model( :posts ); end
  # You can specify the primary key column like so:
  #   class Author < DBI::Model( :authors, 'id' ); end
  def self.Model( table, pk_ = 'id' )
    h = DBI::DatabaseHandle.last_handle
    if h.nil? or not h.connected?
      raise DBI::Error.new( "Attempted to create a Model class without first connecting to a database." )
    end
    
    model_key = case h.handle
      when DBI::DBD::Pg::Database
        "#{h.dbname}::#{table}"
      # TODO: more DBDs
      else
        table
    end
    
    @models ||= Hash.new
    @models[ model_key ] ||= Class.new( DBI::Model ) do |klass|
      klass.trait( {
        :dbh => h,
        :table => table,
        :pk => pk_,
        :columns => h.columns( table.to_s ),
      } )
      
      case h.handle
        when DBI::DBD::Pg::Database
          meta_def( "last_record".to_sym ) do |dbh_|
            self.s1 "SELECT * FROM #{table} WHERE #{pk} = currval( '#{table}_#{pk}_seq' );" 
          end
        # TODO: more DBDs
      end
      
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