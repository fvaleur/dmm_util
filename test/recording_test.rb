require 'test_helper'

 
class RecordingTest < Test::Unit::TestCase
  include DMMTestHelper
  
  # def setup
  #   @driver_mock = mock()
  #   @meter = DmmUtil::Meter.new(@driver_mock)
  # end
  
  def test_name
    recording = DmmUtil::Recording.new(nil, {:name => "xyxz", :start_ts => :starttime, :end_ts => :endtime})
    assert_equal "xyxz", recording.name
    assert_equal :starttime, recording.start_ts
    assert_equal :endtime, recording.end_ts
  end
  
  def test_measurements_count
    driver_mock = mock()
    recording = DmmUtil::Recording.new(driver_mock, {:num_samples => 66})
    assert_equal 66, recording.measurements.count
  end
  
  def test_measurements_index
    driver_mock = mock()
    driver_mock.expects(:qsrr).with(99, 10).returns(
       {
        :start_ts=>Time.parse("Fri May 07 22:48:35.3125 2010"),
        :end_ts=>Time.parse("Fri May 07 22:48:47.18262 2010"),
        :readings=> {
          "MAXIMUM"=> {
            :unit=>"VAC", :state=>"NORMAL", :unit_multiplier=>0, :un1=>5,
           :ts=>Time.parse("Fri May 07 22:48:36.0166 2010"),
           :value=>0.0362, :attribute=>"NONE", :decimals=>4
          }
        },
        :readings2=> {
          "PRIMARY"=> {
            :unit=>"VAC", :state=>"NORMAL", :unit_multiplier=>0, :un1=>5,
            :ts=>Time.parse("Fri May 07 22:48:35.3125 2010"),
            :value=>0.0354, :attribute=>"NONE", :decimals=>4
          }
        },
      }
    )
    
    recording = DmmUtil::Recording.new(driver_mock, {:reading_index => 99})
    
    measurement = recording.measurements[10]
    assert_equal Time.parse("Fri May 07 22:48:35.3125 2010"), measurement.start_ts
    assert_equal 0.0362, measurement.maximum.value
    assert_equal 0.0354, measurement.primary.value
  end
  
  def test_measurements__each
    driver_mock = mock()
    test_time = Time.parse("Fri May 07 22:48:35.3125 2010")
    driver_mock.expects(:qsrr).with(99, 0).returns({:start_ts=> (test_time+1)})
    driver_mock.expects(:qsrr).with(99, 1).returns({:start_ts=> (test_time+2)})
    driver_mock.expects(:qsrr).with(99, 2).returns({:start_ts=> (test_time+3)})
    driver_mock.expects(:qsrr).with(99, 3).returns({:start_ts=> (test_time+4)})
    
    recording = DmmUtil::Recording.new(driver_mock, {:num_samples => 4, :reading_index => 99})
    
    res = []
    recording.measurements.each do |m|
      res << m.start_ts
    end
    
    assert_equal [(test_time+1), (test_time+2), (test_time+3), (test_time+4)], res
  end
  
  
end