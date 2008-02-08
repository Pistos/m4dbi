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
    
    def <<( new_item_of_the_many )
      new_item_of_the_many.send( "#{@the_one_fk}=".to_sym, @the_one.pk )
    end
  end
end