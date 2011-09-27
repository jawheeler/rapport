module Rapport
  
  class << self
    def safe_proc(proc)
      lambda do |m|
        begin
          proc.call(m) 
        rescue NameError => ne 
          nil
        end
      end
    end

    def safe_send(key)
      lambda{|m| !m.nil? and m.respond_to?(key) ? m.send(key) : nil }
    end
  
    def format_underscore(value)
      value.to_s.gsub(/\W/,'_').gsub(/(.)([A-Z])/,'\1_\2').gsub(/_+/,'_').downcase
    end
  
    def format_camel_case(value)
      value.to_s.capitalize.gsub(/_(.)/){ $1.upcase }
    end
  end
      
end