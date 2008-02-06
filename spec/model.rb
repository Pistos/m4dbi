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
  
  it 'should provide hash-like single-record access by primary key' do
    o = @m_author[ 1 ]
    o.should.not.equal nil
    o.name.should == 'author1'
    
    o = @m_author[ 2 ]
    o.should.not.equal nil
    o.name.should == 'author2'
  end
  
  it 'should provide multi-record access via #where' do
    posts = @m_post.where(
      :author_id => 1
    )
    posts.should.not.equal nil
    posts.should.not.be.empty
    posts.size.should == 2
    posts[ 0 ].class.should == @m_post
      
    sorted_posts = posts.sort { |p1,p2|
      p1._id <=> p2._id
    }
    p = sorted_posts.first
    p.text.should == 'First post.'
  end
end
