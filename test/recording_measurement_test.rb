require 'test_helper'

 
class RecordingMeasurementTest < Test::Unit::TestCase
  include DMMTestHelper
  
  def test_basic_getters
    measurement = DmmUtil::RecordingMeasurement.new(:start_ts=>Time.parse("Fri May 07 22:48:36.0166 2010"),
                                           :end_ts=>Time.parse("Sat May 07 22:48:36.0166 2011")
                                          )  

    assert_equal Time.parse("Fri May 07 22:48:36.0166 2010"), measurement.start_ts
    assert_equal Time.parse("Sat May 07 22:48:36.0166 2011"), measurement.end_ts
  end
  
  def test_reading_names
    measurement = DmmUtil::RecordingMeasurement.new(:readings => {
                                              "MAXIMUM" => {},
                                              "MINIMUM" => {}
                                           }, :readings2 => {"PRIMARY" => {}})
                                           
    assert_sets_equal [:primary, :maximum, :minimum], measurement.reading_names
  end
  
  def test_to_s
    measurement = DmmUtil::RecordingMeasurement.new(:readings2 => {
                                                      "PRIMARY" => {:value=>0.0362, :unit => "VAC", 
                                                                    :unit_multiplier=>0, :decimals => 4, :state=>"NORMAL"},
                                                    },
                                                    :readings => {
                                                      "SECONDARY" => {:value => 1.03e-06, :unit => "AAC",
                                                                      :unit_multiplier => -6, :decimals => 2, :state=>"NORMAL"},
                                                      "LIVE" => {:value => 9.99999999e+37, :unit => "OHM",
                                                                 :unit_multiplier => 6, :decimals => 1, :state=>"OL"}
                                                    })
                                           
    expected = "0.0362 VAC (secondary: 1.03 uAAC, live: OL MOHM)"
    assert_equal expected, measurement.to_s
  end
  
  def test_to_s__live_is_same_as_primary
    measurement = DmmUtil::RecordingMeasurement.new(:readings2 => {
                                                      "PRIMARY" => {:value=>0.0362, :unit => "VAC", 
                                                                    :unit_multiplier=>0, :decimals => 4, :state=>"NORMAL"},
                                                    },
                                                    :readings => {
                                                      "LIVE" =>   {:value=>0.0362, :unit => "VAC", 
                                                                   :unit_multiplier=>0, :decimals => 4, :state=>"NORMAL"}
                                                    })
                                           
    expected = "0.0362 VAC"
    assert_equal expected, measurement.to_s
  end
  
end