class Hash
  def to_clause( join_string )
    # The clause items and the values have to be in the same order.
    keys_ = keys
    clause = keys_.map { |field|
      "#{field} = ?"
    }.join( join_string )
    values_ = keys_.map { |key|
      self[ key ]
    }
    [ clause, values_ ]
  end
  
  def to_where_clause
    to_clause( " AND " )
  end
  
  def to_set_clause
    to_clause( ", " )
  end
end