require 'spec/helper'

$dbh = DBI.connect( "DBI:Pg:m4dbi", "m4dbi", "m4dbi" )
# See test-schema.sql and test-data.sql

describe 'DBI::Model' do
  before do
    @m_author = Class.new(
      DBI::Model( :authors )
    )
    @m_post = Class.new(
      DBI::Model( :posts )
    )
  end
  
  it 'should be defined' do
    @m_author.should.not.equal nil
    @m_post.should.not.equal nil
  end
  
  it 'should provide hash-like single-record access via #[ primary_key_value ]' do
    o = @m_author[ 1 ]
    o.should.not.equal nil
    o.name.should == 'author1'
    o.class.should.equal @m_author
    
    o = @m_author[ 2 ]
    o.should.not.equal nil
    o.name.should == 'author2'
    o.class.should.equal @m_author
  end
  
  it 'should provide multi-record access via #where( Hash )' do
    posts = @m_post.where(
      :author_id => 1
    )
    posts.should.not.equal nil
    posts.should.not.be.empty
    posts.size.should == 2
    posts[ 0 ].class.should.equal @m_post
      
    sorted_posts = posts.sort { |p1,p2|
      p1._id <=> p2._id
    }
    p = sorted_posts.first
    p.text.should == 'First post.'
  end    
    
  it 'should provide multi-record access via #where( String )' do
    posts = @m_post.where( "id < 3" )
    posts.should.not.equal nil
    posts.should.not.be.empty
    posts.size.should == 2
    posts[ 0 ].class.should.equal @m_post
      
    sorted_posts = posts.sort { |p1,p2|
      p2._id <=> p1._id
    }
    p = sorted_posts.first
    p.text.should == 'Second post.'
  end
  
  it 'should provide access to primary key' do
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
  end
end
