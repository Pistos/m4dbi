require 'spec/helper'

describe 'Hash' do
  it 'should be convertible to a where subclause and matching value Array' do
    h = {
      :a => 2,
      :b => 'foo',
      :abc => Time.now,
      :xyz => 9.02,
    }
    clause, values = h.to_where_clause
    
    s = "a = ? AND b = ? AND abc = ? AND xyz = ?"
    clause.length.should.equal s.length
    h.each do |key,value|
      clause.should.match /#{key} = ?/
      values.find { |v| v == value }.should.not.be.nil
    end
    values.size.should.equal h.keys.size
  end
end