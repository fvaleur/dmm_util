require 'test_helper'


class FormatConvertorsTest < Test::Unit::TestCase
  include DMMTestHelper
  
  def setup
    test_class = Class.new()
    test_class.send(:include, DmmUtil::FormatConvertors)
    @fc = test_class.new
  end
  
  def test_get_u16
    assert_equal 0, @fc.get_u16("\x00\x00", 0)
    assert_equal 1, @fc.get_u16("\x01\x00", 0)
    assert_equal 257, @fc.get_u16("\x01\x01", 0)
    assert_equal 1, @fc.get_u16("\xff\x01\x00\xff", 1)
  end
  
  def test_get_s16
    assert_equal 0, @fc.get_s16("\x00\x00", 0)
    assert_equal 1, @fc.get_s16("\x01\x00", 0)
    assert_equal 256, @fc.get_s16("\x00\x01", 0)
    assert_equal 257, @fc.get_s16("\x01\x01", 0)
    assert_equal 1, @fc.get_s16("\xff\x01\x00\xff", 1)
    
    assert_equal -0x8000, @fc.get_s16("\x00\x80", 0)
    assert_equal -0x8000 + 1, @fc.get_s16("\x01\x80", 0)
    assert_equal -0x8000 + 256, @fc.get_s16("\x00\x81", 0)
    assert_equal -0x8000 + 257, @fc.get_s16("\x01\x81", 0) 
  end
  
  def test_get_double
    assert_equal 0, @fc.get_double("\x00\x00\x00\x00\x00\x00\x00\x00", 0)
    assert_equal 1, @fc.get_double("\00\00\xf0\x3F\x00\x00\x00\x00", 0) 
    assert_equal 123.4, @fc.get_double("\x99\xd9\x5e\x40\x9a\x99\x99\x99", 0)
    assert_equal -123.4, @fc.get_double("\x99\xd9\x5e\xc0\x9a\x99\x99\x99", 0)                         
    assert_equal 123.4, @fc.get_double("\xff\xff\x99\xd9\x5e\x40\x9a\x99\x99\x99\xff\xff", 2)
  end
  
  def test_parse_time
    t_local = Time.parse("Wed May 12 21:15:51 2010")
    t_utc = Time.parse("Wed May 12 21:15:51 UTC 2010")
    assert_equal 0, t_local - @fc.parse_time(t_utc.to_f)
    assert_equal -0.12, t_local - @fc.parse_time(t_utc.to_f + 0.12)
  end
  
  def test_get_time
    @fc.expects(:get_double).with(:str, :offset).returns(:floatval)
    @fc.expects(:parse_time).with(:floatval).returns(:timeval)
    assert_equal :timeval, @fc.get_time(:str, :offset)
  end
  
  def test_quote_str
    assert_equal "'a string'", @fc.quote_str("a string")
    assert_equal "\"a 'string'\"", @fc.quote_str("a 'string'")
    assert_equal "'a \"string\"'", @fc.quote_str('a "string"')
    assert_equal "'a ''string\"'", @fc.quote_str("a 'string\"") 
  end
  
end