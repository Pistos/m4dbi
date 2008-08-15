require 'spec/helper'

describe 'Hash' do
  it 'is convertible to an SQL subclause and matching value Array' do
    h = {
      :a => 2,
      :b => 'foo',
      :the_nil => nil,
      :abc => Time.now,
      :xyz => 9.02,
    }
    clause, values = h.to_clause( " AND " )
    where_clause, where_values = h.to_where_clause
    
    str = "a = ? AND b = ? AND the_nil = ? AND abc = ? AND xyz = ?"
    where_str = "a = ? AND b = ? AND the_nil IS NULL AND abc = ? AND xyz = ?"
    clause.length.should.equal str.length
    where_clause.length.should.equal where_str.length
    
    h.each_key do |key|
      clause.should.match /#{key} = ?/
      if h[ key ].nil?
        where_clause.should.match /#{key} IS NULL/
      else
        where_clause.should.match /#{key} = ?/
      end
    end
    
    values.should.equal h.values
    where_values.should.equal h.values.compact
  end
end