module DmmUtil  
  class Reading
    attr_reader :raw

    MULTIPLIER_MAP = {
    -12 => "p",
     -9 => "n",
     -6 => "u",
     -3 => "m",
     -2 => "c",
     -1 => "d",
      0 => "",
      1 => "D",
      2 => "h",
      3 => "k",
      6 => "M",
      9 => "G",
     12 => "T"
    }
    
    def initialize(attrs)
      @raw = attrs
    end
    
    def ts 
      raw[:ts]
    end
    
    def value
      raw[:value]
    end
    
    def unit
      raw[:unit]
    end
    
    def scaled_value
      decimals = @raw[:decimals]
      multiplier = @raw[:unit_multiplier]
      state = @raw[:state]
      
      if state == "NORMAL"
        val = "%.#{decimals}f" % (value / (10 ** multiplier))
      elsif state == "OL_MINUS"
        val = "-OL"
      else
        val = state
      end
      
      [val, "#{MULTIPLIER_MAP[multiplier]}#{unit}"]
    end
    
    def to_s
      sv = scaled_value
      "#{sv.first} #{sv.last}"
    end

    def ==(other)
      value == other.value && unit == other.unit
    end
      

  end
end