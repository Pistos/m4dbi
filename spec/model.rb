require 'spec/helper'

# See test-schema.sql and test-data.sql

def reset_data
  dir = File.dirname( __FILE__ )
  File.read( "#{dir}/test-data.sql" ).split( /;/ ).each do |command|
    $dbh.do( command )
  end
end

$dbh = DBI.connect( "DBI:Pg:m4dbi", "m4dbi", "m4dbi" )
reset_data

describe 'A DBI::Model subclass' do
  before do
    @m_author = Class.new(
      DBI::Model( :authors )
    )
    @m_post = Class.new(
      DBI::Model( :posts )
    )
    @m_empty = Class.new(
      DBI::Model( :empty_table )
    )
  end
  
  it 'should be defined' do
    @m_author.should.not.be.nil
    @m_post.should.not.be.nil
  end
  
  it 'should provide hash-like single-record access via #[ primary_key_value ]' do
    o = @m_author[ 1 ]
    o.should.not.be.nil
    o.name.should.equal 'author1'
    o.class.should.equal @m_author
    
    o = @m_author[ 2 ]
    o.should.not.be.nil
    o.name.should.equal 'author2'
    o.class.should.equal @m_author
  end
  
  it 'should return nil from #[] when no record found' do
    o = @m_author[ 999 ]
    o.should.be.nil
  end
  
  it 'should provide multi-record access via #where( Hash )' do
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
    
  it 'should provide multi-record access via #where( String )' do
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
  
  it 'should return an empty array from #where when no records found' do
    a = @m_author.where( :id => 999 )
    a.should.be.empty
    
    p = @m_post.where( "text = 'aoeu'" )
    p.should.be.empty
  end
  
  it 'should return all table records via #all' do
    rows = @m_author.all
    rows.should.not.be.nil
    rows.should.not.be.empty
    rows.size.should.equal 2
    
    rows[ 0 ].id.should.equal 1
    rows[ 0 ].name.should.equal 'author1'
    rows[ 1 ].id.should.equal 2
    rows[ 1 ].name.should.equal 'author2'
  end
  
  it 'should return an empty array when #all is called on an empty table' do
    rows = @m_empty.all
    rows.should.not.be.nil
    rows.should.be.empty
  end
  
  it 'should provide a means to create new records via #create( Hash )' do
    a = @m_author.create(
      :id => 3,
      :name => 'author3'
    )
    a.should.not.be.nil
    a.class.should.equal @m_author
    a.id.should.equal 3
    a.should.respond_to :name
    a.should.not.respond_to :no_column_by_this_name
    a.name.should.equal 'author3'
    
    a_ = @m_author[ 3 ]
    a_.should.not.be.nil
    a_.should.equal a
    a_.name.should.equal 'author3'
    
    reset_data
  end
  
  it 'should provide a means to create new records via #create { |r| }' do
    should.raise( NoMethodError ) do
      @m_author.create { |rec|
        rec.no_such_column = 'foobar'
      }
    end
    
    a = @m_author.create { |rec|
      rec.id = 3
      rec.name = 'author3'
    }
    a.should.not.be.nil
    a.class.should.equal @m_author
    a.id.should.equal 3
    a.name.should.equal 'author3'
    
    a_ = @m_author[ 3 ]
    a_.should.equal a
    a_.name.should.equal 'author3'
    
    reset_data
  end
  
  it 'should provide a means to use generic raw SQL to select model instances' do
    posts = @m_post.select_all(
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
  end
end

describe 'A DBI::Model subclass instance' do
  before do
    @m_author = Class.new(
      DBI::Model( :authors )
    )
    @m_post = Class.new(
      DBI::Model( :posts )
    )
  end
  
  it 'should provide access to primary key value' do
    a = @m_author[ 1 ]
    a.pk.should.equal 1
    
    p = @m_post[ 3 ]
    p.pk.should.equal 3
  end
  
  it 'should provide read access to fields via identically-named readers' do
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
  
  it 'should provide write access to fields via identically-named writers' do
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
  
  it 'should maintain identity across multiple DB hits' do
    px = @m_post[ 1 ]
    py = @m_post[ 1 ]
    
    px.should.equal py
  end
  
  it 'should provide multi-column writability via Model#set' do
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
  
  it 'should be deleted by #delete' do
    p = @m_post[ 3 ]
    p.should.not.be.nil
    successfully_deleted = p.delete
    successfully_deleted.should.be.true
    @m_post[ 3 ].should.be.nil
    
    reset_data
  end

end