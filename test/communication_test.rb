require 'test_helper'

class CommunicationTest < Test::Unit::TestCase
  include DMMTestHelper
  
  def setup
    @port = stub()
    @port.stubs(:write)
    @meter = DmmUtil::Fluke28xDriver.new(@port)
  end
  
  def test_open_driver
    SerialPort.expects(:new).with("/some/path", {"parity"=>0, "stop_bits"=>1, "baud"=>115200, "data_bits"=>8}).returns(@port)
    @port.expects(:read_timeout=).with(1)
    DmmUtil::Fluke28xDriver.expects(:new).with(@port).returns(@meter)
    @meter.expects(:valid?).returns(true)
    
    assert_equal @meter, DmmUtil.open_driver("/some/path")
  end
  
  def test_open__invalid_meter
    SerialPort.expects(:new).with("/some/path", {"parity"=>0, "stop_bits"=>1, "baud"=>115200, "data_bits"=>8}).returns(@port)
    @port.expects(:read_timeout=).with(1)
    DmmUtil::Fluke28xDriver.expects(:new).with(@port).returns(@meter)
    @meter.expects(:valid?).returns(false)
    
    assert_raise DmmUtil::MeterError do
      DmmUtil.open_driver("/some/path")
    end
  end
  
  def test_open__file_not_found
    assert_raise Errno::ENOENT do
      DmmUtil.open_driver("/some/nonexisting/path")
    end
  end
  
  def test_valid
    @meter.expects(:id).returns({:model_number => "goo", :software_version => "1.0.1", :serial_number => "12345"})
    assert @meter.valid?
    
    @meter.expects(:id).times(3).raises(DmmUtil::MeterError.new("Some error"))
    assert !@meter.valid?
    
    @meter.expects(:id).times(3).returns({:model_number => "goo", :software_version => nil, :serial_number => nil})
    assert !@meter.valid?
  end
  
  def test_valid__retry
    id_seq = sequence('id_seq')
    
    @meter.expects(:id).in_sequence(id_seq).raises(DmmUtil::MeterError.new("Some error"))    
    @meter.expects(:id).in_sequence(id_seq).returns({:model_number => "goo", :software_version => nil, :serial_number => nil})
    @meter.expects(:id).in_sequence(id_seq).returns({:model_number => "goo", :software_version => "1.0.1", :serial_number => "12345"})
    
    assert @meter.valid?
  end
  
  def test_meter_command__ascii
    @port.expects(:write).with("some long command\r")
    @port.expects(:read).returns("0\r1,2,3\r")
    
    assert_equal ["1", "2", "3"], @meter.meter_command("some long command")
  end
  
  def test_meter_command__ascii_strings
    @port.expects(:write).with("some other command\r")
    @port.expects(:read).returns("0\r'val1',\"val2\",3\r")
    
    assert_equal ["val1", "val2", "3"], @meter.meter_command("some other command")
  end
  
  def test_meter_command__ascii_chopped
    read_sequence = sequence(:read)
    @port.expects(:read).in_sequence(read_sequence).returns("0\r'val1','val2',3")
    @port.expects(:read).in_sequence(read_sequence).times(499).returns("")
    @meter.stubs(:sleep)
    
    assert_raise DmmUtil::MeterError do
      @meter.meter_command("cmd")
    end
  end
  
  def test_meter_command__tick_comma
    @port.expects(:read).returns("0\r\"Valeur, - Fredrik\'s \"\r")
    assert_equal ["Valeur, - Fredrik's "], @meter.meter_command("cmd")
  end
  
  def test_meter_command__tick_and_quote
    @port.expects(:read).returns("0\r'What about \"quote''s\" in string'\r")
    assert_equal ["What about \"quote's\" in string"], @meter.meter_command("cmd")
  end

  def test_meter_command__binary
    @port.expects(:read).returns("0\r#0\0\2\3\4\5\6\r")
    assert_equal "\0\2\3\4\5\6", @meter.meter_command("cmd")
  end
  
  def test_meter_command__binary_chopped
    read_sequence = sequence(:read)
    @port.expects(:read).in_sequence(read_sequence).returns("0\r#0\0\2\3\4\5\6")
    @port.expects(:read).in_sequence(read_sequence).times(499).returns("")
    @meter.stubs(:sleep)
     
    assert_raise DmmUtil::MeterError do
      @meter.meter_command("cmd")
    end
  end
  
  def test_meter_command__wrong_strings    
    assert_raise DmmUtil::MeterError do
      @port.expects(:read).returns("0\r1,string'\r")
      @meter.meter_command("cmd")
    end

    assert_raise DmmUtil::MeterError do
      @port.expects(:read).returns("0\r1,string\"\r")
      @meter.meter_command("cmd")
    end

    assert_raise DmmUtil::MeterError do
      @port.expects(:read).returns("0\r1,\"str\r")
      @meter.meter_command("cmd")
    end

    assert_raise DmmUtil::MeterError do
      @port.expects(:read).returns("0\r1'str\r")
      @meter.meter_command("cmd")
    end
     
    assert_raise DmmUtil::MeterError do
      @port.expects(:read).returns("0\r1'str'1\r")
      @meter.meter_command("cmd")
    end
    
    assert_raise DmmUtil::MeterError do
      @port.expects(:read).returns("0\r1\"str\"1\r")
      @meter.meter_command("cmd")
    end
  end
  
  def test_meter_command__error
    @port.expects(:read).returns("2\r")
    error_raised = false

    begin
      @meter.meter_command("cmd")
    rescue DmmUtil::MeterError => e
      error_raised = true
      assert_equal 2, e.status
      assert_equal "Command returned error code 2", e.message
    end

    assert error_raised, "Error was not raised"
  end
  
  def test_meter_command__invalid_data
    @port.expects(:read).returns("invalid!")
    error_raised = false

    begin
      @meter.meter_command("cmd")
    rescue DmmUtil::MeterError => e
      error_raised = true
      assert_equal nil, e.status
      assert_equal "Error parsing status from meter (Non-OK status with extra data on end)", e.message
    end

    assert error_raised, "Error was not raised"
  end
  
  def test_meter_command__retry_on_error_8
     @port.expects(:write).with("command\r").times(3)
     
     read_seq = sequence('read_seq')
     @port.expects(:read).in_sequence(read_seq).returns("8\r")
     @port.expects(:read).in_sequence(read_seq).returns("8\r")
     @port.expects(:read).in_sequence(read_seq).returns("0\rresult\r")
     
     assert_equal ['result'], @meter.meter_command("command")
  end
  
end