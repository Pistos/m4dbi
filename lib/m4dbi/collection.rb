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
  end
end