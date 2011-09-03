require 'test_helper'

 
class ReadingTest < Test::Unit::TestCase
  include DMMTestHelper
  
  def test_basic_getters
    reading = DmmUtil::Reading.new(:value=>0.0362, :unit => "VAC", 
                                   :ts=>Time.parse("Fri May 07 22:48:36.0166 2010"))  
    assert_equal 0.0362, reading.value
    assert_equal "VAC", reading.unit
    assert_equal Time.parse("Fri May 07 22:48:36.0166 2010"), reading.ts
  end
  
  def test_to_s
    reading = DmmUtil::Reading.new({})
    reading.expects(:scaled_value).returns(["foo", "bar"])
    assert_equal "foo bar", reading.to_s
  end
  
  def test_scaled_value
     reading = DmmUtil::Reading.new(:value=>0.0362, :unit => "VAC", 
                                    :unit_multiplier=>0, :decimals => 4, :state=>"NORMAL")
     
     assert_equal ["0.0362", "VAC"], reading.scaled_value
     
     reading = DmmUtil::Reading.new(:value => 1.1e-05, :unit => "VDC",
                                    :unit_multiplier => -3, :decimals => 3, :state=>"NORMAL")
     assert_equal ["0.011", "mVDC"], reading.scaled_value
  
     reading = DmmUtil::Reading.new(:value => 1135700.0, :unit => "OHM",
                                    :unit_multiplier => 6, :decimals => 4, :state=>"NORMAL")
     assert_equal ["1.1357", "MOHM"], reading.scaled_value
     
     reading = DmmUtil::Reading.new(:value => 1.03e-06, :unit => "AAC",
                                    :unit_multiplier => -6, :decimals => 2, :state=>"NORMAL")
     assert_equal ["1.03", "uAAC"], reading.scaled_value
     
     reading = DmmUtil::Reading.new(:value => 9.99999999e+37, :unit => "OHM",
                                    :unit_multiplier => 6, :decimals => 1, :state=>"OL")
     assert_equal ["OL", "MOHM"], reading.scaled_value
     
     reading = DmmUtil::Reading.new(:value=>9.99999999e+37, :unit=>"VDC",
                                    :unit_multiplier=>-3, :decimals=>2, :state=>"OL_MINUS")
     assert_equal ["-OL", "mVDC"], reading.scaled_value
  end
  
end