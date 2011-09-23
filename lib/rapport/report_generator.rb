require 'logger'

module Rapport
  module ReportGenerator
    
    def self.from(report)
      options = report.options
      Rapport.const_get("ReportGenerator#{Rapport.format_camel_case(options[:format].to_s)}").new(report)
    end   
    
    def self.included(base)
      base.extend(ClassMethods)
      def base.all_cell_formats
        @all_cell_formats ||= {}
      end
    end
    
    module ClassMethods
      
      def generate_with(&block)
        raise "Only one call to generate_with is permitted" if public_method_defined?(:generate)
        define_method :generate do
          out = nil
          begin
            logger.info("Generating #{report}...")
            out = block.call
            logger.info("Generated #{report}.")
          rescue Exception => e
            error = report.current_model.nil? ? '' : "While processing:\n\n#{report.current_model.inspect}\n\n"
            error += "#{report} failed:\n\n#{e.message}\n\n#{e.backtrace.join("\n")}"
            logger.error(error)
            logger.mail(:error,error) if logger.respond_to?(:mail)
          end
          out
        end
      end
      
      def cell_format(type, &block)
        all_cell_formats[:"format_#{type}"] = Proc.new(&block)
      end
    end
    
    attr_accessor :options
    
    def formatter
      @formatter ||= ReportFormatter.new(self.class.all_cell_formats)
    end
  
    def method_missing(method, *args)
      if method == :logger
        if Rails
          Rails.logger
        else
          @_logger ||= Logger.new(STDERR)
        end
      else
        super(method, *args)
      end
    end
    
    private
    
    def self.camel_case(value)
      value.capitalize.gsub(/_(.)/){ $1.upcase }
    end 

  end
  
  class ReportFormatter
    def initialize(procs)
      @procs = procs
    end
    
    def initialize(options = {})
      @options = options
    end

    def to_s
      @options[:format]
    end

    def format(type,value)
      return type.call(value) if type.is_a?(Proc)
      method_name = nil
      if type.nil?
        method_name = :"format_#{format_underscore(value.class)}"
      else
        method_name = :"format_#{type.to_s}"
      end

      if !method_name.nil? && self.class.method_defined?(method_name)
        self.send(method_name,value)
      else
        value
      end
    end
    
    def format_underscore(value)
      Rapport.format_underscore(value)
    end

    def format_camel_case(value)
      Rapport.format_camel_case(value)
    end    
    
    def method_missing(method, value)
      @procs[method].call(value)
    end
  end
  
  def self.format_underscore(value)
    value.to_s.gsub(/\W/,'').gsub(/(.)([A-Z])/,'\1_\2').gsub(/_+/,'_').downcase
  end
  
  def self.format_camel_case(value)
    value.capitalize.gsub(/_(.)/){ $1.upcase }
  end
end