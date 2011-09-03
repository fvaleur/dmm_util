module DmmUtil  
  class Cursor
    include Enumerable
    
    def initialize(driver, count_name, query_func, klass)
      @driver = driver
      @count_name = count_name
      @query_func = query_func
      @klass = klass
    end
    
    def count
      @count = @count || @driver.qsls[@count_name]
    end
    
    def each
      (0..(count-1)).each do |idx|
        yield(self[idx])
      end
    end
    
    def [](idx)
      if @klass.instance_method(:initialize).arity == 2
         @klass.new(@driver, @driver.send(@query_func, idx))
      else
        @klass.new(@driver.send(@query_func, idx))
      end
    end
    
  end
end