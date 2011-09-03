module DmmUtil  
  class RecordingMeasurementCursor
    include Enumerable
    
    
    def initialize(driver, recording)
      @driver = driver
      @recording = recording
    end

    def count
      @recording.num_samples
    end
    
    def each
      (0..(count-1)).each do |idx|
        yield(self[idx])
      end
    end
    
    def [](idx)
      RecordingMeasurement.new(@driver.qsrr(@recording.raw[:reading_index] ,idx))
    end
    
  end
end