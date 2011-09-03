require 'dmm_util/format_convertors'
require 'dmm_util/fluke28x_driver'
require 'dmm_util/meter'
require 'dmm_util/cursor'
require 'dmm_util/recording'
require 'dmm_util/recording_measurement'
require 'dmm_util/recording_measurement_cursor'
require 'dmm_util/measurement'
require 'dmm_util/reading'


module DmmUtil
  
  def self.open
    driver = nil
    Dir.glob("/dev/tty.usbserial*").each do |tty_path|
      begin
        driver = open_driver(tty_path)
      rescue DmmUtil::MeterError
        $stderr.write "Warning: Did not find meter at #{tty_path}"
      end
    end
    raise "Could not find a valid meter, are you sure it is connected and turned on?" unless driver
    Meter.new(driver)
  end
  
  def self.open_driver(tty_path)
    port = SerialPort.new(tty_path, {"parity"=>0, "stop_bits"=>1, "baud"=>115200, "data_bits"=>8})
    port.read_timeout = 1
    meter = Fluke28xDriver.new(port)
    
    raise MeterError.new("Device at #{tty_path} does not seem to be a supported DMM") unless meter.valid?
    meter
  end
  
end