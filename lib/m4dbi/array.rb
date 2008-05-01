class Array
  def to_placeholders
    map { '?' }.join( ', ' )
  end
end