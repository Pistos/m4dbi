require 'spec/helper'

describe 'Hash' do
  it 'is convertible to an SQL subclause and matching value Array' do
    h = {
      :a => 2,
      :b => 'foo',
      :abc => Time.now,
      :xyz => 9.02,
    }
    clause, values = h.to_clause( " AND " )
    where_clause, where_values = h.to_where_clause
    
    s = "a = ? AND b = ? AND abc = ? AND xyz = ?"
    clause.length.should.equal s.length
    where_clause.length.should.equal s.length
    
    h.each do |key,value|
      clause.should.match /#{key} = ?/
      where_clause.should.match /#{key} = ?/
      values.find { |v| v == value }.should.not.be.nil
      where_values.find { |v| v == value }.should.not.be.nil
    end
    values.size.should.equal h.keys.size
    where_values.size.should.equal h.keys.size
  end
end