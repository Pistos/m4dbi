class Hash
  # Takes an optional block to provide a single "field = ?" type subclause
  # for each key-value pair.
  def to_clause( join_string )
    # The clause items and the values have to be in the same order.
    keys_ = keys
    if block_given?
      mapping = keys_.map { |field| yield field }
    else
      mapping = keys_.map { |field| "#{field} = ?" }
    end
    clause = mapping.join( join_string )
    values_ = keys_.map { |key|
      self[ key ]
    }
    values_.compact!
    [ clause, values_ ]
  end
  
  def to_where_clause
    to_clause( " AND " ) { |field|
      if self[ field ].nil?
        "#{field} IS NULL"
      else
        "#{field} = ?"
      end
    }
  end
  
  def to_set_clause
    to_clause( ", " )
  end
end