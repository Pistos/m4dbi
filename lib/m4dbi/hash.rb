class Hash
  def to_where_clause
    keys.map { |field|
      "#{field} = ?"
    }.join( " AND " )
  end
end