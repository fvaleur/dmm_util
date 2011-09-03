module DmmUtil  
  class Recording
    attr_reader :raw
    
    def initialize(driver, attrs)
      @driver = driver
      @raw = attrs
    end
    
    def name
      raw[:name]
    end
    
    def start_ts
      raw[:start_ts]
    end
    
    def end_ts
      raw[:end_ts]
    end
    
    def seq_no
      raw[:seq_no]
    end
    
    def num_samples
      raw[:num_samples]
    end
    
    def measurements
      RecordingMeasurementCursor.new(@driver, self)
    end
    
  end
end