module DBI
  class Row
    def method_missing( method, *args )
      if method.to_s =~ /^(.+)=$/
        field = $1
        if ! @column_names.include?( field )
          field = convert_alternate_fieldname( field )
        end
        if @column_names.include?( field )
          self[ field ] = args[ 0 ]
        else
          super
        end
      else
        field = method.to_s
        # We shouldn't use by_field directly and test for nil,
        # because nil may be a valid value for the column.
        if ! @column_names.include?( field )
          field = convert_alternate_fieldname( field )
        end
        if @column_names.include?( field )
          by_field field
        else
          super
        end
      end
    end

    def convert_alternate_fieldname( field )
      field.gsub( /(^_)|(_$)/ , '' )
    end
  end
end
