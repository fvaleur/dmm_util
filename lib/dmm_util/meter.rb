module DmmUtil  
  class Meter
    attr_reader :driver
    
    def initialize(driver)
      @driver = driver
    end
    
    def recordings
      Cursor.new(driver, :recording, :qrsi, Recording)
    end
    
    def saved_measurements
      Cursor.new(driver, :measurement, :qsmr, Measurement)
    end
    
    def saved_min_max
      Cursor.new(driver, :min_max, :qmmsi, Measurement)
    end
    
    def saved_peak
      Cursor.new(driver, :peak, :qpsi, Measurement)
    end
    
    def measure_now
      Measurement.new(driver.qddb)
    end
    
  end
  
  class MeterError < RuntimeError
    attr_reader :status
    def initialize(msg, status = nil)
      super msg
      @status = status
    end
  end
  
end
