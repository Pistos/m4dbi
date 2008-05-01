require 'spec/helper'

describe 'Hash' do
  it 'is convertible to an SQL subclause and matching value Array' do
    h = {
      :a => 2,
      :b => 'foo',
      :abc => Time.now,
      :xyz => 9.02,
      :the_nil => nil,
    }
    clause, values = h.to_clause( " AND " )
    where_clause, where_values = h.to_where_clause
    
    s = "a = ? AND b = ? AND abc = ? AND xyz = ? AND the_nil IS NULL"
    clause.length.should.equal s.length
    where_clause.length.should.equal s.length
    
    h.each_with_index do |key_value,index|
      key, value = key_value[ 0 ], key_value[ 1 ]
      if value.nil?
        clause.should.match /#{key} IS NULL/
        where_clause.should.match /#{key} IS NULL/
      else
        clause.should.match /#{key} = ?/
        where_clause.should.match /#{key} = ?/
      end
      values[ index ].should.equal value
      where_values[ index ].should.equal value
    end
    values.size.should.equal h.keys.size
    where_values.size.should.equal h.keys.size
  end
end