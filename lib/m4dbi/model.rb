module M4DBI
  class Model
    #attr_reader :row
    ancestral_trait_reader :dbh, :table
    ancestral_trait_class_reader :dbh, :table, :pk, :columns

    M4DBI_UNASSIGNED = '__m4dbi_unassigned__'

    extend Enumerable

    def self.[]( first_arg, *args )
      if args.size == 0
        case first_arg
          when Hash
            clause, values = first_arg.to_where_clause
          when NilClass
            clause = pk_clause
            values = [ first_arg ]
          else # single value
            clause = pk_clause
            values = Array( first_arg )
        end
      else
        clause = pk_clause
        values = [ first_arg ] + args
      end

      row = dbh.select_one(
        "SELECT * FROM #{table} WHERE #{clause}",
        *values
      )

      if row
        self.new( row )
      end
    end

    def self.pk_clause
      pk.map { |col|
        "#{col} = ?"
      }.join( ' AND ' )
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
      dbh.select_column( "SELECT COUNT(*) FROM #{table}" ).to_i
    end

    def self.create( hash = {} )
      if block_given?
        struct = Struct.new( *( columns.collect { |c| c[ 'name' ].to_sym } ) )
        row = struct.new( *( [ M4DBI_UNASSIGNED ] * columns.size ) )
        yield row
        hash = {}
        row.members.each do |k|
          if row[ k ] != M4DBI_UNASSIGNED
            hash[ k ] = row[ k ]
          end
        end
      end

      keys = hash.keys
      cols = keys.join( ',' )
      values = keys.map { |key| hash[ key ] }
      value_placeholders = values.map { |v| '?' }.join( ',' )
      rec = nil

      dbh.one_transaction do |dbh_|
        num_inserted = dbh_.execute(
          "INSERT INTO #{table} ( #{cols} ) VALUES ( #{value_placeholders} )",
          *values
        )
        if num_inserted > 0
          pk_hash = hash.slice( *(
            self.pk.map { |pk_col| pk_col.to_sym }
          ) )
          if pk_hash.empty?
            pk_hash = hash.slice( *(
              self.pk.map { |pk_col| pk_col.to_s }
            ) )
          end
          if not pk_hash.empty?
            rec = self.one_where( pk_hash )
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
      error = M4DBI::Error.new( "Failed to find_or_create( #{hash.inspect} )" )
      item = self.one_where( hash )
      if item.nil?
        item =
          begin
            self.create( hash )
          rescue Exception => error
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
      dbh.execute(
        "UPDATE #{table} SET #{set_clause} WHERE #{where_clause}",
        *params
      )
    end

    def self.update_one( *args )
      set_clause, set_params = args[ -1 ].to_set_clause
      pk_values = args[ 0..-2 ]
      params = set_params + pk_values
      dbh.execute(
        "UPDATE #{table} SET #{set_clause} WHERE #{pk_clause}",
        *params
      )
    end

    # Example:
    #   M4DBI::Model.one_to_many( Author, Post, :posts, :author, :author_id )
    #   her_posts = some_author.posts
    #   the_author = some_post.author
    def self.one_to_many( the_one, the_many, many_as, one_as, the_one_fk )
      the_one.class_def( many_as.to_sym ) do
        M4DBI::Collection.new( self, the_many, the_one_fk )
      end
      the_many.class_def( one_as.to_sym ) do
        the_one[ @row[ the_one_fk ] ]
      end
      the_many.class_def( "#{one_as}=".to_sym ) do |new_one|
        send( "#{the_one_fk}=".to_sym, new_one.pk )
      end
    end

    # Example:
    #   M4DBI::Model.many_to_many(
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
          # TODO: m2.id?  Should be m2.pk or something
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
          # TODO: Should be m1.pk not m1.id
          pk
        )
      end
    end

    # ------------------- :nodoc:

    def initialize( row )
      if not row.respond_to?( "[]".to_sym ) or not row.respond_to?( "[]=".to_sym )
        raise M4DBI::Error.new( "Attempted to instantiate M4DBI::Model with an invalid argument (#{row.inspect}).  (Expecting DBI::Row.)" )
      end
      if caller[ 1 ] !~ %r{/m4dbi/model\.rb:}
        warn "Do not call M4DBI::Model#new directly; use M4DBI::Model#create instead."
      end
      @row = row
    end

    def method_missing( method, *args )
      begin
        @row.send( method, *args )
      rescue NoMethodError => e
        if e.backtrace.grep /method_missing/
          # Prevent infinite recursion
          self_str = 'model object'
        elsif self.respond_to? :to_s
          self_str = self.to_s
        elsif self.respond_to? :inspect
          self_str = self.inspect
        elsif self.respond_to? :class
          self_str = "#{self.class} object"
        else
          self_str = "instance of unknown model"
        end

        raise NoMethodError.new(
          "undefined method '#{method}' for #{self_str}",
          method,
          args
        )
      end
    end

    # Returns a single value for single-column primary keys,
    # returns an Array for multi-column primary keys.
    def pk
      if pk_columns.size == 1
        @row[ pk_columns[ 0 ] ]
      else
        pk_values
      end
    end

    # Always returns an Array of values, even for single-column primary keys.
    def pk_values
      pk_columns.map { |col|
        @row[ col ]
      }
    end

    def pk_columns
      self.class.pk
    end

    def pk_clause
      pk_columns.map { |col|
        "#{col} = ?"
      }.join( ' AND ' )
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
      num_updated = dbh.execute(
        "UPDATE #{table} SET #{set_clause} WHERE #{pk_clause}",
        *set_params
      )
      if num_updated > 0
        hash.each do |key,value|
          @row[ key ] = value
        end
      end
      num_updated
    end

    # Returns true iff the record and only the record was successfully deleted.
    def delete
      num_deleted = dbh.execute(
        "DELETE FROM #{table} WHERE #{pk_clause}",
        *pk_values
      )
      num_deleted == 1
    end

    # save does nothing.  It exists to provide compatibility with other ORMs.
    def save
      nil
    end
  end

  # Define a new M4DBI::Model like this:
  #   class Post < M4DBI::Model( :posts ); end
  # You can specify the primary key column(s) using an option, like so:
  #   class Author < M4DBI::Model( :authors, pk: [ 'auth_num' ] ); end
  def self.Model( table, options = Hash.new )
    h = options[ :dbh ] || M4DBI.last_dbh
    if h.nil? || ! h.connected?
      raise M4DBI::Error.new( "Attempted to create a Model class without first connecting to a database." )
    end
    pk_ = options[ :pk ] || [ 'id' ]
    if not pk_.respond_to? :each
      raise M4DBI::Error.new( "Primary key must be enumerable (was given #{pk_.inspect})" )
    end

    model_key =
      if h.respond_to? :database_name
        "#{h.database_name}::#{table}"
      else
        table
      end

    @models ||= Hash.new
    @models[ model_key ] ||= Class.new( M4DBI::Model ) do |klass|
      klass.trait( {
        :dbh => h,
        :table => table,
        :pk => pk_,
        :columns => h.table_schema( table.to_sym ).columns,
      } )

      meta_def( 'pk_str'.to_sym ) do
        if pk.size == 1
          pk[ 0 ].to_s
        else
          pk.to_s
        end
      end

      if defined?( RDBI::Driver::PostgreSQL ) and RDBI::Driver::PostgreSQL === h
        # TODO: This is broken for non-SERIAL or multi-column primary keys
        meta_def( "last_record".to_sym ) do |dbh_|
          self.s1 "SELECT * FROM #{table} WHERE #{pk_str} = currval( '#{table}_#{pk_str}_seq' );"
        end
      # TODO: MySQL
      # elsif defined?( DBI::DBD::Mysql::Database ) and DBI::DBD::Mysql::Database === h
        # meta_def( "last_record".to_sym ) do |dbh_|
          # self.s1 "SELECT * FROM #{table} WHERE #{pk_str} = LAST_INSERT_ID();"
        # end
      elsif defined?( RDBI::Driver::SQLite3 ) and RDBI::Driver::SQLite3 === h
        meta_def( "last_record".to_sym ) do |dbh_|
          self.s1 "SELECT * FROM #{table} WHERE #{pk_str} = last_insert_rowid();"
        end
      # TODO: more DB drivers
      end

      klass.trait[ :columns ].each do |col|

        colname = col[ 'name' ]
        method = colname.to_sym
        while klass.method_defined? method
          method = "#{method}_".to_sym
        end

        # Column readers
        class_def( method ) do
          @row[ colname ]
        end

        # Column writers

        class_def( "#{method}=".to_sym ) do |new_value|
          num_changed = dbh.execute(
            "UPDATE #{table} SET #{colname} = ? WHERE #{pk_clause}",
            new_value,
            *pk_values
          )
          if num_changed > 0
            @row[ colname ] = new_value
          end
        end

        class_def( '[]='.to_sym ) do |colname, new_value|
          num_changed = dbh.execute(
            "UPDATE #{table} SET #{colname} = ? WHERE #{pk_clause}",
            new_value,
            *pk_values
          )
          if num_changed > 0
            @row[ colname ] = new_value
          end
        end

      end
    end
  end

end