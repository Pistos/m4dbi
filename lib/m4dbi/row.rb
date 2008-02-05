require 'dbi'

module DBI
  class Row
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
end
