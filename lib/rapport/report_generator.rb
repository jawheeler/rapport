require 'logger'

module Rapport
  module ReportGenerator
    
    def self.from(report)
      options = report.options
      Rapport.const_get("ReportGenerator#{Rapport.format_camel_case(options[:format].to_s)}").from(report)
    end   
    
    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set(:@cell_formatter, CellFormatter.new)
      def base.inherited(subclass)
        super(subclass)
        subclass.instance_variable_set(:@cell_formatter, base.instance_variable_get(:@cell_formatter).dup)
      end      
    end
    
    module ClassMethods
      # Override to customize the report generator based on the charactersistics of the report or its options
      # Default implementation uses default constructor and assigns to the report attribute.
      def from(report)
        out = self.new
        out.report = report
        out
      end
      
      def generate_with(&block)
        raise "Only one call to generate_with is permitted (or none if #generate is implemented)" if public_method_defined?(:generate)
        define_method :generate do
          raise "No report to generate!" if report.nil?
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
        instance_variable_get(:@cell_formatter).add_cell_format(type, &block)
      end
    end
    
    attr_accessor :report
    
    def options
      report.options
    end
    
    def cell_formatter
      @cell_formatter ||= self.class.instance_variable_get(:@cell_formatter).dup
    end
    
    def format(type, value)
      cell_formatter.format(type, value)
    end
  
    def method_missing(method, *args)
      if method == :logger
        if Module.const_defined?("Rails")
          Rails.logger
        else
          @_logger ||= Logger.new(STDERR)
        end
      else
        super(method, *args)
      end
    end
    
    def each_row
      report.each_row {|row| yield row }
    end    

  end
  
  class CellFormatter
    
    def initialize(procs = {})
      @procs = procs
    end
    
    def dup
      CellFormatter.new(@procs.dup)
    end
    
    def add_cell_format(type, &block)
      proc = Proc.new(&block)
      @procs[type] = proc
      @procs[Rapport.format_underscore(type.to_s)] = proc if type.is_a?(Class)
      
      # Support ActiveSupport::TimeWithZone automatically
      if type == Time
        add_cell_format(ActiveSupport::TimeWithZone, &block) if type == Time rescue nil
      end
      
    end

    def format(type,value)
      if type.is_a?(Proc)
        type.call(value)
      else 
        proc = @procs[type] || @procs[value.class]
        proc.nil? ? value : proc.call(value)
      end
    end
  end

end