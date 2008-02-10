require 'spec/helper'

describe 'Hash' do
  it 'should be convertible to a where subclause' do
    h = {
      :a => 2,
      :b => 'foo',
      :abc => Time.now,
      :xyz => 9.02,
    }
    c = h.to_where_clause
    s = "a = ? AND b = ? AND abc = ? AND xyz = ?"
    c.length.should.equal s.length
    h.keys.each do |key|
      c.should.match /#{key} = ?/
    end
  end
end