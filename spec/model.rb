require File.join(File.dirname(__FILE__), 'helper')

describe 'M4DBI::Model' do
  it 'raises an exception when trying to define a model before connecting to a database' do
    dbh = M4DBI.last_dbh
    if dbh && dbh.respond_to?( :disconnect )
      dbh.disconnect
      dbh.should.not.be.connected
    end
    dbh = M4DBI.last_dbh
    if dbh
      dbh.should.not.be.connected
    end
    should.raise( M4DBI::Error ) do
      @m_author = Class.new( M4DBI::Model( :authors ) )
    end
  end
end

$dbh = connect_to_spec_database
reset_data

class ManyCol < M4DBI::Model( :many_col_table )
  def inc
    self.c1 = c1 + 10
  end

  def dec
    self.c1 = c1 - 10
  end
end

describe 'A M4DBI::Model subclass' do
  before do
    # Here we subclass M4DBI::Model.
    # This is nearly equivalent to the typical "ChildClassName < ParentClassName"
    # syntax, but allows us to refer to the class in our specs.
    @m_author = Class.new( M4DBI::Model( :authors ) )
    @m_post = Class.new( M4DBI::Model( :posts ) )
    @m_empty = Class.new( M4DBI::Model( :empty_table ) )
    @m_mc = Class.new( M4DBI::Model( :many_col_table ) )
    @m_nipk = Class.new( M4DBI::Model( :non_id_pk, :pk => [ :str ] ) )
    @m_mcpk = Class.new( M4DBI::Model( :mcpk, :pk => [ :kc1, :kc2 ] ) )
    class Author < M4DBI::Model( :authors )
      remove_after_create_hooks
      remove_after_update_hooks
      remove_after_delete_hooks
    end
  end

  it 'can be defined' do
    @m_author.should.not.be.nil
    @m_post.should.not.be.nil
  end

  it 'maintains identity across different inheritances' do
    should.not.raise do
      class Author < M4DBI::Model( :authors ); end
      class Author < M4DBI::Model( :authors ); end
    end
  end

  it 'maintains member methods across redefinitions' do
    class Author < M4DBI::Model( :authors )
      def method1; 1; end
    end
    class Author < M4DBI::Model( :authors )
      def method2; 2; end
    end
    a = Author[ 3 ]
    a.method1.should.equal 1
    a.method2.should.equal 2
  end

  it 'maintains identity across different database handles of the same database' do
    # If you try to subclass a class a second time with a different parent class,
    # Ruby raises an exception.
    should.not.raise do
      original_handle = M4DBI.last_dbh

      class Author < M4DBI::Model( :authors ); end

      dbh = connect_to_spec_database
      new_handle = M4DBI.last_dbh
      new_handle.should.equal dbh
      new_handle.should.not.equal original_handle

      class Author < M4DBI::Model( :authors ); end
    end
  end

  it 'provides the database handle it is using' do
    begin
      @m_author.dbh.should.equal $dbh

      dbh = connect_to_spec_database( ENV[ 'M4DBI_DATABASE2' ] || 'm4dbi2' )
      @m_author2 = Class.new( M4DBI::Model( :authors ) )
      @m_author2.dbh.should.equal dbh
    ensure
      # Clean up handles for later specs
      connect_to_spec_database
    end
  end

  it 'maintains distinction from models of the same name in different databases' do
    begin
      a1 = @m_author[ 1 ]
      a1.should.not.be.nil
      a1.name.should.equal 'author1'

      dbh = connect_to_spec_database( ENV[ 'M4DBI_DATABASE2' ] || 'm4dbi2' )
      reset_data( dbh, "test-data2.sql" )

      @m_author2 = Class.new( M4DBI::Model( :authors ) )
      @m_author2.dbh.should.not.equal @m_author.dbh

      @m_author2[ 1 ].should.be.nil
      a11 = @m_author2[ 11 ]
      a11.should.not.be.nil
      a11.name.should.equal 'author11'

      a2 = @m_author[ 2 ]
      a2.should.not.be.nil
      a2.name.should.equal 'author2'
    ensure
      # Clean up handles for later specs
      # puts dbh.object_id
      # dbh.disconnect if dbh and dbh.connected?
      connect_to_spec_database
    end
  end

  it 'can use a specific database handle' do
    begin
      dbh1 = connect_to_spec_database
      dbh1.should.equal M4DBI.last_dbh
      dbh2 = connect_to_spec_database( ENV[ 'M4DBI_DATABASE2' ] || 'm4dbi2' )
      dbh2.should.equal M4DBI.last_dbh
      reset_data( dbh2, "test-data2.sql" )

      dbh1.should.not.equal dbh2

      class Author1 < M4DBI::Model( :authors, :dbh => dbh1 ); end
      class Author2 < M4DBI::Model( :authors, :dbh => dbh2 ); end

      a1 = Author1[ 1 ]
      a1.should.not.be.nil
      a1.name.should.equal 'author1'

      a11 = Author2[ 11 ]
      a11.should.not.be.nil
      a11.name.should.equal 'author11'
    ensure
      # Clean up handles for later specs
      connect_to_spec_database
    end
  end

  it 'raises an exception when creating with invalid arguments' do
    should.raise( M4DBI::Error ) do
      @m_author.new nil
    end
    should.raise( M4DBI::Error ) do
      @m_author.new 2
    end
    should.raise( M4DBI::Error ) do
      @m_author.new Object.new
    end
  end

  it 'provides hash-like single-record access via #[ primary_key_value ]' do
    o = @m_author[ 1 ]
    o.should.not.be.nil
    o.class.should.equal @m_author
    o.name.should.equal 'author1'

    o = @m_author[ 2 ]
    o.should.not.be.nil
    o.class.should.equal @m_author
    o.name.should.equal 'author2'

    o = @m_nipk[ 'one' ]
    o.should.not.be.nil
    o.class.should.equal @m_nipk
    o.c1.should.equal 1
    o.c2.should.equal 2

    o = @m_nipk[ 'two' ]
    o.should.not.be.nil
    o.class.should.equal @m_nipk
    o.c1.should.equal 2
    o.c2.should.equal 4

    o = @m_mcpk[ [ 2, 2 ] ]
    o.should.not.be.nil
    o.class.should.equal @m_mcpk
    o.val.should.equal 'two two'

    o = @m_mcpk[ 1, 1 ]
    o.should.not.be.nil
    o.class.should.equal @m_mcpk
    o.val.should.equal 'one one'

    o = @m_mcpk[ { :kc1 => 5, :kc2 => 6 } ]
    o.should.not.be.nil
    o.class.should.equal @m_mcpk
    o.val.should.equal 'five six'

    should.not.raise( RDBI::Error ) do
      o = @m_author[ nil ]
      o.should.be.nil
    end
  end

  it 'provides hash-like single-record access via #[ field_hash ]' do
    o = @m_author[ :name => 'author1' ]
    o.should.not.be.nil
    o.class.should.equal @m_author
    o[ 'id' ].should.equal 1

    o = @m_post[ :author_id => 1 ]
    o.should.not.be.nil
    o.class.should.equal @m_post
    o.text.should.equal 'First post.'

    o = @m_mc[ :c1 => 100, :c2 => 50 ]
    o.should.not.be.nil
    o.class.should.equal @m_mc
    o.c3.should.equal 20

    o = @m_mc[ :c1 => 100, :c2 => nil ]
    o.should.not.be.nil
    o.class.should.equal @m_mc
    o.c3.should.equal 40
  end

  it 'returns nil from #[] when no record is found' do
    o = @m_author[ 999 ]
    o.should.be.nil

    o = @m_author[ :name => 'foobar' ]
    o.should.be.nil
  end

  it 'provides multi-record access via #where( Hash )' do
    posts = @m_post.where( :author_id => 1 )
    posts.should.not.be.nil
    posts.should.not.be.empty
    posts.size.should.equal 2
    posts[ 0 ].class.should.equal @m_post

    sorted_posts = posts.sort { |p1,p2|
      p1[ 'id' ] <=> p2[ 'id' ]
    }
    p = sorted_posts.first
    p.text.should.equal 'First post.'

    rows = @m_mc.where( :c1 => 100, :c2 => 50 )
    rows.should.not.be.nil
    rows.should.not.be.empty
    rows.size.should.equal 1
    row = rows[ 0 ]
    row.class.should.equal @m_mc
    row.c1.should.equal 100
    row.c3.should.equal 20

    rows = @m_mc.where( :c1 => 100, :c2 => nil )
    rows.should.not.be.nil
    rows.should.not.be.empty
    rows.size.should.equal 1
    row = rows[ 0 ]
    row.class.should.equal @m_mc
    row.c1.should.equal 100
    row.c3.should.equal 40
  end

  it 'provides multi-record access via #where( String )' do
    posts = @m_post.where( "id < 3" )
    posts.should.not.be.nil
    posts.should.not.be.empty
    posts.size.should.equal 2
    posts[ 0 ].class.should.equal @m_post

    sorted_posts = posts.sort { |p1,p2|
      p2[ 'id' ] <=> p1[ 'id' ]
    }
    p = sorted_posts.first
    p.text.should.equal 'Second post.'
  end

  it 'provides multi-record access via #where( String, param, param... )' do
    posts = @m_post.where( "id < ?", 3 )
    posts.should.not.be.nil
    posts.should.not.be.empty
    posts.size.should.equal 2
    posts[ 0 ].class.should.equal @m_post

    sorted_posts = posts.sort { |p1,p2|
      p2[ 'id' ] <=> p1[ 'id' ]
    }
    p = sorted_posts.first
    p.text.should.equal 'Second post.'
  end

  it 'returns an empty array from #where when no records are found' do
    a = @m_author.where( :id => 999 )
    a.should.be.empty

    p = @m_post.where( "text = 'aoeu'" )
    p.should.be.empty
  end

  it 'provides single-record access via #one_where( Hash )' do
    post = @m_post.one_where( :author_id => 2 )
    post.should.not.be.nil
    post.class.should.equal @m_post
    post.text.should.equal 'Second post.'

    row = @m_mc.one_where( :c1 => 100, :c2 => nil )
    row.should.not.be.nil
    row.class.should.equal @m_mc
    row.c1.should.equal 100
    row.c3.should.equal 40
  end

  it 'provides single-record access via #one_where( String )' do
    post = @m_post.one_where( "text LIKE '%Third%'" )
    post.should.not.be.nil
    post.class.should.equal @m_post
    post[ 'id' ].should.equal 3
  end

  it 'provides single-record access via #one_where( String, param, param... )' do
    post = @m_post.one_where( "text LIKE ?", '%Third%' )
    post.should.not.be.nil
    post.class.should.equal @m_post
    post[ 'id' ].should.equal 3
  end

  it 'returns nil from #one_where when no record is found' do
    a = @m_author.one_where( :id => 999 )
    a.should.be.nil

    p = @m_post.one_where( "text = 'aoeu'" )
    p.should.be.nil
  end

  it 'returns all table records via #all' do
    rows = @m_author.all
    rows.should.not.be.nil
    rows.should.not.be.empty
    rows.size.should.equal 3

    rows[ 0 ][ 'id' ].should.equal 1
    rows[ 0 ].class.should.equal @m_author
    rows[ 0 ].name.should.equal 'author1'
    rows[ 1 ][ 'id' ].should.equal 2
    rows[ 1 ].class.should.equal @m_author
    rows[ 1 ].name.should.equal 'author2'
  end

  it 'returns an empty array when #all is called on an empty table' do
    rows = @m_empty.all
    rows.should.not.be.nil
    rows.should.be.empty
  end

  it 'returns a random single record from #one' do
    one = @m_author.one
    one.should.not.be.nil
    one.class.should.equal @m_author
  end

  it 'returns nil from #one on an empty table' do
    one = @m_empty.one
    one.should.be.nil
  end

  it 'returns the record count via #count' do
    n = @m_author.count
    n.should.equal 3
  end

  it 'can be instantiated with no argument' do
    lambda {
      @m_empty.new
    }.should.not.raise(Exception)
  end

  it 'provides a means to create a new record from a Hash' do
    num_authors = @m_author.count

    a = @m_author.create(
      :id => 99,
      :name => 'author99'
    )
    a.should.not.be.nil
    a.class.should.equal @m_author
    a[ 'id' ].should.equal 99
    a.should.respond_to :name
    a.should.not.respond_to :no_column_by_this_name
    a.name.should.equal 'author99'

    a_ = @m_author[ 99 ]
    a_.should.not.be.nil
    a_.should.equal a
    a_.name.should.equal 'author99'

    # Insert without auto-incrementing primary key specified
    # Try at least as many times as there were records in the DB,
    # because the sequence used for the IDs is independent of
    # the actual ID values in the DB for some RDBMSes.
    num_authors.times do
      begin
        a = @m_author.create(
          :name => 'author10'
        )
        break  # Stop on success
      rescue Exception => e
        if e.message !~ /duplicate/
          raise e
        end
      end
    end
    a.should.not.be.nil
    a.class.should.equal @m_author
    a[ 'id' ].should.not.be.nil
    a.should.respond_to :name
    a.should.not.respond_to :no_column_by_this_name
    a.name.should.equal 'author10'

    a_ = @m_author[ a[ 'id' ] ]
    a_.should.not.be.nil
    a_.should.equal a
    a_.name.should.equal 'author10'

    reset_data
  end

  it 'provides a means to create a new record from a block' do
    should.raise( NoMethodError ) do
      @m_author.create { |rec|
        rec.no_such_column = 'foobar'
      }
    end

    a = @m_author.create { |rec|
      rec[ 'id' ] = 9
      rec.name = 'author9'
    }
    a.should.not.be.nil
    a.class.should.equal @m_author
    a[ 'id' ].should.equal 9
    a.name.should.equal 'author9'

    a_ = @m_author[ 9 ]
    a_.should.equal a
    a_.name.should.equal 'author9'

    m = nil
    should.not.raise do
      m = @m_mc.create { |rec|
        rec[ 'id' ] = 1
        rec.c2 = 7
        rec.c3 = 8
      }
    end
    m_ = @m_mc[ 1 ]
    m_[ 'id' ].should.equal 1
    m_.c1.should.be.nil
    m_.c2.should.equal 7
    m_.c3.should.equal 8
    m_.c4.should.be.nil
    m_.c5.should.be.nil

    reset_data
  end

  it 'provides a means to create a new record from an empty Hash' do
    @m = Class.new( M4DBI::Model( :has_all_defaults ) )
    num_records = @m.count

    r = @m.create
    @m.count.should.equal num_records + 1
    r.should.not.be.nil
    r.class.should.equal @m
    r[ 'id' ].should.not.be.nil
    r.should.respond_to :time_created
    r.should.not.respond_to :no_column_by_this_name
    r.time_created.should.not.be.nil
    r.time_created.should.be.kind_of DateTime
  end

  it 'returns a record via #find_or_create( Hash )' do
    n = @m_author.count
    a = @m_author.find_or_create(
      :id => 1,
      :name => 'author1'
    )
    a.should.not.be.nil
    a.class.should.equal @m_author
    a[ 'id' ].should.equal 1
    a.should.respond_to :name
    a.should.not.respond_to :no_column_by_this_name
    a.name.should.equal 'author1'
    @m_author.count.should.equal n

    n = @m_mc.count
    row = @m_mc.find_or_create( :c1 => 100, :c2 => nil )
    row.should.not.be.nil
    row.class.should.equal @m_mc
    row.c1.should.equal 100
    row.c3.should.equal 40
    @m_mc.count.should.equal n
  end

  it 'creates a record via #find_or_create( Hash )' do
    n = @m_author.count
    a = @m_author.find_or_create(
      :id => 9,
      :name => 'author9'
    )
    a.should.not.be.nil
    a.class.should.equal @m_author
    a[ 'id' ].should.equal 9
    a.should.respond_to :name
    a.should.not.respond_to :no_column_by_this_name
    a.name.should.equal 'author9'
    @m_author.count.should.equal n+1

    a_ = @m_author[ 9 ]
    a_.should.not.be.nil
    a_.should.equal a
    a_.name.should.equal 'author9'

    reset_data
  end

  it 'provides a means to use generic raw SQL to select model instances' do
    posts = @m_post.s(
      %{
        SELECT
          p.*
        FROM
          posts p,
          authors a
        WHERE
          p.author_id = a.id
          AND a.name = ?
      },
      'author1'
    )
    posts.should.not.be.nil
    posts.should.not.be.empty
    posts.size.should.equal 2

    posts[ 0 ][ 'id' ].should.equal 1
    posts[ 0 ].text.should.equal 'First post.'
    posts[ 0 ].class.should.equal @m_post
    posts[ 1 ][ 'id' ].should.equal 3
    posts[ 1 ].text.should.equal 'Third post.'
    posts[ 1 ].class.should.equal @m_post

    no_posts = @m_post.s( "SELECT * FROM posts WHERE 1+1 = 3" )
    no_posts.should.not.be.nil
    no_posts.should.be.empty
  end

  it 'provides a means to use generic raw SQL to select one model instance' do
    post = @m_post.s1(
      %{
        SELECT
          p.*
        FROM
          posts p,
          authors a
        WHERE
          p.author_id = a.id
          AND a.name = ?
        ORDER BY
          id DESC
      },
      'author1'
    )

    post.should.not.be.nil
    post.class.should.equal @m_post

    post[ 'id' ].should.equal 3
    post.author_id.should.equal 1
    post.text.should.equal 'Third post.'

    no_post = @m_post.s1( "SELECT * FROM posts WHERE 1+1 = 3" )
    no_post.should.be.nil
  end

  it 'is Enumerable' do
    should.not.raise do
      @m_author.each { |a| }
      names = @m_author.map { |a| a.name }
      names.find { |name| name == 'author1' }.should.not.be.nil
      names.find { |name| name == 'author2' }.should.not.be.nil
      names.find { |name| name == 'author3' }.should.not.be.nil
      names.find { |name| name == 'author99' }.should.be.nil
    end
    authors = []
    @m_author.each do |a|
      authors << a
    end
    authors.find { |a| a.name == 'author1' }.should.not.be.nil
    authors.find { |a| a.name == 'author2' }.should.not.be.nil
    authors.find { |a| a.name == 'author3' }.should.not.be.nil
    authors.find { |a| a.name == 'author99' }.should.be.nil
  end

  it 'provides a means to update records referred to by primary key value' do
    new_text = 'Some new text.'

    p2 = @m_post[ 2 ]
    p2.text.should.not.equal new_text
    @m_post.update_one( 2, { :text => new_text } )
    p2_ = @m_post[ 2 ]
    p2_.text.should.equal new_text

    row = @m_mcpk[ 1, 1 ]
    row.val.should.not.equal new_text
    @m_mcpk.update_one( 1, 1, { :val => new_text } )
    row = @m_mcpk[ 1, 1 ]
    row.val.should.equal new_text

    row = @m_mcpk[ 3, 4 ]
    row.val.should.not.equal new_text
    @m_mcpk.update_one( 3, 4, { :val => new_text } )
    row = @m_mcpk[ 3, 4 ]
    row.val.should.equal new_text

    reset_data
  end

  it 'provides a means to update records referred to by a value hash' do
    new_text = 'This is some new text.'

    posts = @m_post.where( :author_id => 1 )
    posts.size.should.equal 2
    posts.find_all { |p| p.text == new_text }.should.be.empty

    @m_post.update(
      { :author_id => 1 },
      { :text => new_text }
    )

    posts_ = @m_post.where( :author_id => 1 )
    posts_.size.should.equal 2
    posts_.find_all { |p| p.text == new_text }.should.equal posts_

    reset_data
  end

  it 'provides a means to update records specified by a raw WHERE clause' do
    new_text = 'This is some new text.'

    posts = @m_post.where( :author_id => 1 )
    posts.size.should.equal 2
    posts.find_all { |p| p.text == new_text }.should.be.empty

    @m_post.update(
      "author_id < 2",
      { :text => new_text }
    )

    posts_ = @m_post.where( :author_id => 1 )
    posts_.size.should.equal 2
    posts_.find_all { |p| p.text == new_text }.should.equal posts_

    reset_data
  end

  it 'after creation, executes code provided in an after_create hook' do
    class Author < M4DBI::Model( :authors )
      after_create do |author|
        $test = 2
        author.name = 'different name'
      end
    end
    $test.should.not.equal 2
    a = Author.create(name: 'theauthor')
    $test.should.equal 2
    a.name.should.equal 'different name'

    class Post < M4DBI::Model( :posts ); end
    class Author < M4DBI::Model( :authors )
      after_create do |author|
        Post.create(author_id: author.id, text: 'foobar')
      end
    end
    n = Post.count
    a = Author.create(name: 'theauthor')
    Post.count.should == n+1
  end

  it 'provides a means to remove all after_create hooks' do
    class Author < M4DBI::Model( :authors )
      after_create do |author|
        $test = 'remove after_create'
      end
    end
    class Author < M4DBI::Model( :authors )
      remove_after_create_hooks
    end
    $test.should.not.equal 'remove after_create'
    a = Author.create(name: 'theauthor')
    $test.should.not.equal 'remove after_create'
  end
end

describe 'A created M4DBI::Model subclass instance' do
  before do
    @m_mc = Class.new( M4DBI::Model( :many_col_table ) )
    @m_author = Class.new( M4DBI::Model( :authors ) )
    @m_post = Class.new( M4DBI::Model( :posts ) )
    @m_conflict = Class.new( M4DBI::Model( :conflicting_cols ) )
  end

  it 'provides read access to fields via identically-named readers' do
    mc = @m_mc.create(
      :c3 => 3,
      :c4 => 4
    )
    mc.should.not.be.nil
    should.not.raise do
      mc[ 'id' ]
      mc.c1
      mc.c2
      mc.c5
    end
    mc[ 'id' ].should.not.be.nil
    mc.c3.should.equal 3
    mc.c4.should.equal 4
  end

  it 'provides write access to fields via identically-named writers' do
    mc = @m_mc.create(
      :c3 => 30,
      :c4 => 40
    )
    mc.should.not.be.nil
    mc.c1 = 10
    mc.c2 = 20
    mc.c1.should.equal 10
    mc.c2.should.equal 20
    mc.c3.should.equal 30
    mc.c4.should.equal 40
    id_ = mc[ 'id' ]
    id_.should.not.be.nil

    mc_ = @m_mc[ id_ ]
    mc_[ 'id' ].should.equal id_
    mc_.c1.should.equal 10
    mc_.c2.should.equal 20
    mc_.c3.should.equal 30
    mc_.c4.should.equal 40
  end

  it 'provides read access to fields via Hash-like syntax' do
    mc = @m_mc.create(
      :c3 => 3,
      :c4 => 4
    )
    mc.should.not.be.nil
    mc[ 'id' ].should.not.be.nil
    mc[ 'c3' ].should.equal 3
    mc[ 'c4' ].should.equal 4
    mc[ :id ].should.not.be.nil
    mc[ :c3 ].should.equal 3
    mc[ :c4 ].should.equal 4
  end

  it 'provides write access to fields via Hash-like syntax' do
    mc = @m_mc.create(
      :c3 => 30,
      :c4 => 40
    )
    mc.should.not.be.nil
    mc[ 'c1' ] = 10
    mc[ 'c2' ] = 20
    mc[ 'c1' ].should.equal 10
    mc[ 'c2' ].should.equal 20
    mc[ 'c3' ].should.equal 30
    mc[ 'c4' ].should.equal 40
    id_ = mc[ 'id' ]
    id_.should.not.be.nil

    mc_ = @m_mc[ id_ ]
    mc_[ 'id' ].should.equal id_
    mc_[ 'c1' ].should.equal 10
    mc_[ 'c2' ].should.equal 20
    mc_[ 'c3' ].should.equal 30
    mc_[ 'c4' ].should.equal 40
  end

  it 'provides alternative accessors for columns that collide with Object methods' do
    mc = @m_conflict.create(
      :c1 => 123,
      :class => 'Mammalia',
      :dup => false
    )
    mc.should.not.be.nil
    should.not.raise do
      mc[ 'id' ]
      mc.class
      mc.class_
      mc.dup
      mc.dup_
    end
    mc[ 'id' ].should.not.be.nil
    mc.c1.should.equal 123
    mc.class.should.equal @m_conflict
    mc.class_.should.equal 'Mammalia'
    mc.dup.should.equal mc
  end

  it 'maintains Hash key equality across different fetches' do
    h = Hash.new
    a = @m_author[ 1 ]
    h[ a ] = 123
    a_ = @m_author[ 1 ]
    h[ a_].should.equal 123
    a.should.equal a_

    a2 = @m_author[ 2 ]
    h[ a2 ].should.be.nil
    a2.should.not.equal a

    h[ a2 ] = 456
    h[ a ].should.equal 123
    h[ a_ ].should.equal 123

    a2_ = @m_author[ 2 ]
    h[ a2_ ].should.equal 456
    a2.should.equal a2_
  end

  it 'maintains Hash key distinction for different Model subclasses' do
    h = Hash.new
    a = @m_author[ 1 ]
    h[ a ] = 123
    p = @m_post[ 1 ]
    h[ p ] = 456
    h[ p ].should.equal 456

    a_ = @m_author[ 1 ]
    h[ a_ ].should.equal 123
  end

  it 'after setting data, executes code provided in an after_update hook' do
    class Author < M4DBI::Model( :authors )
      after_update do |author|
        $test = 3
        author.name = 'different name'
      end
    end

    $test.should.not.equal 3
    a = Author.create(name: 'theauthor')
    $test.should.not.equal 3
    a.set  name: 'foobar'
    $test.should.equal 3
    a.name.should.equal 'different name'

    $test = nil
    a = Author.create(name: 'theauthor')
    $test.should.not.equal 3
    a.name = 'foobar'
    $test.should.equal 3
    a.name.should.equal 'different name'
  end

  it 'provides a means to remove all after_update hooks' do
    class Author < M4DBI::Model( :authors )
      after_update do |author|
        $test = 'remove after_update'
      end
    end
    class Author < M4DBI::Model( :authors )
      remove_after_update_hooks
    end
    $test.should.not.equal 'remove after_update'
    a = Author.create(name: 'theauthor')
    a.name = 'another author'
    $test.should.not.equal 'remove after_update'
  end

  it 'provides a means to remove all before_delete hooks' do
    class Author < M4DBI::Model( :authors )
      before_delete do |author|
        $test = 'remove before_update'
      end
    end
    class Author < M4DBI::Model( :authors )
      remove_before_delete_hooks
    end
    $test.should.not.equal 'remove before_delete'
    a = Author.create(name: 'theauthor')
    a.delete
    $test.should.not.equal 'remove before_delete'
  end

  it 'provides a means to remove all after_delete hooks' do
    class Author < M4DBI::Model( :authors )
      after_delete do |author|
        $test = 'remove after_delete'
      end
    end
    class Author < M4DBI::Model( :authors )
      remove_after_delete_hooks
    end
    $test.should.not.equal 'remove after_delete'
    a = Author.create(name: 'theauthor')
    a.delete
    $test.should.not.equal 'remove after_delete'
  end
end

describe 'A found M4DBI::Model subclass instance' do
  before do
    @m_author = Class.new( M4DBI::Model( :authors ) )
    @m_post = Class.new( M4DBI::Model( :posts ) )
    @m_mc = Class.new( M4DBI::Model( :many_col_table ) )
    @m_nipk = Class.new( M4DBI::Model( :non_id_pk, :pk => [ :str ] ) )
    @m_mcpk = Class.new( M4DBI::Model( :mcpk, :pk => [ :kc1, :kc2 ] ) )
  end

  it 'provides access to primary key value' do
    a = @m_author[ 1 ]
    a.pk.should.equal 1

    p = @m_post[ 3 ]
    p.pk.should.equal 3

    r = @m_mcpk[ 1, 1 ]
    r.pk.should.equal [ 1, 1 ]

    r = @m_mcpk[ { :kc1 => 3, :kc2 => 4 } ]
    r.pk.should.equal [ 3, 4 ]
  end

  it 'provides read access to fields via identically-named readers' do
    p = @m_post[ 2 ]

    should.not.raise( NoMethodError ) do
      p[ 'id' ]
      p.author_id
      p.text
    end

    should.raise( NoMethodError ) do
      p.foobar
    end

    p[ 'id' ].should.equal 2
    p.author_id.should.equal 2
    p.text.should.equal 'Second post.'
  end

  it 'provides write access to fields via identically-named writers' do
    the_new_text = 'Here is some new text.'

    p2 = @m_post[ 2 ]

    p3 = @m_post[ 3 ]
    p3.text = the_new_text
    p3.text.should.equal the_new_text

    p3_ = @m_post[ 3 ]
    p3_.text.should.equal the_new_text

    # Shouldn't change other rows
    p2_ = @m_post[ 2 ]
    p2_.text.should.equal p2.text

    mc1 = @m_mc.create(
      :id => 1,
      :c1 => 2
    )
    mc1.c1.should.equal 2
    mc1.c1 = nil
    mc1.c1.should.be.nil
    mc1_ = @m_mc[ 1 ]
    mc1_.c1.should.be.nil

    reset_data
  end

  it 'maintains identity across multiple DB hits' do
    px = @m_post[ 1 ]
    py = @m_post[ 1 ]

    px.should.equal py
  end

  it 'provides multi-column writability via Model#set' do
    p = @m_post[ 1 ]
    the_new_text = 'The 3rd post.'
    p.set(
      :author_id => 2,
      :text => the_new_text
    )
    p.author_id.should.equal 2
    p.text.should.equal the_new_text

    p_ = @m_post[ 1 ]
    p_.author_id.should.equal 2
    p_.text.should.equal the_new_text

    mc1 = @m_mc.create(
      :id => 1,
      :c1 => 2,
      :c2 => 3
    )
    mc1.set(
      :c1 => nil,
      :c2 => 4
    )
    mc1.c1.should.be.nil
    mc1.c2.should.equal 4
    mc1_ = @m_mc[ 1 ]
    mc1_.c1.should.be.nil
    mc1_.c2.should.equal 4

    reset_data
  end

  it 'is deleted by #delete' do
    p = @m_post[ 3 ]
    p.should.not.be.nil
    successfully_deleted = p.delete
    successfully_deleted.should.be.true
    @m_post[ 3 ].should.be.nil

    o = @m_nipk[ 'one' ]
    o.should.not.be.nil
    successfully_deleted = o.delete
    successfully_deleted.should.be.true
    @m_nipk[ 'one' ].should.be.nil

    reset_data
  end

  it 'before deletion, executes code provided in an before_delete hook' do
    class Author < M4DBI::Model( :authors )
      before_delete do |author|
        $test = author.name
      end
    end
    $test.should.not.equal 'theauthor'
    a = Author.create(name: 'theauthor')
    $test.should.not.equal 'theauthor'
    a.delete
    $test.should.equal 'theauthor'
  end

  it 'after deletion, executes code provided in an after_delete hook' do
    class Author < M4DBI::Model( :authors )
      after_delete do |author|
        $test = 4
      end
    end
    $test.should.not.equal 4
    a = Author.create(name: 'theauthor')
    $test.should.not.equal 4
    a.delete
    $test.should.equal 4
  end

  it 'does nothing on #save' do
    p = @m_post[ 1 ]
    should.not.raise do
      p.save
    end
  end

  it 'does nothing on #save!' do
    p = @m_post[ 1 ]
    should.not.raise do
      p.save!
    end
  end

  it 'provides a Hash representation' do
    record = @m_mc.create( id: 12, c1: 50, c2: 44  )
    record.to_h.should.equal( {
      'id' => 12,
      'c1' => 50,
      'c2' => 44,
      'c3' => nil,
      'c4' => nil,
      'c5' => nil,
      'ts' => nil,
    } )
  end
end

describe 'M4DBI::Model (relationships)' do
  before do
    @m_author = Class.new( M4DBI::Model( :authors ) )
    @m_post = Class.new( M4DBI::Model( :posts ) )
    @m_fan = Class.new( M4DBI::Model( :fans ) )
  end

  it 'facilitates relating one to many, providing read access' do
    M4DBI::Model.one_to_many( @m_author, @m_post, :posts, :author, :author_id )
    a = @m_author[ 1 ]
    a.posts.should.not.be.empty
    p = @m_post[ 3 ]
    p.author.should.not.be.nil
    p.author[ 'id' ].should.equal 1
  end

  it 'facilitates relating one to many, allowing one of the many to set its one' do
    M4DBI::Model.one_to_many(
      @m_author, @m_post, :posts, :author, :author_id
    )
    p = @m_post[ 3 ]
    p.author.should.not.be.nil
    p.author[ 'id' ].should.equal 1
    p.author = @m_author.create( :id => 4, :name => 'author4' )
    p_ = @m_post[ 3 ]
    p_.author[ 'id' ].should.equal 4

    reset_data
  end

  it 'facilitates relating many to many, providing read access' do
    M4DBI::Model.many_to_many(
      @m_author, @m_fan, :authors_liked, :fans, :authors_fans, :author_id, :fan_id
    )
    a1 = @m_author[ 1 ]
    a2 = @m_author[ 2 ]
    f2 = @m_fan[ 2 ]
    f3 = @m_fan[ 3 ]

    a1f = a1.fans
    a1f.should.not.be.nil
    a1f.should.not.be.empty
    a1f.size.should.equal 2
    a1f[ 0 ].class.should.equal @m_fan
    a1f.find { |f| f.name == 'fan1' }.should.be.nil
    a1f.find { |f| f.name == 'fan2' }.should.not.be.nil
    a1f.find { |f| f.name == 'fan3' }.should.not.be.nil

    a2f = a2.fans
    a2f.should.not.be.nil
    a2f.should.not.be.empty
    a2f.size.should.equal 2
    a2f[ 0 ].class.should.equal @m_fan
    a2f.find { |f| f.name == 'fan1' }.should.be.nil
    a2f.find { |f| f.name == 'fan3' }.should.not.be.nil
    a2f.find { |f| f.name == 'fan4' }.should.not.be.nil

    f2a = f2.authors_liked
    f2a.should.not.be.nil
    f2a.should.not.be.empty
    f2a.size.should.equal 1
    f2a[ 0 ].class.should.equal @m_author
    f2a[ 0 ].name.should.equal 'author1'

    f3a = f3.authors_liked
    f3a.should.not.be.nil
    f3a.should.not.be.empty
    f3a.size.should.equal 2
    f3a.find { |a| a.name == 'author1' }.should.not.be.nil
    f3a.find { |a| a.name == 'author2' }.should.not.be.nil
    f3a.find { |a| a.name == 'author3' }.should.be.nil

    @m_author[ 3 ].fans.should.be.empty
    @m_fan[ 5 ].authors_liked.should.be.empty
  end
end
