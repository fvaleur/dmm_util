require 'ostruct'

module DmmUtil  

  class Measurement
    attr_reader :raw
    
    def initialize(attrs)
      @raw = attrs
    end
    
    def name
      raw[:name] || raise("Not a named measurement")
    end
    
    def ts 
      raw[:ts] || self.primary.ts
    end
    
    def prim_function
      raw[:prim_function]
    end
    
    def reading_names
      raw[:readings].keys.map{|r| r.downcase.to_sym}
    end
    
    def to_s
      order = [:primary, :maximum, :average, :minimum, :rel_reference, 
               :secondary,
               :db_ref, :temp_offset,
               :live, :rel_live]
      existing = reading_names
      res = []
      
      existing.delete(:live) if existing.include?(:live) && self.live == self.primary
      
      (order - [:primary]).each do |name|
        next unless existing.include?(name)
        res << "#{name}: #{self.send(name).to_s}"
      end
      
      (existing - order).each do |name|
        res << "#{name}: #{self.send(name).to_s}"
      end
      
      if res.empty?
        primary.to_s
      else
        "#{primary.to_s} (#{res.join(", ")})"
      end
    end
    
    def method_missing(meth, *args)
      if raw[:readings].has_key?(meth.to_s.upcase)
         Reading.new(raw[:readings][meth.to_s.upcase])
      else
        super
      end
    end
    
  end

end