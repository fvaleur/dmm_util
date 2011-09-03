require 'rubygems'
require 'serialport'
require 'enumerator'

### It appears thwe are 32 bit vals:
## Mulit-map values
# Sequence numbers
# duration

module DmmUtil  
  class Fluke28xDriver    
    MPQ_PROPS = [:company, :contact, :operator, :site]
    MP_PROPS  = {:dcpol => [:pos, :neg], :rsm => [:off, :on], :si => [:off, :on], 
                 :lang => [:japanese, :english, :chinese, :german, :french, :spanish, :italian], 
                 :apoffto => [2700, 0, 3600, 900, 1500, 2100], :hzedge => [:rising, :falling], :lcdcont => :int, :acsmooth => [:off, :on], 
                 :numfmt => [:point, :comma], :beeper => [:off, :on], :pwpol => [:pos, :neg], :aheventth => :int, 
                 :timefmt => [12, 24], :cusdbm => :int, :dbmref => [16, 0, 600, 50, 8, 25, 75, 4, 1000, 32], 
                 :receventth => [5, 0, 1, 25, 20, 15, 4, 10], :contbeepos => [:short, :open], :digits => [5, 4], :tempos => :int, 
                 :clock => :timeval, :contbeep => [:off, :on], :ablto => [0, 600, 1200, 1800, 300, 900, 1500], 
                 :tempunit => [:c, :f], :datefmt => [:mm_dd, :dd_mm]}
                 
    include FormatConvertors
    
    def initialize(port)
      @port = port
      @map_cache = {}
    end
    
##########  High level commands  ################

    def valid?
      3.times do  
        begin
          res = self.id
          return true if res[:model_number] && res[:software_version] && res[:serial_number]
        rescue MeterError
        end
      end
      return false
    end
    
##########   Fluke28xDrivercommands    ##################    

    def id
      res = meter_command("ID") 
      {:model_number => res[0], :software_version => res[1], :serial_number => res[2]}      
    end

    def qdda
      res = meter_command("qdda")
      
      mode_count = Integer(res[8])
      reading_count = Integer(res[9 + mode_count])
      raise DmmUtil::MeterError("Error parsing qdda response") unless res.size == 10 + mode_count + reading_count * 9
      
      reading_map = {}
      res[(10 + mode_count)..-1].each_slice(9) do |reading|
        reading_map[reading[0]] = {:value => Float(reading[1]), 
                                   :unit => reading[2], :unit_multiplier => Integer(reading[3]), 
                                   :decimals => reading[4].to_i,
                                   :state => reading[6], :ts => parse_time(reading[8].to_f),
                                   :display_digits => Integer(reading[5]), :attribute => reading[7]}
       end
      
      {:prim_function => res[0], :sec_function => res[1], :mode => res[9,mode_count], 
       :auto_range => res[2], :range_max => Integer(res[4]),
       :unit => res[3], :unit_multiplier => Integer(res[5]),
       :bolt => res[6], :ts => (res[7].to_i == 0 ? nil : parse_time(Float(res[7]))),
       :readings => reading_map}
    end
    
    def qddb
      bytes = meter_command("qddb")
      
      reading_count = get_u16(bytes, 32)
      raise MeterError.new("qddb parse error, expected #{reading_count * 30 + 34} bytes, got #{bytes.size}") unless bytes.size == reading_count * 30 + 34
      tsval = get_double(bytes, 20)
      # all bytes parsed
      {
        :prim_function => get_map_value(:primfunction, bytes, 0), 
        :sec_function => get_map_value(:secfunction, bytes, 2),
        :auto_range => get_map_value(:autorange, bytes, 4),
        :unit => get_map_value(:unit, bytes, 6),
        :range_max => get_double(bytes, 8),
        :unit_multiplier => get_s16(bytes, 16),
        :bolt => get_map_value(:bolt, bytes, 18),
        :ts => (tsval < 0.1) ? nil : parse_time(tsval), # 20
        :mode => get_multimap_value(:mode, bytes, 28),
        :un1 => get_u16(bytes, 30),
        # 32 is reading count
        :readings => parse_readings(bytes[34 .. -1])
      }
    end
    
    def qsls
      res = meter_command("qsls")
      {:recording => Integer(res[0]), :min_max => Integer(res[1]), 
       :peak => Integer(res[2]), :measurement => Integer(res[3])}
    end
    
    def qsmr(idx)
      # Get saved measurement
      res = meter_command("qsmr #{idx}")

      reading_count = get_u16(res, 36)
      raise MeterError.new("qsmr parse error, expected at least #{reading_count * 30 + 38} bytes, got #{res.size}") unless res.size >= reading_count * 30 + 38
      
      { :seq_no => get_u16(res,0),
        :un1 => get_u16(res,2),   # 32 bit?
        :prim_function =>  get_map_value(:primfunction, res,4), # prim?
        :sec_function => get_map_value(:secfunction, res,6), # sec?
        :auto_range => get_map_value(:autorange, res, 8),
        :unit => get_map_value(:unit, res, 10),
        :range_max => get_double(res, 12),
        :unit_multiplier => get_s16(res, 20),
        :bolt => get_map_value(:bolt, res, 22),
        :un4 => get_u16(res,24),  # ts?
        :un5 => get_u16(res,26),
        :un6 => get_u16(res,28),
        :un7 => get_u16(res,30),
        :mode => get_multimap_value(:mode, res,32),
        :un9 => get_u16(res,34),
        # 36 is reading count
        :readings => parse_readings(res[38, reading_count * 30]),
        :name => res[(38 + reading_count * 30)..-1],
      }
    end
    
    def qmmsi(idx)
      # Get min/max      
      do_min_max_cmd("qmmsi", idx)
    end
    
    def qpsi(idx)
      # Recorded peak 
      do_min_max_cmd("qpsi", idx)
    end
    
    def qrsi(idx)
      # Recorded session info
      res = meter_command("qrsi #{idx}")
      reading_count = get_u16(res, 76)
      raise MeterError.new("qrsi parse error, expected at least #{reading_count * 30 + 78} bytes, got #{res.size}") unless res.size >= reading_count * 30 + 78
      
      # All bytes parsed
      {
        :seq_no => get_u16(res, 0),
        :un2 => get_u16(res, 2),   # 32 bits?
        :start_ts => parse_time(get_double(res, 4)),
        :end_ts => parse_time(get_double(res, 12)),
        :sample_interval => get_double(res, 20),
        :event_threshold => get_double(res, 28),
        :reading_index => get_u16(res, 36), # 32 bits?
        :un3 => get_u16(res, 38),
        :num_samples => get_u16(res, 40),  # Is this 32 bits? Whats in 42
        :un4 => get_u16(res, 42),
        :prim_function => get_map_value(:primfunction, res, 44), # prim?
        :sec_function => get_map_value(:secfunction, res, 46), # sec?
        :auto_range => get_map_value(:autorange, res, 48),
        :unit => get_map_value(:unit, res, 50),
        :range_max  => get_double(res, 52),
        :unit_multiplier => get_s16(res, 60),
        :bolt => get_map_value(:bolt, res, 62),  #bolt?
        :un8 => get_u16(res, 64),  #ts3?
        :un9 => get_u16(res, 66),  #ts3?
        :un10 => get_u16(res, 68),  #ts3?
        :un11 => get_u16(res, 70),  #ts3?
        :mode => get_multimap_value(:mode, res, 72),
        :un12 => get_u16(res, 74),
        # 76 is reading count
        :readings => parse_readings(res[78, reading_count * 30]),
        :name => res[(78 + reading_count * 30)..-1]
      }
    end

    def qsrr(reading_idx, sample_idx)
      res = meter_command("qsrr #{reading_idx},#{sample_idx}", 149)

      raise  MeterError.new("Invalid block size: #{res.size} should be 146") unless res.size == 146
      # All bytes parsed - except there seems to be single byte at end?
      {
        :start_ts =>  parse_time(get_double(res, 0)),
        :end_ts =>  parse_time(get_double(res, 8)),
        :readings => parse_readings(res[16, 30*3]),
        :duration => get_u16(res, 106) * 0.1,
        :un2 => get_u16(res, 108),
        :readings2 => parse_readings(res[110,30]),
        :record_type =>  get_map_value(:recordtype, res, 140),
        :stable   => get_map_value(:isstableflag, res, 142), 
        :transient_state => get_map_value(:transientstate, res, 144)
      }      
    end
    
    def qemap(map_name)
      res = meter_command("qemap #{map_name.to_s}")
      entry_count = Integer(res.shift)
      raise MeterError.new("Error parsing qemap") unless res.size == entry_count * 2
      
      map = {}
      res.each_slice(2) do |key, val|
        map[Integer(key)] = val
      end
      map
    end
    
    MPQ_PROPS.each do |mpq_prop|
      define_method(mpq_prop) do
        self.meter_command("qmpq #{mpq_prop}")[0]
      end
      
      define_method("#{mpq_prop}=") do |val|
        self.meter_command("mpq #{mpq_prop},#{quote_str(val)}", 0)
      end
    end
    
    MP_PROPS.each do |mp_prop, format|
      define_method(mp_prop) do
        val = self.meter_command("qmp #{mp_prop}")[0]
        if format == :int
          val = Integer(val)
        elsif format == :timeval
          tz_offset = Time.now.utc_offset
          val = Time.at(Integer(val) - tz_offset)
        end
        val
      end
      
      define_method("#{mp_prop}=") do |val|
        if format.is_a?(Array)
          raise MeterError.new("Illegal value '#{val}' for #{mp_prop}. Legal values: #{format.join(", ")}") unless format.include?(val)
        elsif format == :int
          raise MeterError.new("Illegal value '#{val}' for #{mp_prop}. Must be integer.") unless val.is_a?(Integer)
        elsif format == :timeval
          raise MeterError.new("Clock command requires a Time object.") unless val.is_a?(Time)
          tz_offset = Time.now.utc_offset
          val = val.to_i + tz_offset
        end
        self.meter_command("mp #{mp_prop},#{val}",0)
      end
    end
      
    
##########   Low level stuff   ##########
    def do_min_max_cmd(cmd, idx)
      res = meter_command("#{cmd} #{idx}")
      # un8 = 0, un2 = 0, always bolt
      reading_count = get_u16(res, 52)
      raise MeterError.new("qsmmsi parse error, expected at least #{reading_count * 30 + 54} bytes, got #{res.size}") unless res.size >= reading_count * 30 + 54
      
      # All bytes parsed
      { :seq_no => get_u16(res, 0),
        :un2 => get_u16(res, 2),      # High byte of seq no?
        :ts1 => parse_time(get_double(res, 4)),
        :ts2 => parse_time(get_double(res, 12)),
        :prim_function => get_map_value(:primfunction, res, 20),
        :sec_function => get_map_value(:secfunction, res, 22),
        :autorange => get_map_value(:autorange, res, 24),
        :unit => get_map_value(:unit, res, 26),
        :range_max  => get_double(res, 28),
        :unit_multiplier => get_s16(res, 36),
        :bolt => get_map_value(:bolt, res, 38),
        :ts3 => parse_time(get_double(res, 40)),
        :mode => get_multimap_value(:mode, res, 48), 
        :un8 => get_u16(res, 50),
        # 52 is reading_count
        :readings => parse_readings(res[54, reading_count * 30]),
        :name => res[(54 + reading_count * 30)..-1]
        }
    end

    def parse_readings(reading_bytes)
      readings = {}
      ByteStr.new(reading_bytes).each_slice(30) do |reading_arr|
        r = reading_arr.map{|b| b.chr}.join
        # All bytes parsed
        readings[get_map_value(:readingid, r, 0)] = {
                               :value => get_double(r, 2),
                               :unit => get_map_value(:unit, r, 10),
                               :unit_multiplier => get_s16(r, 12),
                               :decimals => get_s16(r, 14),
                               :display_digits => get_s16(r, 16), 
                               :state => get_map_value(:state, r, 18),
                               :attribute => get_map_value(:attribute, r, 20),
                               :ts => get_time(r, 22)
        }
      end
      readings
    end
  
      
    def get_map_value(map_name, str, offset)
      map = @map_cache[map_name.to_sym] ||= qemap(map_name)
      value = get_u16(str, offset)
      raise MeterError.new("Can not find key #{value} in map #{map_name}") unless map.has_key?(value)
      map[value]
    end
    
    def get_multimap_value(map_name, str, offset)
      map = @map_cache[map_name.to_sym] ||= qemap(map_name)
      value = get_u16(str, offset)
      check = 0
      ret = []
      map.keys.sort.each do |key|
        if (value & key) != 0
          ret << map[key]
          check |= key
        end
      end
      raise MeterError.new("Can not find key #{value} in map #{map_name}") unless check == value
      ret
    end
    
    def data_ok?(data, count)      
      # No status code yet
      return false if data.size < 2
      
      # Non-OK status
      return true if data.size == 2 && data[0,1] != "0" && data[1,1] == "\r"
      
      # Non-OK status with extra data on end
      raise MeterError.new("Error parsing status from meter (Non-OK status with extra data on end)") if data.size > 2 && data[0,1] != "0"
      
      # We should now be in OK state
      raise MeterError.new("Error parsing status from meter (status:#{data[0,1]} size:#{data.size})") unless data[0,1] == "0" && data[1,1] == "\r"
      
      if count
        data.size == count
      else
        data.size >= 4 && data[-1,1] == "\r"
      end
      
    end
    
    def read_retry(count)
      retry_count = 0
      data = ""
      
      while retry_count < 500 && !data_ok?(data, count)
        data += @port.read
        return data if data_ok?(data, count)
        sleep 0.01
        retry_count += 1
      end
      raise MeterError.new("Error parsing status from meter: #{data[0,1]} #{data.size} #{data[1,1] == "\r"} #{data[-1,1] == "\r"}")
    end
    
    def meter_command(cmd, expected_result = nil)
      @port.write "#{cmd}\r"
      data = read_retry(expected_result ? (expected_result + 2) : nil )
      status = data[0,1]
      raise MeterError.new("Command returned error code #{status}", Integer(status)) unless status == "0"
      raise MeterError.new("Did not receive complete reply from meter") unless data[-1,1] == "\r"
      
      binary = (data[2,2] == "#0")
      
      if binary
        data[4..-2]
      else
        tokens = []
        state = :init
        current_token = []
        data[2..-2].each_byte do |b|
          c = b.chr
          case state
          when :init
            case c
            when ","
              tokens << current_token.join
              current_token = []
            when "'"
              raise MeterError.new("Unexpected quote") unless current_token.empty?
              state = :sq
            when '"'
              raise MeterError.new("Unexpected double-quote") unless current_token.empty?
              state = :dq
            else
              current_token << c
            end
          when :sq
            case c
            when "'"
              state = :sqe
            else
              current_token << c
            end
          when :sqe
            case c
            when "'"
              current_token << c
              state = :sq
            when ","
              tokens << current_token.join
              current_token = []
              state = :init
            else
              raise MeterError.new("Expected comma after single-quoted string")
            end
          when :dq
            case c
            when '"'
              state = :dqe
            else
              current_token << c
            end
          when :dqe
            case c
            when ","
              tokens << current_token.join
              current_token = []
              state = :init
            else
              raise MeterError.new("Expected comma after double-quoted string")
            end
          else
            raise MeterError.new("Invalid parser state")
          end
        end

        raise MeterError.new("Did not find end of string") unless [:init, :sqe, :dqe].include?(state)
        tokens << current_token.join 
        
      end
    rescue MeterError => e
      if e.status == 8
        retry
      else
        raise
      end  
    end
    
  end
  
  class ByteStr < String
    alias :each :each_byte
  end
  


  
end