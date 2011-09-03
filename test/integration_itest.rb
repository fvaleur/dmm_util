require 'test_helper'

class IntegrationItest < Test::Unit::TestCase
  include DMMTestHelper
  
  def test_open
    m = DmmUtil.open
    assert m.driver.valid?
  end
  
  def test_id
    @meter = DmmUtil::open_driver("/dev/tty.usbserial-A7004rWH")
    res = @meter.id
    assert_equal({:model_number=>"FLUKE 289",
                  :software_version=>"V1.10",
                  :serial_number=>"12540010"},  res)
  end
  
  def test_qemap
    @meter = DmmUtil::open_driver("/dev/tty.usbserial-A7004rWH")
    QEMAP.each do |key, val|
       assert_equal(val, @meter.qemap(key))
    end
  end
  
  def test_mpq_props
    @meter = DmmUtil::open_driver("/dev/tty.usbserial-A7004rWH")
    assert_sets_equal DmmUtil::Fluke28xDriver::MPQ_PROPS, @meter.qemap(:mpq_props).values.map{|val| val.downcase.to_sym}
  end
  
  def test_mp_props
    @meter = DmmUtil::open_driver("/dev/tty.usbserial-A7004rWH")
    assert_sets_equal DmmUtil::Fluke28xDriver::MP_PROPS.keys.map{|v|v.to_s}, @meter.qemap(:mp_props).values.map{|val| val.downcase}
    DmmUtil::Fluke28xDriver::MP_PROPS.each do |key, val|
      next unless val.is_a?(Array)
      if val.first.is_a?(Integer)
        real =  @meter.qemap(key).values.map{|v| Integer(v)}
      else
        real =  @meter.qemap(key).values.map{|v| v.downcase.to_sym}
      end
      assert_sets_equal val, real
    end
  end
  
  # Time
  # qdda/qddb query setting consistent
  # Hitting backlight key / query backlight status
  
  # def test_qdda
  #   result = @meter.meter_command("qdda")
  #   puts result.inspect
  # end
  # 
  # def test_qddb
  #   result = @meter.meter_command("qddb")
  #   puts hex(result)
  # end
  
  # def test_qsmr
  #   #saved meassurement
  #   result = @meter.meter_command("qsmr 0")
  #   puts "qsmr"
  #   puts hex(result)
  #   # 01 00 00 00 01 00 00 00  01 00 02 00 00 00 14 40  ...............@
  #   # 00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  #   # 04 00 00 00 01 00 02 00  34 EF C0 3F E5 61 A1 D6  ........4..?.a..
  #   # 02 00 00 00 04 00 05 00  02 00 00 00 25 F9 D2 41  ............%..A
  #   # 00 30 A0 A8 52 65 63 6F  72 64 69 6E 67 20 31     .0..Recording.1
  # end
  # 
  # def test_qmmsi
  #   #saved min/max
  #   result = @meter.meter_command("qmmsi 0")
  #   puts "qmmsi"
  #   puts hex(result)
  #   # 2B 00 00 00 2C F9 D2 41  00 40 3D 40 2C F9 D2 41  +...,..A.@=@,..A
  #   # 00 20 BA 46 01 00 00 00  01 00 02 00 00 00 14 40  ...F...........@
  #   # 00 00 00 00 00 00 01 00  2C F9 D2 41 00 40 3D 40  ........,..A.@=@
  #   # 10 00 00 00 04 00 02 00  7B F2 A0 3F 6E C5 FE B2  ........{..?n...
  #   # 02 00 00 00 04 00 05 00  02 00 00 00 2C F9 D2 41  ............,..A
  #   # 00 20 BA 46 07 00 76 4F  9E 3F AC AD D8 5F 02 00  ...F..vO.?..._..
  #   # 00 00 04 00 05 00 02 00  00 00 2C F9 D2 41 00 00  ..........,..A..
  #   # 8F 43 08 00 F2 1F A2 3F  72 8A 8E E4 02 00 00 00  .C.....?r.......
  #   # 04 00 05 00 02 00 00 00  2C F9 D2 41 00 90 BD 44  ........,..A...D
  #   # 09 00 A0 89 A0 3F 61 54  52 27 02 00 00 00 04 00  .....?aTR'......
  #   # 05 00 02 00 00 00 2C F9  D2 41 00 20 BA 46 43 69  ......,..A...FCi
  #   # 72 63 75 69 74 20 31                              rcuit.1
  # end
  # 
  # def test_qpsi
  #   #saved peak
  #   result = @meter.meter_command("qpsi 0")
  #   puts "qpsi"
  #   puts hex(result)
  #   # 2C 00 00 00 2C F9 D2 41  00 60 A1 79 2C F9 D2 41  ,...,..A.`.y,..A
  #   # 00 60 11 7A 01 00 09 00  01 00 02 00 00 00 14 40  .`.z...........@
  #   # 00 00 00 00 00 00 01 00  2C F9 D2 41 00 60 A1 79  ........,..A.`.y
  #   # 10 00 00 00 04 00 02 00  72 68 A1 3F 9C C4 20 B0  ........rh.?....
  #   # 02 00 00 00 03 00 05 00  02 00 00 00 2C F9 D2 41  ............,..A
  #   # 00 60 11 7A 07 00 45 B6  B3 BF 83 C0 CA A1 04 00  .`.z..E.........
  #   # 00 00 03 00 05 00 02 00  00 00 2C F9 D2 41 00 70  ..........,..A.p
  #   # B1 79 08 00 C0 CA C1 3F  98 6E 12 83 04 00 00 00  .y.....?.n......
  #   # 03 00 05 00 02 00 00 00  2C F9 D2 41 00 60 A1 79  ........,..A.`.y
  #   # 09 00 72 68 A1 3F 9C C4  20 B0 02 00 00 00 03 00  ..rh.?..........
  #   # 05 00 02 00 00 00 2C F9  D2 41 00 60 11 7A 43 69  ......,..A.`.zCi
  #   # 72 63 75 69 74 20 32                              rcuit.2
  # endx
  # 
  # def test_qrsi
  #   # Recorded session info / header
  #   result = @meter.meter_command("qrsi 0")
  #   puts "qrsi"
  #   puts hex(result)
  #   # 06 00 00 00 26 F9 D2 41  00 00 D4 30 26 F9 D2 41  ....&..A...0&..A
  #   # 00 B0 CB 33 00 20 8C 40  00 00 00 00 E1 7A A4 3F  ...3...@.....z.?
  #   # 7B 14 AE 47 07 00 00 00  02 00 00 00 01 00 00 00  {..G............
  #   # 01 00 02 00 00 00 14 40  00 00 00 00 00 00 01 00  .......@........
  #   # 00 00 00 00 00 00 00 00  20 00 00 00 01 00 02 00  ................
  #   # D7 12 A2 3F 51 FC 18 73  02 00 00 00 04 00 05 00  ...?Q..s........
  #   # 02 00 00 00 26 F9 D2 41  00 B0 CB 33 42 61 74 74  ....&..A...3Batt
  #   # 65 72 79 20 31                                    ery.1
  # end
  # 
  # def test_qsrr
  #   # Recorded session record/sample
  #   puts "qsrr"
  #   result = @meter.meter_command("qsrr 7,0")
  #   puts hex(result)
  #   # 26 F9 D2 41 00 00 D4 30  26 F9 D2 41 00 B0 CB 33  &..A...0&..A...3
  #   # 08 00 CE 88 A2 3F 7F FB  3A 70 02 00 00 00 04 00  .....?..:p......
  #   # 05 00 02 00 00 00 26 F9  D2 41 00 10 01 31 07 00  ......&..A...1..
  #   # 4E D1 A1 3F A9 35 CD 3B  02 00 00 00 04 00 05 00  N..?.5.;........
  #   # 02 00 00 00 26 F9 D2 41  00 60 14 31 09 00 55 B0  ....&..A.`.1..U.
  #   # 10 40 1C 7C 61 32 02 00  00 00 04 00 05 00 02 00  .@.|a2..........
  #   # 00 00 26 F9 D2 41 00 00  D4 30 76 00 00 00 02 00  ..&..A...0v.....
  #   # F2 1F A2 3F 72 8A 8E E4  02 00 00 00 04 00 05 00  ...?r...........
  #   # 02 00 00 00 26 F9 D2 41  00 00 D4 30 00 00 01 00  ....&..A...0....
  #   # 00 00                                             ..
  # end
  # 
  # 
  # 
  # def xtest_other_maps
  #    @meter.qemap(:fileMode)
  #    @meter.qemap(:beeperTestState)
  #    @meter.qemap(:sessionType)
  #    @meter.qemap(:calStatus)
  #    @meter.qemap(:mode)
  #    @meter.qemap(:readingID)
  #    @meter.qemap(:attribute)
  #    @meter.qemap(:jackName)
  #    @meter.qemap(:jackPositionStatus)
  #    @meter.qemap(:testPattern)
  #    @meter.qemap(:lcdModeState)
  #    @meter.qemap(:ledState)
  #    @meter.qemap(:mp_props)
  #    @meter.qemap(:mpdev_props)
  #    @meter.qemap(:mpq_props)
  #    @meter.qemap(:memSize)
  #    @meter.qemap(:powerMode)
  #    @meter.qemap(:buttonName)
  #    @meter.qemap(:presstype)
  #    @meter.qemap(:channel)
  #    @meter.qemap(:sampleTime)
  #    @meter.qemap(:recordType)
  #    @meter.qemap(:isStableFlag)
  #    @meter.qemap(:transientState)
  #    @meter.qemap(:xaJackName)
  # end
  # 
  # def xtest_other_maps2
  #   @meter.qemap(:rsob)
  #   @meter.qemap(:blightVals)
  #   @meter.qemap(:blVals)
  #   @meter.qemap(:memVals)
  #   @meter.qemap(:primFunction)
  #   @meter.qemap(:secFunction)
  #   @meter.qemap(:MODE)
  #   @meter.qemap(:jackDetect)
  #   @meter.qemap(:updateMode)
  #   @meter.qemap(:acSmooth)
  #   @meter.qemap(:SI)
  #   @meter.qemap(:tempUnit)
  #   @meter.qemap(:dBmRef)
  #   @meter.qemap(:pwPol)
  #   @meter.qemap(:hzEdge)
  #   @meter.qemap(:dcPol)
  #   @meter.qemap(:contBeep)
  #   @meter.qemap(:contBeepOS)
  #   @meter.qemap(:timeFmt)
  #   @meter.qemap(:numFmt)
  #   @meter.qemap(:lang)
  #   @meter.qemap(:dateFmt)
  #   @meter.qemap(:recEventTh)
  #   @meter.qemap(:rsm)
  #   @meter.qemap(:ablto)
  #   @meter.qemap(:digits)
  #   @meter.qemap(:beeper)
  #   @meter.qemap(:apoffto)
  #   @meter.qemap(:UNIT)
  #   @meter.qemap(:ATTRIBUTE)
  #   @meter.qemap(:STATE)
  #   @meter.qemap(:autoRange)
  #   @meter.qemap(:unit)
  #   @meter.qemap(:bolt)
  # end
  

  
  
  
  
  
  
  
  #"Map fileMode: {0=>\"READ\", 1=>\"APPEND\", 2=>\"TRUNCATE\"}"
  #"Map beeperTestState: {0=>\"OFF\", 1=>\"ON\"}"
  #"Map sessionType: {0=>\"ALL\", 1=>\"RECORDED\", 2=>\"MIN_MAX\", 3=>\"PEAK\", 4=>\"MEASUREMENT\"}"
  #"Map calStatus: {5=>\"CAL_COMPLETE\", 0=>\"INACTIVE\", 1=>\"WAITING\", 2=>\"CALIBRATING\", 3=>\"INVALID_ROTARY_SWITCH\"}"
  #"Map mode: {16=>\"MIN_MAX_AVG\", 0=>\"NONE\", 1=>\"AUTO_HOLD\", 128=>\"REL_PERCENT\", 2=>\"AUTO_SAVE\", 8=>\"LOW_PASS_FILTER\", 256=>\"CALIBRATION\", 64=>\"REL\", 4=>\"HOLD\", 32=>\"RECORD\"}"
  #"Map readingID: {5=>\"BARGRAPH\", 11=>\"REL_REFERENCE\", 12=>\"DB_REF\", 1=>\"LIVE\", 7=>\"MINIMUM\", 13=>\"TEMP_OFFSET\", 2=>\"PRIMARY\", 8=>\"MAXIMUM\", 3=>\"SECONDARY\", 9=>\"AVERAGE\", 4=>\"REL_LIVE\"}"
  #"Map attribute: {5=>\"LO_OHMS\", 0=>\"NONE\", 6=>\"NEGATIVE_EDGE\", 1=>\"OPEN_CIRCUIT\", 7=>\"POSITIVE_EDGE\", 2=>\"SHORT_CIRCUIT\", 8=>\"HIGH_CURRENT\", 3=>\"GLITCH_CIRCUIT\", 4=>\"GOOD_DIODE\"}"
  #"Map jackName: {0=>\"AMPS\", 1=>\"m_uAMPS\"}"
  #"Map jackPositionStatus: {0=>\"IN\", 1=>\"OUT\"}"
  #"Map testPattern: {5=>\"HORIZ_LINES\", 0=>\"OFF\", 6=>\"VERT_LINES\", 1=>\"BLANK\", 7=>\"HORIZ_LINES_OFFSET\", 2=>\"BOX\", 8=>\"VERT_LINES_OFFSET\", 3=>\"SOLID\", 4=>\"CONTRAST\"}"
  #"Map lcdModeState: {0=>\"ON\", 1=>\"OFF\"}"
  #"Map ledState: {0=>\"ON\", 1=>\"OFF\"}"
  #"Map mp_props: {16=>\"dcPol\", 5=>\"rsm\", 22=>\"SI\", 11=>\"lang\", 0=>\"apoffto\", 17=>\"hzEdge\", 6=>\"lcdCont\", 23=>\"acSmooth\", 12=>\"numFmt\", 1=>\"beeper\", 18=>\"pwPol\", 7=>\"ahEventTh\", 13=>\"timeFmt\", 2=>\"cusDBm\", 19=>\"dBmRef\", 8=>\"recEventTh\", 14=>\"contBeepOS\", 3=>\"digits\", 20=>\"tempOS\", 9=>\"Clock\", 15=>\"contBeep\", 4=>\"ablto\", 21=>\"tempUnit\", 10=>\"dateFmt\"}"
  #"Map mpdev_props: {0=>\"ablto\", 1=>\"apoffto\", 2=>\"recEventTh\"}"
  #"Map mpq_props: {0=>\"COMPANY\", 1=>\"CONTACT\", 2=>\"OPERATOR\", 3=>\"SITE\"}"
  #"Map memSize: {1=>\"1\", 2=>\"2\", 4=>\"4\"}"
  #"Map powerMode: {0=>\"ON\", 1=>\"BATTERY_SAVER\", 2=>\"OFF\", 3=>\"OFF_WITH_WAKEUP\", 4=>\"RESTART\"}"
  #"Map buttonName: {654=>\"HOLD\", 660=>\"ONOFF\", 655=>\"MINMAX\", 650=>\"F1\", 606=>\"UP\", 656=>\"RANGE\", 651=>\"F2\", 607=>\"DOWN\", 657=>\"INFO\", 652=>\"F3\", 608=>\"LEFT\", 658=>\"BACKLIGHT\", 653=>\"F4\", 609=>\"RIGHT\"}"
  #"Map presstype: {0=>\"PRESSED\", 1=>\"HELD_DOWN\", 2=>\"RELEASED\", 3=>\"REPEATED\"}"
  #"Map channel: {5=>\"5\", 0=>\"0\", 6=>\"6\", 1=>\"1\", 7=>\"7\", 2=>\"2\", 3=>\"3\", 4=>\"4\"}"
  #"Map sampleTime: {5=>\"5\", 11=>\"11\", 0=>\"0\", 6=>\"6\", 12=>\"12\", 1=>\"1\", 7=>\"7\", 13=>\"13\", 2=>\"2\", 8=>\"8\", 14=>\"14\", 3=>\"3\", 9=>\"9\", 15=>\"15\", 4=>\"4\", 10=>\"10\"}"
  #"Map recordType: {0=>\"INPUT\", 1=>\"INTERVAL\"}"
  #"Map isStableFlag: {0=>\"UNSTABLE\", 1=>\"STABLE\"}"
  #"Map transientState: {0=>\"NON_T\", 1=>\"RANGE_UP\", 2=>\"RANGE_DOWN\", 3=>\"OVERLOAD\", 4=>\"OPEN_TC\"}"
  #"Map xaJackName: {5=>\"JACK\", 0=>\"AMPS\", 1=>\"m_uAMPS\", 2=>\"BOTH\", 3=>\"NONE\", 4=>\"IGNORE\"}"
  
  
  ## Can be set?
  #"Map rsob: {5=>\"4\", 11=>\"NUM\", 0=>\"LIMBO\", 6=>\"5\", 12=>\"INVALID\", 1=>\"0\", 7=>\"6\", 2=>\"1\", 8=>\"7\", 3=>\"2\", 9=>\"8\", 4=>\"3\", 10=>\"9\"}"
  #"Map blightVals: {1=>\"OFF\", 2=>\"LOW\", 3=>\"HIGH\"}"
  #"Map blVals: {5=>\"PARTLY_EMPTY_3\", 6=>\"FULL\", 1=>\"EMPTY\", 2=>\"ALMOST_EMPTY\", 3=>\"PARTLY_EMPTY_1\", 4=>\"PARTLY_EMPTY_2\"}"
  #"Map memVals: {0=>\"EXHAUSTED\", 1=>\"SEVERE\", 2=>\"WARNING\", 3=>\"OK\"}"
  #"Map primFunction: {38=>\"CAL_FILT_AMP\", 27=>\"OHMS\", 16=>\"UA_DC\", 5=>\"V_AC_OVER_DC\", 44=>\"CAL_ACDC_AC_COMP\", 33=>\"OHMS_LOW\", 22=>\"MA_AC_PLUS_DC\", 11=>\"A_AC\", 0=>\"LIMBO\", 39=>\"CAL_DC_AMP_X5\", 28=>\"CONDUCTANCE\", 17=>\"A_AC_OVER_DC\", 6=>\"V_DC_OVER_AC\", 45=>\"CAL_V_AC_LOZ\", 34=>\"CAL_V_DC_LOZ\", 23=>\"UA_AC_OVER_DC\", 12=>\"MA_AC\", 1=>\"V_AC\", 40=>\"CAL_DC_AMP_X10\", 29=>\"CONTINUITY\", 18=>\"A_DC_OVER_AC\", 7=>\"V_AC_PLUS_DC\", 46=>\"CAL_V_AC_PEAK\", 35=>\"CAL_AD_GAIN_X2\", 24=>\"UA_DC_OVER_AC\", 13=>\"UA_AC\", 2=>\"MV_AC\", 41=>\"CAL_NINV_AC_AMP\", 30=>\"CAPACITANCE\", 19=>\"A_AC_PLUS_DC\", 8=>\"MV_AC_OVER_DC\", 47=>\"CAL_MV_AC_PEAK\", 36=>\"CAL_AD_GAIN_X1\", 25=>\"UA_AC_PLUS_DC\", 14=>\"A_DC\", 3=>\"V_DC\", 42=>\"CAL_ISRC_500NA\", 31=>\"DIODE_TEST\", 20=>\"MA_AC_OVER_DC\", 9=>\"MV_DC_OVER_AC\", 48=>\"CAL_TEMPERATURE\", 37=>\"CAL_RMS\", 26=>\"TEMPERATURE\", 15=>\"MA_DC\", 4=>\"MV_DC\", 43=>\"CAL_COMP_TRIM_MV_DC\", 32=>\"V_AC_LOZ\", 21=>\"MA_DC_OVER_AC\", 10=>\"MV_AC_PLUS_DC\"}"
  #"Map secFunction: {5=>\"DBV\", 0=>\"NONE\", 6=>\"DBM_HERTZ\", 1=>\"HERTZ\", 7=>\"DBV_HERTZ\", 2=>\"DUTY_CYCLE\", 8=>\"CREST_FACTOR\", 3=>\"PULSE_WIDTH\", 9=>\"PEAK_MIN_MAX\", 4=>\"DBM\"}"
  #"Map MODE: {16=>\"MIN_MAX_AVG\", 0=>\"NONE\", 1=>\"AUTO_HOLD\", 128=>\"REL_PERCENT\", 2=>\"AUTO_SAVE\", 8=>\"LOW_PASS_FILTER\", 256=>\"CALIBRATION\", 64=>\"REL\", 4=>\"HOLD\", 32=>\"RECORD\"}"
  #"Map jackDetect: {1=>\"OK\", 2=>\"ATTENTION\", 3=>\"WARNING\"}"
  #"Map updateMode: {0=>\"DISABLED\", 1=>\"ENABLED_UNLOCKED\", 2=>\"ENABLED_LOCKED\", 3=>\"RETURNED_TO_ORIGINAL\", 4=>\"SUCCESSFUL\"}"
  #"Map acSmooth: {0=>\"OFF\", 1=>\"ON\"}"
  #"Map SI: {0=>\"OFF\", 1=>\"ON\"}"
  #"Map tempUnit: {0=>\"C\", 1=>\"F\"}"
  #"Map dBmRef: {16=>\"16\", 0=>\"0\", 600=>\"600\", 50=>\"50\", 8=>\"8\", 25=>\"25\", 75=>\"75\", 4=>\"4\", 1000=>\"1000\", 32=>\"32\"}"
  #"Map pwPol: {0=>\"POS\", 1=>\"NEG\"}"
  #"Map hzEdge: {0=>\"RISING\", 1=>\"FALLING\"}"
  #"Map dcPol: {0=>\"POS\", 1=>\"NEG\"}"
  #"Map contBeep: {0=>\"OFF\", 1=>\"ON\"}"
  #"Map contBeepOS: {0=>\"SHORT\", 1=>\"OPEN\"}"
  #"Map timeFmt: {0=>\"12\", 1=>\"24\"}"
  #"Map numFmt: {0=>\"POINT\", 1=>\"COMMA\"}"
  #"Map lang: {5=>\"JAPANESE\", 0=>\"ENGLISH\", 6=>\"CHINESE\", 1=>\"GERMAN\", 2=>\"FRENCH\", 3=>\"SPANISH\", 4=>\"ITALIAN\"}"
  #"Map dateFmt: {0=>\"MM_DD\", 1=>\"DD_MM\"}"
  #"Map recEventTh: {5=>\"5\", 0=>\"0\", 1=>\"1\", 25=>\"25\", 20=>\"20\", 15=>\"15\", 4=>\"4\", 10=>\"10\"}"
  #"Map rsm: {0=>\"OFF\", 1=>\"ON\"}"
  #"Map ablto: {0=>\"0\", 600=>\"600\", 1200=>\"1200\", 1800=>\"1800\", 300=>\"300\", 900=>\"900\", 1500=>\"1500\"}"
  #"Map digits: {5=>\"5\", 4=>\"4\"}"
  #"Map beeper: {0=>\"OFF\", 1=>\"ON\"}"
  #"Map apoffto: {2700=>\"2700\", 0=>\"0\", 3600=>\"3600\", 900=>\"900\", 1500=>\"1500\", 2100=>\"2100\"}"

  #"Map UNIT: {16=>\"PCT\", 5=>\"ADC\", 11=>\"Hz\", 0=>\"NONE\", 17=>\"dB\", 6=>\"AAC\", 12=>\"S\", 1=>\"VDC\", 18=>\"dBV\", 7=>\"AAC_PLUS_DC\", 13=>\"F\", 2=>\"VAC\", 19=>\"dBm\", 8=>\"A\", 14=>\"CEL\", 3=>\"VAC_PLUS_DC\", 20=>\"CREST_FACTOR\", 9=>\"OHM\", 15=>\"FAR\", 4=>\"V\", 10=>\"SIE\"}"
  #"Map ATTRIBUTE: {5=>\"LO_OHMS\", 0=>\"NONE\", 6=>\"NEGATIVE_EDGE\", 1=>\"OPEN_CIRCUIT\", 7=>\"POSITIVE_EDGE\", 2=>\"SHORT_CIRCUIT\", 8=>\"HIGH_CURRENT\", 3=>\"GLITCH_CIRCUIT\", 4=>\"GOOD_DIODE\"}"
  #"Map STATE: {5=>\"OL\", 0=>\"INACTIVE\", 6=>\"OL_MINUS\", 1=>\"INVALID\", 7=>\"OPEN_TC\", 2=>\"NORMAL\", 3=>\"BLANK\", 4=>\"DISCHARGE\"}"
  #"Map autoRange: {0=>\"MANUAL\", 1=>\"AUTO\"}"
  #"Map unit: {16=>\"PCT\", 5=>\"ADC\", 11=>\"Hz\", 0=>\"NONE\", 17=>\"dB\", 6=>\"AAC\", 12=>\"S\", 1=>\"VDC\", 18=>\"dBV\", 7=>\"AAC_PLUS_DC\", 13=>\"F\", 2=>\"VAC\", 19=>\"dBm\", 8=>\"A\", 14=>\"CEL\", 3=>\"VAC_PLUS_DC\", 20=>\"CREST_FACTOR\", 9=>\"OHM\", 15=>\"FAR\", 4=>\"V\", 10=>\"SIE\"}"
  #"Map bolt: {0=>\"OFF\", 1=>\"ON\"}"
  
  
  
  
  
  
  
  
  
  
  
end