require File.join(File.dirname(__FILE__), 'helper')

$dbh = connect_to_spec_database
reset_data

describe 'M4DBI::Collection' do
  before do
    @m_author = Class.new( M4DBI::Model( :authors ) )
    @m_post = Class.new( M4DBI::Model( :posts ) )

    M4DBI::Model.one_to_many(
      @m_author, @m_post, :posts, :author, :author_id
    )
  end

  it 'accepts additions' do
    num_posts = @m_post.count

    a = @m_author[ 1 ]
    the_text = 'A new post.'

    num_posts_of_author = a.posts.count

    # Insert without auto-incrementing primary key specified
    # Try at least as many times as there were records in the DB,
    # because the sequence used for the IDs is independent of
    # the actual ID values in the DB for some RDBMSes.
    num_posts.times do
      begin
        a.posts << { :text => the_text }
        break  # Stop on success
      rescue Exception => e
        if e.message !~ /duplicate/
          raise e
        end
      end
    end

    a.posts.count.should.equal num_posts_of_author + 1

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
