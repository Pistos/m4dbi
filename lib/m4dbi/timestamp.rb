module DBI
  class Timestamp
    def method_missing( method, *args )
      t = to_time
      begin
        t.send( method, *args )
      rescue NoMethodError => e
        raise NoMethodError.new(
          "undefined method '#{method}' for #{self}",
          method,
          args
        )
      end
    end
    
    def <=>( other )
      to_time <=> other.to_time
    end
  end
end