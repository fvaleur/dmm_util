require 'test/unit'
require 'dmm_util'
require 'mocha'
require 'time'

module DMMTestHelper
  
  def assert_hashes_equal(expected, real, path = [])
    flunk "Values are not hash (#{expected.class.name}, #{expected.class.name})" unless expected.is_a?(Hash) && real.is_a?(Hash)
    
    expected_keys = expected.keys
    real_keys = real.keys
    flunk "Following keys expected but not found: #{(expected_keys - real_keys).join(", ")} (#{path.join(":")})" unless (expected_keys - real_keys).empty?
    flunk "Following keys found but not expected: #{(real_keys - expected_keys).join(", ")} (#{path.join(":")})" unless (real_keys - expected_keys).empty?
    
    expected_keys.each do |key|
      key_path = path.dup << key
      expected_val = expected[key]
      real_val = real[key]
      expected_val = expected_val.to_f if expected_val.is_a?(Fixnum) && real_val.is_a?(Float)
      flunk "Types for key #{key_path.join(":")} differ: expected #{expected_val.class.name} but was #{real_val.class.name}" if expected_val.class != real_val.class
      
      if expected_val.is_a?(Hash)
        assert_hashes_equal expected_val, real_val, key_path
      elsif expected_val.is_a?(Float)
        assert (expected_val - real_val).abs < 0.0000000001, "Values for key #{key_path.join(":")} not equal: Expected #{expected_val} but got #{real_val}"
      elsif expected_val.is_a?(Time)
        assert (expected_val.to_f - real_val.to_f).abs < 0.00001, "Values for key #{key_path.join(":")} not equal: Expected #{expected_val} but got #{real_val}"
      else
        assert_equal expected_val, real_val, "Values for key #{key_path.join(":")} not equal"
      end
    end
  end
  
  def assert_sets_equal(expected, real)
    not_found = expected - real
    not_expected = real - expected
    msg = []
    msg << "Expected but not found: #{not_found.join(", ")}." unless not_found.empty?
    msg << "Found but not expected: #{not_expected.join(", ")}." unless not_expected.empty?
    flunk msg.join("\n") unless msg.empty?
  end
  
  def hex(bytes)
    bs = DmmUtil::ByteStr.new(bytes)
    hex_chunks = []
    text_chunks = []
    bs.each_slice(8) do |slice|
      hex_chunks << slice.map{|b| "%02X" % b}.join(" ")
      text_chunks << slice.map{|b| (b > 32 && b < 126) ? b.chr : "."}.join
    end
    
    lines = []
    (0..hex_chunks.size-1).each_slice(2) do |left, right|
      if right.nil?
        lines << "#{hex_chunks[left]}#{' '*(23-hex_chunks[left].size)}  #{' '*23}  #{text_chunks[left]}" 
      else
        lines << "#{hex_chunks[left]}  #{hex_chunks[right]}#{' '*(23-hex_chunks[right].size)}  #{text_chunks[left]}#{text_chunks[right]}" 
      end
    end
    
    lines.join("\n")
  end
  
  def bin_parse(hexstr)
    hexstr.split.select{|s| s.size == 2}.map{|s| s.to_i(16).chr}.join
  end
  
  
  QEMAP = { :secfunction => {
                5=>"DBV",
                0=>"NONE",
                6=>"DBM_HERTZ",
                1=>"HERTZ",
                7=>"DBV_HERTZ",
                2=>"DUTY_CYCLE",
                8=>"CREST_FACTOR",
                3=>"PULSE_WIDTH",
                9=>"PEAK_MIN_MAX",
                4=>"DBM"},
                
            :autorange => {0=>"MANUAL", 1=>"AUTO"},
            
            :unit => {
                16=>"PCT",
                5=>"ADC",
                11=>"Hz",
                0=>"NONE",
                17=>"dB",
                6=>"AAC",
                12=>"S",
                1=>"VDC",
                18=>"dBV",
                7=>"AAC_PLUS_DC",
                13=>"F",
                2=>"VAC",
                19=>"dBm",
                8=>"A",
                14=>"CEL",
                3=>"VAC_PLUS_DC",
                20=>"CREST_FACTOR",
                9=>"OHM",
                15=>"FAR",
                4=>"V",
                10=>"SIE"},
              
            :mode => { 
                16=>"MIN_MAX_AVG",
                0=>"NONE",
                1=>"AUTO_HOLD",
                128=>"REL_PERCENT",
                2=>"AUTO_SAVE",
                8=>"LOW_PASS_FILTER",
                256=>"CALIBRATION",
                64=>"REL",
                4=>"HOLD",
                32=>"RECORD"},
                              
            :primfunction => {
                38=>"CAL_FILT_AMP", 27=>"OHMS", 16=>"UA_DC", 5=>"V_AC_OVER_DC", 44=>"CAL_ACDC_AC_COMP", 
                33=>"OHMS_LOW", 22=>"MA_AC_PLUS_DC", 11=>"A_AC", 0=>"LIMBO", 39=>"CAL_DC_AMP_X5", 
                28=>"CONDUCTANCE", 17=>"A_AC_OVER_DC", 6=>"V_DC_OVER_AC", 45=>"CAL_V_AC_LOZ", 
                34=>"CAL_V_DC_LOZ", 23=>"UA_AC_OVER_DC", 12=>"MA_AC", 1=>"V_AC", 40=>"CAL_DC_AMP_X10", 
                29=>"CONTINUITY", 18=>"A_DC_OVER_AC", 7=>"V_AC_PLUS_DC", 46=>"CAL_V_AC_PEAK", 35=>"CAL_AD_GAIN_X2", 
                24=>"UA_DC_OVER_AC", 13=>"UA_AC", 2=>"MV_AC", 41=>"CAL_NINV_AC_AMP", 30=>"CAPACITANCE", 
                19=>"A_AC_PLUS_DC", 8=>"MV_AC_OVER_DC", 47=>"CAL_MV_AC_PEAK", 36=>"CAL_AD_GAIN_X1", 
                25=>"UA_AC_PLUS_DC", 14=>"A_DC", 3=>"V_DC", 42=>"CAL_ISRC_500NA", 31=>"DIODE_TEST", 
                20=>"MA_AC_OVER_DC", 9=>"MV_DC_OVER_AC", 48=>"CAL_TEMPERATURE", 37=>"CAL_RMS", 
                26=>"TEMPERATURE", 15=>"MA_DC", 4=>"MV_DC", 43=>"CAL_COMP_TRIM_MV_DC", 32=>"V_AC_LOZ", 
                21=>"MA_DC_OVER_AC", 10=>"MV_AC_PLUS_DC"},
  
            :bolt => {0=>"OFF", 1=>"ON"},
  
            :readingid => {
                5=>"BARGRAPH",
                11=>"REL_REFERENCE",
                12=>"DB_REF",
                1=>"LIVE",
                7=>"MINIMUM",
                13=>"TEMP_OFFSET",
                2=>"PRIMARY",
                8=>"MAXIMUM",
                3=>"SECONDARY",
                9=>"AVERAGE",
                4=>"REL_LIVE"},

            :state => {            
                5=>"OL",
                0=>"INACTIVE",
                6=>"OL_MINUS",
                1=>"INVALID",
                7=>"OPEN_TC",
                2=>"NORMAL",
                3=>"BLANK",
                4=>"DISCHARGE"},
                
            :attribute => { 
                5=>"LO_OHMS", 
                0=>"NONE", 
                6=>"NEGATIVE_EDGE", 
                1=>"OPEN_CIRCUIT", 
                7=>"POSITIVE_EDGE", 
                2=>"SHORT_CIRCUIT", 
                8=>"HIGH_CURRENT", 
                3=>"GLITCH_CIRCUIT", 
                4=>"GOOD_DIODE"},

            :recordtype => {0=>"INPUT", 1=>"INTERVAL"},
            
            :isstableflag => {0=>"UNSTABLE", 1=>"STABLE"},
            
            :transientstate => {0=>"NON_T", 1=>"RANGE_UP", 2=>"RANGE_DOWN", 3=>"OVERLOAD", 4=>"OPEN_TC"},
   }                
  
  
end