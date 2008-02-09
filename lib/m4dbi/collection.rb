module DBI
  class Collection
    def initialize( the_one, the_many_model, the_one_fk )
      @the_one = the_one
      @the_many_model = the_many_model
      @the_one_fk = the_one_fk
    end
    
    def elements
      @the_many_model.where( @the_one_fk => @the_one.pk )
    end
    
    def method_missing( method, *args, &blk )
      elements.send( method, *args, &blk )
    end
    
    def push( new_item_hash )
      new_item_hash[ @the_one_fk ] = @the_one.pk
      @the_many_model.create( new_item_hash )
    end
    alias << push
    alias add push
    
    def delete( arg )
      case arg
        when @the_many_model
          result = @the_many_model.dbh.do(
            %{
              DELETE FROM #{@the_many_model.table}
              WHERE
                #{@the_one_fk} = ?
                AND #{@the_many_model.pk} = ?
            },
            @the_one.pk,
            arg.pk
          )
          result > 0
        when Hash
          hash = arg
          keys = hash.keys
          where_subclause = keys.map { |k|
            "#{k} = ?"
          }.join( " AND " )
          @the_many_model.dbh.do(
            %{
              DELETE FROM #{@the_many_model.table}
              WHERE
                #{@the_one_fk} = ?
                AND #{where_subclause}
            },
            @the_one.pk,
            *( keys.map { |k| hash[ k ] } )
          )
      end
    end
  end
end