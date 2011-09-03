require 'test_helper'

 
class MeasurementTest < Test::Unit::TestCase
  include DMMTestHelper
  
  def test_basic_getters
    measurement = DmmUtil::Measurement.new(:name=>"This Was Saved", :prim_function => "VAC", 
                                       :ts=>Time.parse("Fri May 07 22:48:36.0166 2010"))  
    assert_equal "This Was Saved", measurement.name
    assert_equal "VAC", measurement.prim_function
    assert_equal Time.parse("Fri May 07 22:48:36.0166 2010"), measurement.ts
    
    measurement = DmmUtil::Measurement.new(:prim_function => "VDC", 
                                            :readings => {
                                              "PRIMARY" => {:ts=>Time.parse("Fri May 07 22:48:36.0166 2011")}
                                            })
    assert_equal Time.parse("Fri May 07 22:48:36.0166 2011"), measurement.ts
  end
  
  def test_reading_names
    measurement = DmmUtil::Measurement.new(:readings => {
                                              "PRIMARY" => {},
                                              "MAXIMUM" => {},
                                              "MINIMUM" => {}
                                           })
                                           
    assert_sets_equal [:primary, :maximum, :minimum], measurement.reading_names
  end
  
  def test_to_s
    measurement = DmmUtil::Measurement.new(:readings => {
                                              "PRIMARY" => {:value=>0.0362, :unit => "VAC", 
                                                            :unit_multiplier=>0, :decimals => 4, :state=>"NORMAL"},
                                              "SECONDARY" => {:value => 1.03e-06, :unit => "AAC",
                                                              :unit_multiplier => -6, :decimals => 2, :state=>"NORMAL"},
                                              "LIVE" => {:value => 9.99999999e+37, :unit => "OHM",
                                                          :unit_multiplier => 6, :decimals => 1, :state=>"OL"}
                                           })
                                           
    expected = "0.0362 VAC (secondary: 1.03 uAAC, live: OL MOHM)"
    assert_equal expected, measurement.to_s
  end
  
  def test_to_s__live_is_same_as_primary
    measurement = DmmUtil::Measurement.new(:readings => {
                                              "PRIMARY" => {:value=>0.0362, :unit => "VAC", 
                                                            :unit_multiplier=>0, :decimals => 4, :state=>"NORMAL"},
                                              "LIVE" =>   {:value=>0.0362, :unit => "VAC", 
                                                           :unit_multiplier=>0, :decimals => 4, :state=>"NORMAL"}
                                           })
                                           
    expected = "0.0362 VAC"
    assert_equal expected, measurement.to_s
  end
  
end