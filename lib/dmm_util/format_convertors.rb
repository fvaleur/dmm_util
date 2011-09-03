module DmmUtil
  
  module FormatConvertors
    
    def get_u16(str, offset)
      lo_byte = str[offset]
      hi_byte = str[offset + 1]
      hi_byte * 0x100 + lo_byte
    end

    def get_s16(str, offset)
      val = get_u16(str, offset)
      unless (val & 0x8000) == 0
        val = -(0x10000 - val)
      end
      val
    end
    
    def get_double(str, offset)
      bytestr = str[offset, 8]
      endianstr = bytestr[0,4].reverse + bytestr[4,4].reverse
      endianstr.unpack("G")[0]
    end
    
    def get_time(str, offset)
      parse_time(get_double(str, offset))
    end
    
    def parse_time(t)
      tz_offset = Time.now.utc_offset
      Time.at(t - tz_offset)
    end
    
    def quote_str(str)
      has_single = str.include?("'")
      has_double = str.include?('"')
      
      if has_single && !has_double
        "\"#{str}\""
      else
        "'#{str.gsub(/'/, "''")}'"
      end
    end
    
  end
end