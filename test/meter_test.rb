require 'test_helper'

 
class MeterTest < Test::Unit::TestCase
  include DMMTestHelper
  
  def setup
    @driver_mock = mock()
    @meter = DmmUtil::Meter.new(@driver_mock)
  end
  
  def test_recordings_each
    @driver_mock.expects(:qsls).returns({:recording => 2})
    @driver_mock.expects(:qrsi).with(0).returns({:name => "Recording1"})
    @driver_mock.expects(:qrsi).with(1).returns({:name => "Recording2"})
    
    res = []
    @meter.recordings.each do |val|
      res << val.name
    end
    
    assert_equal ["Recording1", "Recording2"], res
  end
  
  def test_recordings_count
    @driver_mock.expects(:qsls).returns({:recording => 3})
    assert_equal 3, @meter.recordings.count
  end
  
  def test_recordings_index
    @driver_mock.expects(:qrsi).with(1).returns({:name => "Recording2"})    
    assert_equal "Recording2", @meter.recordings[1].name
  end
  
  def test_recordings_find_from_enumerable
    @driver_mock.expects(:qsls).returns({:recording => 4})
    @driver_mock.expects(:qrsi).with(0).returns({:name => "Recording1"})
    @driver_mock.expects(:qrsi).with(1).returns({:name => "Recording2"})
    
    rec = @meter.recordings.find{|r| r.name == "Recording2" }
    assert_equal "Recording2", rec.name
  end

  def test_saved_measurements_each
    @driver_mock.expects(:qsls).returns({:measurement => 2})
    @driver_mock.expects(:qsmr).with(0).returns({:name => "Measurement1"})
    @driver_mock.expects(:qsmr).with(1).returns({:name => "Measurement2"})
    
    res = []
    @meter.saved_measurements.each do |val|
      res << val.name
    end
    
    assert_equal ["Measurement1", "Measurement2"], res
  end
  
  def test_saved_measurements_count
    @driver_mock.expects(:qsls).returns({:measurement => 4})
    assert_equal 4, @meter.saved_measurements.count
  end
  
  def test_saved_measurements_index
    @driver_mock.expects(:qsmr).with(1).returns({
                    :name => "Measurement2", 
                    :readings => {"PRIMARY"=> {:value => 6.66}}
                    })    
    m = @meter.saved_measurements[1]
    assert_equal "Measurement2", m.name
    assert_equal 6.66, m.primary.value
  end
  
  def test_saved_measurements_find_from_enumerable
    @driver_mock.expects(:qsls).returns({:measurement => 4})
    @driver_mock.expects(:qsmr).with(0).returns({:name => "Measurement1"})
    @driver_mock.expects(:qsmr).with(1).returns({:name => "Measurement2"})
    
    m = @meter.saved_measurements.find{|m| m.name == "Measurement2" }
    assert_equal "Measurement2", m.name
  end
  
  def test_saved_min_max_each
    @driver_mock.expects(:qsls).returns({:min_max => 2})
    @driver_mock.expects(:qmmsi).with(0).returns({:name => "Measurement1"})
    @driver_mock.expects(:qmmsi).with(1).returns({:name => "Measurement2"})
    
    res = []
    @meter.saved_min_max.each do |val|
      res << val.name
    end
    
    assert_equal ["Measurement1", "Measurement2"], res
  end
  
  def test_saved_min_max_count
    @driver_mock.expects(:qsls).returns({:min_max => 4})
    assert_equal 4, @meter.saved_min_max.count
  end
  
  def test_saved_min_max_index
    @driver_mock.expects(:qmmsi).with(1).returns({
                    :name => "Measurement2", 
                    :readings => {"PRIMARY"=> {:value => 6.66}}
                    })    
    m = @meter.saved_min_max[1]
    assert_equal "Measurement2", m.name
    assert_equal 6.66, m.primary.value
  end
  
  def test_saved_min_max_find_from_enumerable
    @driver_mock.expects(:qsls).returns({:min_max => 4})
    @driver_mock.expects(:qmmsi).with(0).returns({:name => "Measurement1"})
    @driver_mock.expects(:qmmsi).with(1).returns({:name => "Measurement2"})
    
    m = @meter.saved_min_max.find{|m| m.name == "Measurement2" }
    assert_equal "Measurement2", m.name
  end
  
  def test_saved_peak_each
    @driver_mock.expects(:qsls).returns({:peak => 2})
    @driver_mock.expects(:qpsi).with(0).returns({:name => "Measurement1"})
    @driver_mock.expects(:qpsi).with(1).returns({:name => "Measurement2"})
    
    res = []
    @meter.saved_peak.each do |val|
      res << val.name
    end
    
    assert_equal ["Measurement1", "Measurement2"], res
  end
  
  def test_saved_peak_count
    @driver_mock.expects(:qsls).returns({:peak => 4})
    assert_equal 4, @meter.saved_peak.count
  end
  
  def test_saved_peak_index
    @driver_mock.expects(:qpsi).with(1).returns({
                    :name => "Measurement2", 
                    :readings => {"PRIMARY"=> {:value => 6.66}}
                    })    
    m = @meter.saved_peak[1]
    assert_equal "Measurement2", m.name
    assert_equal 6.66, m.primary.value
  end
  
  def test_saved_peak_find_from_enumerable
    @driver_mock.expects(:qsls).returns({:peak => 4})
    @driver_mock.expects(:qpsi).with(0).returns({:name => "Measurement1"})
    @driver_mock.expects(:qpsi).with(1).returns({:name => "Measurement2"})
    
    m = @meter.saved_peak.find{|m| m.name == "Measurement2" }
    assert_equal "Measurement2", m.name
  end
  
  def test_measure_now
    @driver_mock.expects(:qddb).returns({
      :prim_function => "V_DC", 
      :sec_function => "NONE", 
      :mode => ["MIN_MAX_AVG", "REL"], 
      :auto_range => "MANUAL", 
      :range_max => 5,               
      :readings => {
         "PRIMARY"=> {:decimals=>4, :unit_multiplier=>0, 
                       :state=>"NORMAL", :ts => Time.parse("Sat May 15 13:14:48.54199 2010"), 
                       :un1 => 5, :attribute => "NONE", :value=>-1.5821, :unit=>"VDC"},
         "MAXIMUM"=> {:decimals=>4, :unit_multiplier=>0, 
                       :state=>"NORMAL", :ts => Time.parse("Sat May 15 13:14:35.26465 2010"), 
                       :un1 => 5, :attribute => "NONE", :value=>-1.5352, :unit=>"VDC"}
      }
    })
    
    m = @meter.measure_now
    assert_equal "V_DC", m.prim_function
    assert_equal  Time.parse("Sat May 15 13:14:35.26465 2010"), m.maximum.ts
    assert_equal  -1.5821, m.primary.value
  end
  
end