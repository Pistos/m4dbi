require 'dbi'

class DBI::DatabaseHandle
  def select_column( statement, *bindvars )
    row = select_one( statement, *bindvars )
    if row
      row[ 0 ]
    end
  end
end

class DBI::Row
  def method_missing( method, *args )
    field = method.to_s
    # We shouldn't use by_field directly and test for nil,
    # because nil may be a valid value for the column.
    if @column_names.include?( field )
      by_field field
    else
      field = field.gsub( /(^_)|(_$)/ , '' )
      if @column_names.include?( field )
        by_field field
      else
        super
      end
    end
  end
end