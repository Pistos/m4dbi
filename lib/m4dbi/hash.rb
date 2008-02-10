class Hash
  
  def to_where_clause
    # The clause items and the values have to be in the same order.
    keys_ = keys
    clause = keys_.map { |field|
      "#{field} = ?"
    }.join( " AND " )
    values_ = keys_.map { |key|
      self[ key ]
    }
    [ clause, values_ ]
  end
end