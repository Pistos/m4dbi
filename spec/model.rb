require 'spec/helper'

# See test-schema.sql and test-data.sql

def reset_data( dbh = $dbh, datafile = "test-data.sql" )
  dir = File.dirname( __FILE__ )
  File.read( "#{dir}/#{datafile}" ).split( /;/ ).each do |command|
    dbh.do( command )
  end
end

describe 'DBI::Model' do
  it 'raises an exception when trying to define a model before connecting to a database' do
    dbh = DBI::DatabaseHandle.last_handle
    if dbh and dbh.respond_to? :disconnect
      dbh.disconnect
    end
    should.raise do
      @m_author = Class.new( DBI::Model( :authors ) )
    end
  end
end

$dbh = DBI.connect( "DBI:Pg:m4dbi", "m4dbi", "m4dbi" )
reset_data

class ManyCol < DBI::Model( :many_col_table )
  def inc
    self.c1 = c1 + 10
  end
  
  def dec
    self.c1 = c1 - 10
  end
end

describe 'A DBI::Model subclass' do
  before do
    # Here we subclass DBI::Model.
    # This is nearly equivalent to the typical "ChildClassName < ParentClassName"
    # syntax, but allows us to refer to the class in our specs.
    @m_author = Class.new( DBI::Model( :authors ) )
    @m_post = Class.new( DBI::Model( :posts ) )
    @m_empty = Class.new( DBI::Model( :empty_table ) )
    @m_mc = Class.new( DBI::Model( :many_col_table ) )
    class Author < DBI::Model( :authors ); end
  end
  
  it 'can be defined' do
    @m_author.should.not.be.nil
    @m_post.should.not.be.nil
  end
  
  it 'maintains identity across different inheritances' do
    should.not.raise do
      class Author < DBI::Model( :authors ); end
      class Author < DBI::Model( :authors ); end
    end
  end
  
  it 'maintains member methods across redefinitions' do
    class Author < DBI::Model( :authors )
      def method1; 1; end
    end
    class Author < DBI::Model( :authors )
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
      original_handle = DBI::DatabaseHandle.last_handle
      
      class Author < DBI::Model( :authors ); end
        
      dbh = DBI.connect( "DBI:Pg:m4dbi", "m4dbi", "m4dbi" )
      new_handle = DBI::DatabaseHandle.last_handle
      new_handle.should.equal dbh
      new_handle.should.not.equal original_handle
      
      class Author < DBI::Model( :authors ); end
    end
  end
  
  it 'maintains distinction from models of the same name in different databases' do
    begin
      a1 = @m_author[ 1 ]
      a1.should.not.be.nil
      a1.name.should.equal 'author1'
      
      dbh = DBI.connect( "DBI:Pg:m4dbi2", "m4dbi", "m4dbi" )
      reset_data( dbh, "test-data2.sql" )
      
      @m_author2 = Class.new( DBI::Model( :authors ) )
      
      @m_author2[ 1 ].should.be.nil
      a11 = @m_author2[ 11 ]
      a11.should.not.be.nil
      a11.name.should.equal 'author11'
      
      a2 = @m_author[ 2 ]
      a2.should.not.be.nil
      a2.name.should.equal 'author2'
    ensure
      # Clean up handles for later specs
      dbh.disconnect if dbh and dbh.connected?
      DBI.connect( "DBI:Pg:m4dbi", "m4dbi", "m4dbi" )
    end
  end
  
  it 'raises an exception when creating with invalid arguments' do
    should.raise( DBI::Error ) do
      @m_author.new nil
    end
    should.raise( DBI::Error ) do
      @m_author.new 2
    end
    should.raise( DBI::Error ) do
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
  end
  
  it 'provides hash-like single-record access via #[ field_hash ]' do
    o = @m_author[ :name => 'author1' ]
    o.should.not.be.nil
    o.class.should.equal @m_author
    o.id.should.equal 1
    
    o = @m_post[ :author_id => 1 ]
    o.should.not.be.nil
    o.class.should.equal @m_post
    o.text.should.equal 'First post.'
  end
  
  it 'returns nil from #[] when no record is found' do
    o = @m_author[ 999 ]
    o.should.be.nil
    
    o = @m_author[ :name => 'foobar' ]
    o.should.be.nil
  end
  
  it 'provides multi-record access via #where( Hash )' do
    posts = @m_post.where(
      :author_id => 1
    )
    posts.should.not.be.nil
    posts.should.not.be.empty
    posts.size.should.equal 2
    posts[ 0 ].class.should.equal @m_post
      
    sorted_posts = posts.sort { |p1,p2|
      p1._id <=> p2._id
    }
    p = sorted_posts.first
    p.text.should.equal 'First post.'
  end    
    
  it 'provides multi-record access via #where( String )' do
    posts = @m_post.where( "id < 3" )
    posts.should.not.be.nil
    posts.should.not.be.empty
    posts.size.should.equal 2
    posts[ 0 ].class.should.equal @m_post
      
    sorted_posts = posts.sort { |p1,p2|
      p2._id <=> p1._id
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
  end
  
  it 'provides single-record access via #one_where( String )' do
    post = @m_post.one_where( "text LIKE '%Third%'" )
    post.should.not.be.nil
    post.class.should.equal @m_post
    post.id.should.equal 3
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
    
    rows[ 0 ].id.should.equal 1
    rows[ 0 ].name.should.equal 'author1'
    rows[ 1 ].id.should.equal 2
    rows[ 1 ].name.should.equal 'author2'
  end
  
  it 'returns an empty array when #all is called on an empty table' do
    rows = @m_empty.all
    rows.should.not.be.nil
    rows.should.be.empty
  end
  
  it 'returns any single record from #one' do
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
  
  it 'provides a means to create new records via #create( Hash )' do
    a = @m_author.create(
      :id => 9,
      :name => 'author9'
    )
    a.should.not.be.nil
    a.class.should.equal @m_author
    a.id.should.equal 9
    a.should.respond_to :name
    a.should.not.respond_to :no_column_by_this_name
    a.name.should.equal 'author9'
    
    a_ = @m_author[ 9 ]
    a_.should.not.be.nil
    a_.should.equal a
    a_.name.should.equal 'author9'
    
    reset_data
  end
  
  it 'provides a means to create new records via #create { |r| }' do
    should.raise( NoMethodError ) do
      @m_author.create { |rec|
        rec.no_such_column = 'foobar'
      }
    end
    
    a = @m_author.create { |rec|
      rec.id = 9
      rec.name = 'author9'
    }
    a.should.not.be.nil
    a.class.should.equal @m_author
    a.id.should.equal 9
    a.name.should.equal 'author9'
    
    a_ = @m_author[ 9 ]
    a_.should.equal a
    a_.name.should.equal 'author9'
    
    m = nil
    should.not.raise do
      m = @m_mc.create { |rec|
        rec.id = 1
        rec.c2 = 7
        rec.c3 = 8
      }
    end
    m_ = @m_mc[ 1 ]
    m_.id.should.equal 1
    m_.c1.should.be.nil
    m_.c2.should.equal 7
    m_.c3.should.equal 8
    m_.c4.should.be.nil
    m_.c5.should.be.nil
    
    reset_data
  end
  
  it 'returns a record via #find_or_create( Hash )' do
    n = @m_author.count
    a = @m_author.find_or_create(
      :id => 1,
      :name => 'author1'
    )
    a.should.not.be.nil
    a.class.should.equal @m_author
    a.id.should.equal 1
    a.should.respond_to :name
    a.should.not.respond_to :no_column_by_this_name
    a.name.should.equal 'author1'
    @m_author.count.should.equal n
  end
  
  it 'creates a record via #find_or_create( Hash )' do
    n = @m_author.count
    a = @m_author.find_or_create(
      :id => 9,
      :name => 'author9'
    )
    a.should.not.be.nil
    a.class.should.equal @m_author
    a.id.should.equal 9
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
    
    posts[ 0 ].id.should.equal 1
    posts[ 0 ].text.should.equal 'First post.'
    posts[ 1 ].id.should.equal 3
    posts[ 1 ].text.should.equal 'Third post.'
    
    no_posts = @m_post.s( "SELECT * FROM posts WHERE FALSE" )
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
    
    post.id.should.equal 3
    post.author_id.should.equal 1
    post.text.should.equal 'Third post.'
    
    no_post = @m_post.s1( "SELECT * FROM posts WHERE FALSE" )
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
    new_text = 'This is some new text.'
    
    p2 = @m_post[ 2 ]
    p2.text.should.not.equal new_text
    
    @m_post.update_one( 2, { :text => new_text } )
    
    p2_ = @m_post[ 2 ]
    p2_.text.should.equal new_text
    
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
end

describe 'A created DBI::Model subclass instance' do
  before do
    @m_mc = Class.new( DBI::Model( :many_col_table ) )
    @m_author = Class.new( DBI::Model( :authors ) )
    @m_post = Class.new( DBI::Model( :posts ) )
  end
  
  it 'provides read access to fields via identically-named readers' do
    mc = @m_mc.create(
      :c3 => 3,
      :c4 => 4
    )
    mc.should.not.be.nil
    should.not.raise do
      mc.id
      mc.c1
      mc.c2
      mc.c5
    end
    mc.id.should.not.be.nil
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
    id_ = mc.id
    id_.should.not.be.nil
    
    mc_ = @m_mc[ id_ ]
    mc_.id.should.equal id_
    mc_.c1.should.equal 10
    mc_.c2.should.equal 20
    mc_.c3.should.equal 30
    mc_.c4.should.equal 40
  end
  
  it 'maintains Hash key equality across different fetches' do
    h = Hash.new
    a = @m_author[ 1 ]
    h[ a ] = 123
    a_ = @m_author[ 1 ]
    h[ a_].should.equal 123
    
    a2 = @m_author[ 2 ]
    h[ a2 ].should.be.nil
    
    h[ a2 ] = 456
    h[ a ].should.equal 123
    h[ a_ ].should.equal 123
    
    a2_ = @m_author[ 2 ]
    h[ a2_ ].should.equal 456
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
end

describe 'A found DBI::Model subclass instance' do
  before do
    @m_author = Class.new( DBI::Model( :authors ) )
    @m_post = Class.new( DBI::Model( :posts ) )
  end
  
  it 'provides access to primary key value' do
    a = @m_author[ 1 ]
    a.pk.should.equal 1
    
    p = @m_post[ 3 ]
    p.pk.should.equal 3
  end
  
  it 'provides read access to fields via identically-named readers' do
    p = @m_post[ 2 ]
    
    should.not.raise( NoMethodError ) do
      p.id
      p.author_id
      p.text
    end
    
    should.raise( NoMethodError ) do
      p.foobar
    end
    
    p.id.should.equal 2
    p.author_id.should.equal 2
    p.text.should.equal 'Second post.'
  end
  
  it 'provides write access to fields via identically-named writers' do
    the_new_text = 'Here is some new text.'
    
    p2 = @m_post[ 2 ]
    
    p3 = @m_post[ 3 ]
    p3.text = the_new_text
    
    p3_ = @m_post[ 3 ]
    p3_.text.should.equal the_new_text
    
    # Shouldn't change other rows
    p2_ = @m_post[ 2 ]
    p2_.text.should.equal p2.text
    
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
    
    p_ = @m_post[ 1 ]
    p_.author_id.should.equal 2
    p_.text.should.equal the_new_text
    
    reset_data
  end
  
  it 'is deleted by #delete' do
    p = @m_post[ 3 ]
    p.should.not.be.nil
    successfully_deleted = p.delete
    successfully_deleted.should.be.true
    @m_post[ 3 ].should.be.nil
    
    reset_data
  end

  it 'does nothing on #save' do
    p = @m_post[ 1 ]
    should.not.raise do
      p.save
    end
  end
  
  it 'allows a field to be incremented' do
    mc = ManyCol.create( :c1 => 50 )
    should.not.raise do
      mc.inc
    end
  end
  it 'allows a field to be decremented' do
    mc = ManyCol.create( :c1 => 50 )
    should.not.raise do
      mc.dec
    end
  end
end

describe 'DBI::Model (relationships)' do
  before do
    @m_author = Class.new( DBI::Model( :authors ) )
    @m_post = Class.new( DBI::Model( :posts ) )
    @m_fan = Class.new( DBI::Model( :fans ) )
  end
  
  it 'facilitates relating one to many, providing read access' do
    DBI::Model.one_to_many( @m_author, @m_post, :posts, :author, :author_id )
    a = @m_author[ 1 ]
    a.posts.should.not.be.empty
    p = @m_post[ 3 ]
    p.author.should.not.be.nil
    p.author.id.should.equal 1
  end
  
  it 'facilitates relating one to many, allowing one of the many to set its one' do
    DBI::Model.one_to_many(
      @m_author, @m_post, :posts, :author, :author_id
    )
    p = @m_post[ 3 ]
    p.author.should.not.be.nil
    p.author.id.should.equal 1
    p.author = @m_author.create( :id => 4, :name => 'author4' )
    p_ = @m_post[ 3 ]
    p_.author.id.should.equal 4
    
    reset_data
  end
  
  it 'facilitates relating many to many, providing read access' do
    DBI::Model.many_to_many(
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

describe 'DBI::Collection' do
  before do
    @m_author = Class.new( DBI::Model( :authors ) )
    @m_post = Class.new( DBI::Model( :posts ) )
    @m_fan = Class.new( DBI::Model( :fans ) )
    
    DBI::Model.one_to_many(
      @m_author, @m_post, :posts, :author, :author_id
    )
  end
  
  it 'accepts additions' do
    a = @m_author[ 1 ]
    the_text = 'A new post.'
    a.posts << { :text => the_text }
    p = a.posts.find { |p| p.text == the_text }
    p.should.not.be.nil
    p.author.should.equal a
    
    a_ = @m_author[ 1 ]
    a_.posts.find { |p| p.text == the_text }.should.not.be.nil
    
    reset_data
  end
  
  it 'facilitates single record deletions' do
    a = @m_author[ 1 ]
    posts = a.posts
    n = posts.size
    p = posts[ 0 ]
    
    posts.delete( p ).should.be.true
    a.posts.size.should.equal( n - 1 )
    posts.find { |p_| p_ == p }.should.be.nil
    
    reset_data
  end
    
  it 'facilitates multi-record deletions' do
    a = @m_author[ 1 ]
    posts = a.posts
    n = posts.size
    posts.delete( :text => 'Third post.' ).should.equal 1
    a.posts.size.should.equal( n - 1 )
    posts.find { |p| p.text == 'Third post.' }.should.be.nil
    posts.find { |p| p.text == 'First post.' }.should.not.be.nil
    
    reset_data
  end
  
  it 'facilitates table-wide deletion' do
    a = @m_author[ 1 ]
    a.posts.should.not.be.empty
    a.posts.clear.should.be > 0
    a.posts.should.be.empty
    
    reset_data
  end
end