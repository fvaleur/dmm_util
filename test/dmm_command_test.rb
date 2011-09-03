require 'test_helper'

# need uint32 parser
# Check if reading un1 is digits precision  -- no, at least not the one set using config.
####### Seems to be digit resolution (50MO / 500MO + capacitance has 4 dig resolution, maybe low ohm, conductance, d/s, p/w, CF)
# on max/min/peak stored value: seq_no might be 32 bit, leaves one unknown value, same as qddb, figure out ts1-ts3
# Press command 'press f1' 'press range,held_down' 'press down,repeated,1' (presses 2 times, seems to work only for arrows)
# Rename Fluke28xDriverto Fluke28xDriver, make new high level meter class
 
class DmmCommandTest < Test::Unit::TestCase
  include DMMTestHelper
  
  def setup
    @meter = DmmUtil::Fluke28xDriver.new(nil)
    @meter.stubs(:meter_command)
  end
  
  def test_id
    @meter.expects(:meter_command).with("ID").returns(["The Model", "Version", "Serial"])
    assert_equal({:model_number => "The Model", :software_version => "Version", :serial_number => "Serial"}, @meter.id)
  end
  
  def test_qsls
    @meter.expects(:meter_command).with("qsls").returns(["4","3","1","9"])
    assert_equal({:recording => 4, :min_max => 3,  :peak => 1, :measurement => 9}, @meter.qsls)
  end
  
  def test_qdda__plain
    @meter.expects(:meter_command).with("qdda").returns(["V_AC","NONE","AUTO","VAC","5","0","OFF","0.000","0","2",
                                                         "LIVE","0.0227","VAC","0","4","5","NORMAL","NONE","1273691972.231",
                                                         "PRIMARY","0.0228","VAC","0","4","5","NORMAL","NONE","1273691972.232"])
    expected = {:prim_function => "V_AC", :sec_function => "NONE", :mode => [], 
                  :auto_range => "AUTO", :range_max => 5,
                  :unit => "VAC", :unit_multiplier => 0,
                  :bolt => "OFF", :ts => nil,
                  :readings => {"LIVE"=> {:decimals=>4, :unit_multiplier=>0,
                                          :state=>"NORMAL", :ts=> Time.parse("Wed May 12 19:19:32.231 2010"),
                                          :display_digits=>5, :value=>0.0227, :attribute =>"NONE", :unit=>"VAC"},
                                "PRIMARY"=> {:decimals=>4, :unit_multiplier=>0, 
                                             :state=>"NORMAL", :ts => Time.parse("Wed May 12 19:19:32.232 2010"),
                                             :display_digits=>5, :value=>0.0228, :attribute=>"NONE", :unit=>"VAC"}}
                }
      result = @meter.qdda
          
      assert_hashes_equal expected, result
  end
  
  def test_qdda__relative_max_min
    @meter.expects(:meter_command).with("qdda").returns(["V_DC", "NONE", "MANUAL", "VDC", "5", "0", "OFF", "1273929235.231", 
                                                         "2", "MIN_MAX_AVG", "REL", "7", 
                                                         "LIVE", "-0.0002", "VDC", "0", "4", "5", "NORMAL", "NONE", "1273929288.341", 
                                                         "PRIMARY", "-1.5824", "VDC", "0", "4", "5", "NORMAL", "NONE", "1273929288.341", 
                                                         "REL_LIVE", "-0.0002", "VDC", "0", "4", "5", "NORMAL", "NONE", "1273929288.341", 
                                                         "MINIMUM", "1e+38", "VDC", "0", "4", "5", "OL_MINUS", "NONE", "1273929239.054", 
                                                         "MAXIMUM", "-1.5352", "VDC", "0", "4", "5", "NORMAL", "NONE", "1273929275.265", 
                                                         "AVERAGE", "-1.5874", "VDC", "0", "4", "5", "NORMAL", "NONE", "1273929288.341", 
                                                         "REL_REFERENCE", "1.5822", "VDC", "0", "4", "5", "NORMAL", "NONE", "1273929198.817"])  
    # todo un1: channel, sample time                                                     
        
    expected = {:prim_function => "V_DC", :sec_function => "NONE", :mode => ["MIN_MAX_AVG", "REL"], 
                   :auto_range => "MANUAL", :range_max => 5,
                   :unit => "VDC", :unit_multiplier => 0,
                   :bolt => "OFF", :ts => Time.parse("Sat May 15 13:13:55.231 2010"), 
                   :readings => {"LIVE"=> {:decimals=>4, :unit_multiplier=>0,
                                           :state=>"NORMAL", :ts=> Time.parse("Sat May 15 13:14:48.341 2010"), 
                                           :display_digits => 5, :attribute => "NONE", :value=>-0.0002, :unit=>"VDC"},
                               "PRIMARY"=> {:decimals=>4, :unit_multiplier=>0, 
                                            :state=>"NORMAL", :ts => Time.parse("Sat May 15 13:14:48.341 2010"), 
                                            :display_digits => 5, :attribute => "NONE", :value=>-1.5824, :unit=>"VDC"},
                                "MAXIMUM"=> {:decimals=>4, :unit_multiplier=>0, 
                                              :state=>"NORMAL", :ts => Time.parse("Sat May 15 13:14:35.265 2010"), 
                                              :display_digits => 5, :attribute => "NONE", :value=>-1.5352, :unit=>"VDC"},
                                "MINIMUM"=> {:decimals=>4, :unit_multiplier=>0, 
                                              :state=>"OL_MINUS", :ts => Time.parse("Sat May 15 13:13:59.054 2010"), 
                                              :display_digits => 5, :attribute => "NONE", :value=>1.0e+38, :unit=>"VDC"},
                                "AVERAGE"=> {:decimals=>4, :unit_multiplier=>0, 
                                              :state=>"NORMAL", :ts => Time.parse("Sat May 15 13:14:48.341 2010"), 
                                              :display_digits => 5, :attribute => "NONE", :value=>-1.5874, :unit=>"VDC"},
                                "REL_LIVE"=> {:decimals=>4, :unit_multiplier=>0, 
                                              :state=>"NORMAL", :ts => Time.parse("Sat May 15 13:14:48.341 2010"), 
                                              :display_digits => 5, :attribute => "NONE", :value=>-0.0002, :unit=>"VDC"},
                                "REL_REFERENCE"=> {:decimals=>4, :unit_multiplier=>0, 
                                              :state=>"NORMAL", :ts => Time.parse("Sat May 15 13:13:18.817 2010"), 
                                              :display_digits => 5, :attribute => "NONE", :value=>1.5822, :unit=>"VDC"},
                                }
                 }
    
    result = @meter.qdda    
    assert_hashes_equal expected, result
  end
    
  def test_qddb__relative_max_min
    stub_qemap
    hex = <<-HEX
      03 00 00 00 00 00 01 00  00 00 14 40 00 00 00 00  ...........@....
      00 00 00 00 A7 FB D2 41  00 D0 CE 84 50 00 00 00  .......A....P...
      07 00 01 00 E2 36 1A 3F  2D 43 1C EB 01 00 00 00  .....6.?-C......
      04 00 05 00 02 00 00 00  A7 FB D2 41 00 B0 22 92  ...........A..".
      02 00 48 50 F9 BF 8E 06  F0 16 01 00 00 00 04 00  ..HP............
      05 00 02 00 00 00 A7 FB  D2 41 00 B0 22 92 04 00  .........A.."...
      E2 36 1A 3F 2D 43 1C EB  01 00 00 00 04 00 05 00  .6.?-C..........
      02 00 00 00 A7 FB D2 41  00 B0 22 92 07 00 D3 CE  .......A..".....
      D2 47 2D DA C5 29 01 00  00 00 04 00 05 00 06 00  .G-..)..........
      00 00 A7 FB D2 41 00 70  C3 85 08 00 2D 90 F8 BF  .....A.p....-...
      72 1B 0D E0 01 00 00 00  04 00 05 00 02 00 00 00  r...............
      A7 FB D2 41 00 F0 D0 8E  09 00 FD 65 F9 BF F6 B9  ...A.......e....
      DA 8A 01 00 00 00 04 00  05 00 02 00 00 00 A7 FB  ................
      D2 41 00 B0 22 92 0B 00  B0 50 F9 3F FF B2 7B F2  .A.."....P.?..{.
      01 00 00 00 04 00 05 00  02 00 00 00 A7 FB D2 41  ...............A
      00 50 B4 7B                                       .P.{
    HEX
    
    @meter.expects(:meter_command).with("qddb").returns(bin_parse(hex))
    
    # Why does qdda not have :un1?
    expected = {:prim_function => "V_DC", :sec_function => "NONE", :mode => ["MIN_MAX_AVG", "REL"], 
                   :auto_range => "MANUAL", :range_max => 5,
                   :unit => "VDC", :unit_multiplier => 0,
                   :bolt => "OFF", :ts => Time.parse("Sat May 15 13:13:55.23145 2010"), :un1 => 0,
                   :readings => {"LIVE"=> {:decimals=>4, :unit_multiplier=>0,
                                           :state=>"NORMAL", :ts=> Time.parse("Sat May 15 13:14:48.54199 2010"), 
                                           :display_digits => 5, :attribute => "NONE", :value=>0.0001, :unit=>"VDC"},
                               "PRIMARY"=> {:decimals=>4, :unit_multiplier=>0, 
                                            :state=>"NORMAL", :ts => Time.parse("Sat May 15 13:14:48.54199 2010"), 
                                            :display_digits => 5, :attribute => "NONE", :value=>-1.5821, :unit=>"VDC"},
                                "MAXIMUM"=> {:decimals=>4, :unit_multiplier=>0, 
                                              :state=>"NORMAL", :ts => Time.parse("Sat May 15 13:14:35.26465 2010"), 
                                              :display_digits => 5, :attribute => "NONE", :value=>-1.5352, :unit=>"VDC"},
                                "MINIMUM"=> {:decimals=>4, :unit_multiplier=>0, 
                                              :state=>"OL_MINUS", :ts => Time.parse("Sat May 15 13:13:59.05371 2010"), 
                                              :display_digits => 5, :attribute => "NONE", :value=>9.99999999e+37, :unit=>"VDC"},
                                "AVERAGE"=> {:decimals=>4, :unit_multiplier=>0, 
                                              :state=>"NORMAL", :ts => Time.parse("Sat May 15 13:14:48.54199 2010"), 
                                              :display_digits => 5, :attribute => "NONE", :value=>-1.5874, :unit=>"VDC"},
                                "REL_LIVE"=> {:decimals=>4, :unit_multiplier=>0, 
                                              :state=>"NORMAL", :ts => Time.parse("Sat May 15 13:14:48.54199 2010"), 
                                              :display_digits => 5, :attribute => "NONE", :value=>0.0001, :unit=>"VDC"},
                                "REL_REFERENCE"=> {:decimals=>4, :unit_multiplier=>0, 
                                              :state=>"NORMAL", :ts => Time.parse("Sat May 15 13:13:18.81738 2010"), 
                                              :display_digits => 5, :attribute => "NONE", :value=>1.5822, :unit=>"VDC"},
                                }
                 }
    
    result = @meter.qddb
    assert_hashes_equal expected, result 
  end
  
  # modes/flags, min/max, timestamp
  
  def test_qemap
    @meter.expects(:meter_command).with("qemap state").returns(["8",
                                                                "0","INACTIVE",
                                                                "1","INVALID",
                                                                "2","NORMAL",
                                                                "3","BLANK",
                                                                "4","DISCHARGE",
                                                                "5","OL",
                                                                "6","OL_MINUS",
                                                                "7","OPEN_TC"])
    assert_equal({0 => "INACTIVE",
                  1 => "INVALID",
                  2 => "NORMAL",
                  3 => "BLANK",
                  4 => "DISCHARGE",
                  5 => "OL",
                  6 => "OL_MINUS",
                  7 => "OPEN_TC"}, @meter.qemap("state"))
        
    @meter.expects(:meter_command).with("qemap state").returns(["8", "0","INACTIVE"])
              
    assert_raise DmmUtil::MeterError do
      @meter.qemap("state")
    end 
  end
  
  def test_get_map
    @meter.expects(:qemap).once.with(:map_name1).returns({1 => :val_1_1, 2 => :val_1_2})
    @meter.expects(:qemap).once.with(:map_name2).returns({1 => :val_2_1, 2 => :val_2_2})
    
    assert_equal :val_1_1, @meter.get_map_value(:map_name1, "\x01\x00", 0)
    assert_equal :val_2_1, @meter.get_map_value(:map_name2, "\x01\x00", 0)
    assert_equal :val_1_2, @meter.get_map_value(:map_name1, "\x02\x00", 0)
    assert_equal :val_2_2, @meter.get_map_value(:map_name2, "\x02\x00", 0)

    assert_raise DmmUtil::MeterError do
      @meter.get_map_value(:map_name1, "\x03\x00", 0)
    end
  end
  
  def test_get_multimap
    @meter.expects(:qemap).once.with(:map_name1).returns({1 => :bit0, 2 => :bit1, 4 => :bit2, 8 => :bit3, 256 => :bit8})
    
    assert_equal [], @meter.get_multimap_value(:map_name1, "\x00\x00", 0)
    assert_equal [:bit0], @meter.get_multimap_value(:map_name1, "\x01\x00", 0)
    assert_equal [:bit0, :bit1], @meter.get_multimap_value(:map_name1, "\x03\x00", 0)
    assert_equal [:bit1, :bit2], @meter.get_multimap_value(:map_name1, "\x06\x00", 0)
    assert_equal [:bit0, :bit2], @meter.get_multimap_value(:map_name1, "\x05\x00", 0)
    assert_equal [:bit0, :bit8], @meter.get_multimap_value(:map_name1, "\x01\x01", 0)
    
    
    assert_raise DmmUtil::MeterError do
      @meter.get_multimap_value(:map_name1, "\x10\x00", 0)
    end
    
  end
  
  def test_qsmr
    stub_qemap
    hex = <<-HEX
      01 00 00 00 01 00 00 00  01 00 02 00 00 00 14 40  ...............@
      00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
      04 00 00 00 01 00 02 00  34 EF C0 3F E5 61 A1 D6  ........4..?.a..
      02 00 00 00 04 00 05 00  02 00 00 00 25 F9 D2 41  ............%..A
      00 30 A0 A8 52 65 63 6F  72 64 69 6E 67 20 31     .0..Recording.1
    HEX
    
    @meter.expects(:meter_command).with("qsmr 0").returns(bin_parse(hex))
    
    expected = {
     :prim_function => "V_AC", :sec_function => "NONE", :mode => ["HOLD"],
     :unit=>"VAC", :seq_no=>1, :bolt=> "OFF", :unit_multiplier=>0,
     :name=>"Recording 1", :auto_range=>"AUTO", :range_max=>5.0,
     :un1 => 0, :un4 => 0, :un5 => 0, :un6 => 0, :un7 => 0, :un9 => 0,
     :readings=> {
        "PRIMARY"=> {:unit => "VAC", :state => "NORMAL", :unit_multiplier => 0,
                     :display_digits => 5, :ts => Time.parse("Fri May 07 22:39:30.50293 2010"),
                     :value => 0.1323, :attribute => "NONE", :decimals => 4 }
                  }
    }
     
     real =  @meter.qsmr(0)
        
     assert_hashes_equal expected, real
  end
  
  def test_qmmsi
    stub_qemap
    hex = <<-HEX
      2B 00 00 00 2C F9 D2 41  00 40 3D 40 2C F9 D2 41  +...,..A.@=@,..A
      00 20 BA 46 01 00 00 00  01 00 02 00 00 00 14 40  ...F...........@
      00 00 00 00 00 00 01 00  2C F9 D2 41 00 40 3D 40  ........,..A.@=@
      10 00 00 00 04 00 02 00  7B F2 A0 3F 6E C5 FE B2  ........{..?n...
      02 00 00 00 04 00 05 00  02 00 00 00 2C F9 D2 41  ............,..A
      00 20 BA 46 07 00 76 4F  9E 3F AC AD D8 5F 02 00  ...F..vO.?..._..
      00 00 04 00 05 00 02 00  00 00 2C F9 D2 41 00 00  ..........,..A..
      8F 43 08 00 F2 1F A2 3F  72 8A 8E E4 02 00 00 00  .C.....?r.......
      04 00 05 00 02 00 00 00  2C F9 D2 41 00 90 BD 44  ........,..A...D
      09 00 A0 89 A0 3F 61 54  52 27 02 00 00 00 04 00  .....?aTR'......
      05 00 02 00 00 00 2C F9  D2 41 00 20 BA 46 43 69  ......,..A...FCi
      72 63 75 69 74 20 31                              rcuit.1
    HEX
    
    @meter.expects(:meter_command).with("qmmsi 0").returns(bin_parse(hex))
    
    expected = {:unit=>"VAC", :unit_multiplier=>0, :name=>"Circuit 1", :range_max=>5.0, :mode => ["MIN_MAX_AVG"],
      :prim_function=>"V_AC", :sec_function=>"NONE",:seq_no=>43, :autorange=>"AUTO", :bolt=>"ON",
      :un2=>0, :un8=>0,
      :ts1=>Time.parse("Sat May 08 00:32:00.95703 2010"),
      :ts2=>Time.parse("Sat May 08 00:32:26.9082 2010"), 
      :ts3=>Time.parse("Sat May 08 00:32:00.95703 2010"), 
      :readings=> {
          "MAXIMUM"=>{:unit=>"VAC", :state=>"NORMAL", :unit_multiplier=>0, :display_digits=>5,
              :ts=>Time.parse("Sat May 08 00:32:18.96191 2010"), 
              :value=>0.0354, :attribute=>"NONE", :decimals=>4
          },
          "PRIMARY"=> {
              :unit=>"VAC", :state=>"NORMAL", :unit_multiplier=>0, :display_digits=>5,
              :ts=>Time.parse("Sat May 08 00:32:26.9082 2010"), 
              :value=>0.0331, :attribute=>"NONE", :decimals=>4
          },
          "AVERAGE"=> {
              :unit=>"VAC", :state=>"NORMAL", :unit_multiplier=>0, :display_digits=>5,
              :ts=>Time.parse("Sat May 08 00:32:26.9082 2010"), 
              :value=>0.0323, :attribute=>"NONE", :decimals=>4
          },
         "MINIMUM"=> {
              :unit=>"VAC", :state=>"NORMAL", :unit_multiplier=>0, :display_digits=>5,
              :ts=>Time.parse("Sat May 08 00:32:14.23438 2010"), 
              :value=>0.0296, :attribute=>"NONE", :decimals=>4
         }
      },
    }
    real =  @meter.qmmsi(0)
    
    assert_hashes_equal expected, real
  end
  
  def test_qpsi
    stub_qemap
    hex = <<-HEX
      2C 00 00 00 2C F9 D2 41  00 60 A1 79 2C F9 D2 41  ,...,..A.`.y,..A
      00 60 11 7A 01 00 09 00  01 00 02 00 00 00 14 40  .`.z...........@
      00 00 00 00 00 00 01 00  2C F9 D2 41 00 60 A1 79  ........,..A.`.y
      10 00 00 00 04 00 02 00  72 68 A1 3F 9C C4 20 B0  ........rh.?....
      02 00 00 00 03 00 05 00  02 00 00 00 2C F9 D2 41  ............,..A
      00 60 11 7A 07 00 45 B6  B3 BF 83 C0 CA A1 04 00  .`.z..E.........
      00 00 03 00 05 00 02 00  00 00 2C F9 D2 41 00 70  ..........,..A.p
      B1 79 08 00 C0 CA C1 3F  98 6E 12 83 04 00 00 00  .y.....?.n......
      03 00 05 00 02 00 00 00  2C F9 D2 41 00 60 A1 79  ........,..A.`.y
      09 00 72 68 A1 3F 9C C4  20 B0 02 00 00 00 03 00  ..rh.?..........
      05 00 02 00 00 00 2C F9  D2 41 00 60 11 7A 43 69  ......,..A.`.zCi
      72 63 75 69 74 20 32                              rcuit.2
    HEX
    
    @meter.expects(:meter_command).with("qpsi 0").returns(bin_parse(hex))
    
    expected = {:unit=>"VAC", :unit_multiplier=>0, :range_max=>5.0, :name=>"Circuit 2", :mode => ["MIN_MAX_AVG"],
      :prim_function=>"V_AC", :sec_function=>"PEAK_MIN_MAX", :seq_no=>44, :autorange=>"AUTO", :bolt=>"ON",
      :un2=>0, :un8=>0, 
      :ts1=>Time.parse("Sat May 08 00:35:50.52148 2010"),
      :ts2=>Time.parse("Sat May 08 00:35:52.27148 2010"), 
      :ts3=>Time.parse("Sat May 08 00:35:50.52148 2010"),
      :readings=> {
        "MAXIMUM"=>{
          :unit=>"V", :state=>"NORMAL", :unit_multiplier=>0, :display_digits=>5,
          :ts=>Time.parse("Sat May 08 00:35:50.52148 2010"), 
          :value=>0.139, :attribute=>"NONE", :decimals=>3
        },
        "PRIMARY"=> {
          :unit=>"VAC", :state=>"NORMAL", :unit_multiplier=>0, :display_digits=>5,
          :ts=>Time.parse("Sat May 08 00:35:52.27148 2010"), 
          :value=>0.034, :attribute=>"NONE", :decimals=>3
        },
       "AVERAGE"=> {
         :unit=>"VAC", :state=>"NORMAL", :unit_multiplier=>0, :display_digits=>5,
         :ts=>Time.parse("Sat May 08 00:35:52.27148 2010"), 
         :value=>0.034, :attribute=>"NONE", :decimals=>3
       },
       "MINIMUM"=> {
         :unit=>"V", :state=>"NORMAL", :unit_multiplier=>0, :display_digits=>5,
         :ts=>Time.parse("Sat May 08 00:35:50.77246 2010"), 
         :value=>-0.077, :attribute=>"NONE", :decimals=>3
       }
      },
    }    
    
    real = @meter.qpsi(0)
    
    assert_hashes_equal expected, real
  end
  
  def test_qrsi
    # TODO: validate sample interval
    stub_qemap
    hex = <<-HEX
      06 00 00 00 26 F9 D2 41  00 00 D4 30 26 F9 D2 41  ....&..A...0&..A
      00 B0 CB 33 00 20 8C 40  00 00 00 00 E1 7A A4 3F  ...3...@.....z.?
      7B 14 AE 47 07 00 00 00  02 00 00 00 01 00 00 00  {..G............
      01 00 02 00 00 00 14 40  00 00 00 00 00 00 01 00  .......@........
      00 00 00 00 00 00 00 00  20 00 00 00 01 00 02 00  ................
      D7 12 A2 3F 51 FC 18 73  02 00 00 00 04 00 05 00  ...?Q..s........
      02 00 00 00 26 F9 D2 41  00 B0 CB 33 42 61 74 74  ....&..A...3Batt
      65 72 79 20 31                                    ery.1
    HEX
    
    @meter.expects(:meter_command).with("qrsi 0").returns(bin_parse(hex))
    
    expected = {:seq_no => 6, :prim_function => "V_AC", :sec_function => "NONE", :bolt => "ON",
                :unit=>"VAC", :sample_interval=>900.0, :num_samples=>2,
                :unit_multiplier=>0, :event_threshold=>0.04, :name=>"Battery 1",
                :mode =>['RECORD'],  :auto_range=>"AUTO", :range_max=>5.0, :reading_index=>7, # un1 is mode?
                :un4 => 0, :un3 => 0, :un10 => 0, :un11 => 0, :un2 => 0, :un12 => 0, :un9 => 0, :un8 => 0,
                :start_ts=>Time.parse("Fri May 07 22:48:35.3125 2010"),
                :end_ts=>Time.parse("Fri May 07 22:48:47.18262 2010"),
                :readings=> {
                  "PRIMARY"=> {
                    :unit=>"VAC", :state=>"NORMAL", :unit_multiplier=>0, :display_digits=>5,
                    :ts=>Time.parse("Fri May 07 22:48:47.18262 2010"),
                    :value=>0.0353, :attribute=>"NONE", :decimals=>4
                  }
                },
               }
    real = @meter.qrsi(0)
    assert_hashes_equal expected, real
  end
  
  def test_qsrr
    stub_qemap
    hex = <<-HEX
      26 F9 D2 41 00 00 D4 30  26 F9 D2 41 00 B0 CB 33  &..A...0&..A...3
      08 00 CE 88 A2 3F 7F FB  3A 70 02 00 00 00 04 00  .....?..:p......
      05 00 02 00 00 00 26 F9  D2 41 00 10 01 31 07 00  ......&..A...1..
      4E D1 A1 3F A9 35 CD 3B  02 00 00 00 04 00 05 00  N..?.5.;........
      02 00 00 00 26 F9 D2 41  00 60 14 31 09 00 55 B0  ....&..A.`.1..U.
      10 40 1C 7C 61 32 02 00  00 00 04 00 05 00 02 00  .@.|a2..........
      00 00 26 F9 D2 41 00 00  D4 30 76 00 00 00 02 00  ..&..A...0v.....
      F2 1F A2 3F 72 8A 8E E4  02 00 00 00 04 00 05 00  ...?r...........
      02 00 00 00 26 F9 D2 41  00 00 D4 30 00 00 01 00  ....&..A...0....
      00 00                                             ..
    HEX
    
    # We have to drop the last byte here because the way bin_parse works
    @meter.expects(:meter_command).with("qsrr 7,0", 149).returns(bin_parse(hex)[0..-2])
    
    expected = {
      :stable=>"STABLE", :record_type=>"INPUT", :un2=>0, :transient_state=>"NON_T", :duration=>11.8,
      :start_ts=>Time.parse("Fri May 07 22:48:35.3125 2010"),
      :end_ts=>Time.parse("Fri May 07 22:48:47.18262 2010"),
      :readings=> {
        "MAXIMUM"=> {
          :unit=>"VAC", :state=>"NORMAL", :unit_multiplier=>0, :display_digits=>5,
         :ts=>Time.parse("Fri May 07 22:48:36.0166 2010"),
         :value=>0.0362, :attribute=>"NONE", :decimals=>4
        },
        "AVERAGE"=> {
         :unit=>"VAC", :state=>"NORMAL", :unit_multiplier=>0, :display_digits=>5,
         :ts=>Time.parse("Fri May 07 22:48:35.3125 2010"),
         :value=>4.1722, :attribute=>"NONE", :decimals=>4
        },
        "MINIMUM"=> {
         :unit=>"VAC", :state=>"NORMAL", :unit_multiplier=>0, :display_digits=>5,
         :ts=>Time.parse("Fri May 07 22:48:36.31836 2010"),
         :value=>0.0348, :attribute=>"NONE", :decimals=>4
        }
      },
      :readings2=> {
        "PRIMARY"=> {
          :unit=>"VAC", :state=>"NORMAL", :unit_multiplier=>0, :display_digits=>5,
          :ts=>Time.parse("Fri May 07 22:48:35.3125 2010"),
          :value=>0.0354, :attribute=>"NONE", :decimals=>4
        }
      },
    }
    real = @meter.qsrr(7,0)
    assert_hashes_equal expected, real
  end
  
  def test_mpq_set_get
    @meter.expects(:meter_command).with("qmpq operator").returns([:the_operator])
    assert_equal :the_operator, @meter.operator
    
    @meter.expects(:meter_command).with("mpq operator,'new operator'", 0)
    @meter.operator = "new operator"
  end
  
  def test_mp_set_get
    @meter.expects(:meter_command).with("qmp beeper").returns([:beeper_state])
    assert_equal :beeper_state, @meter.beeper
    
    @meter.expects(:meter_command).never
    assert_raise DmmUtil::MeterError do
      @meter.beeper = "new_state"
    end
    
    @meter.expects(:meter_command).with("mp beeper,off", 0)
    @meter.beeper = :off
    
    @meter.expects(:meter_command).with("qmp cusdbm").returns(["100"])
    assert_equal 100, @meter.cusdbm
    
    @meter.expects(:meter_command).never
    assert_raise DmmUtil::MeterError do
      @meter.cusdbm = "astring"
    end
  end
  
  def test_clock_set_get
    t_local = Time.parse("Wed May 12 21:15:51 2010")
    t_utc = Time.parse("Wed May 12 21:15:51 UTC 2010")  
    
    @meter.expects(:meter_command).with("mp clock,#{t_utc.to_i}", 0)
    @meter.clock = t_local

    @meter.expects(:meter_command).with("qmp clock").returns(["#{t_utc.to_i}"])
    assert_equal t_local, @meter.clock
  end
  
  
  ###### Test helper test????
  def test_hex
    str = "\x01\x02\x03\x04\x05\x06\x07\x08\x09\n123\n234"
    teststr = str + str + "hellothere"
    expected = <<-ASC
01 02 03 04 05 06 07 08  09 0A 31 32 33 0A 32 33  ..........123.23
34 01 02 03 04 05 06 07  08 09 0A 31 32 33 0A 32  4..........123.2
33 34 68 65 6C 6C 6F 74  68 65 72 65              34hellothere
ASC
    assert_equal expected.strip, hex(teststr)
    assert_equal teststr, bin_parse(expected)
  end
  ######## End test helper test???
  
  def stub_qemap
    QEMAP.each do |key, val|
       @meter.stubs(:qemap).with(key).returns(val)
    end
  end
  
end