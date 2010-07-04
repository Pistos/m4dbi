module M4DBI
  class Collection
    def initialize( the_one, the_many_model, the_one_fk )
      @the_one = the_one
      @the_many_model = the_many_model
      @the_one_fk = the_one_fk
    end

    def elements
      @the_many_model.where( @the_one_fk => @the_one.pk )
    end
    alias copy elements

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
          @the_many_model.dbh.execute(
            %{
              DELETE FROM #{@the_many_model.table}
              WHERE
                #{@the_one_fk} = ?
                AND #{@the_many_model.pk_clause}
            },
            @the_one.pk,
            arg.pk
          ).affected_count > 0
        when Hash
          hash = arg
          keys = hash.keys
          where_subclause = keys.map { |k|
            "#{k} = ?"
          }.join( " AND " )
          @the_many_model.dbh.execute(
            %{
              DELETE FROM #{@the_many_model.table}
              WHERE
                #{@the_one_fk} = ?
                AND #{where_subclause}
            },
            @the_one.pk,
            *( keys.map { |k| hash[ k ] } )
          ).affected_count
      end
    end

    # Returns the number of records deleted
    def clear
      @the_many_model.dbh.execute(
        %{
          DELETE FROM #{@the_many_model.table}
          WHERE #{@the_one_fk} = ?
        },
        @the_one.pk
      ).affected_count
    end
  end
end