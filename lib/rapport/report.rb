module Rapport
  module Report
  
    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set(:@columns, [])
      base.instance_variable_set(:@cell_calculators, {})
      def base.inherited(subclass)
        super(subclass)
        subclass.instance_variable_set(:@columns, base.instance_variable_get(:@columns).dup )
        subclass.instance_variable_set(:@cell_calculators, base.instance_variable_get(:@cell_calculators).dup )
      end
    end
    
    module ClassMethods
      attr_accessor :row_data
      
      def column(*args, &block)
        raise ArgumentError.new("wrong number of arguments (#{args.length} for 1,2, or 3)") unless args.length >= 1 and args.length <= 3
        header = args[0]
        if args.length == 3
          symbol = args[1].to_sym; options = args[2].to_hash
        elsif args.length == 2
          if args[1].is_a?(Symbol)
            symbol = args[1]; options = {}
          else
            symbol = Rapport.format_underscore(header.downcase).to_sym; options = args[1].to_hash
          end
        end
        add_calculator(symbol, options) unless options.nil?
        instance_variable_get(:@columns) << [header, symbol]
      end
      
      private
      
      def add_calculator(symbol, options)
        instance_variable_get(:@cell_calculators)[symbol] = options
      end
    end
    
    attr_accessor :section_data, :current_model, :options
    
    def row_data
      self.class.row_data
    end
  
    def report_generator
      @_report_generator ||= ReportGenerator.from(self)
    end
  
    def generate
      report_generator.generate
    end
    
    def options
      @options ||= {:format => 'fake'}
    end
      
    def each_row
      each_model do |model, row_type|
        self.current_model = model # For error reporting
        yield formatted_row(model, row_type || Rapport.format_underscore(model.class.to_s))
      end
    end
    
    def columns
      if @_columns.nil?
        @_columns = []
        self.class.send(:instance_variable_get, :@columns).each {|col| @_columns << col.dup }
      end
      @_columns
    end
  
    def column_headers
      @_column_headers ||= columns.map{|c| c[0]}
    end
  
    def column_symbols
      @_column_symbols ||= columns.map{|c| c[1]}
    end
    
    def to_model_class
      @_to_model_class ||= Struct.new("#{self.class}Model", *column_symbols)
    end
  
    def table_name
      @table_name ||= options[:report_table_name] || "reports_#{Rapport.format_underscore(self.class).sub(/_?report_?/,'')}"
    end
  
    def raw_cell_value(key, model, row_type)
      self.row_data[key] = cell_calculator_for(key,row_type).call(model)
    end
  
    def formatted_cell_value(key, model, row_type)
      row_data[key] = raw_value = raw_cell_value(key, model, row_type)
      report_generator.format(cell_format_for(key), raw_value)
    end  
  
    def to_s
      [self.class, options[:format]].compact.map{|p| p.to_s }.join(' ')
    end
  
    protected
  
    def section(section_data = {}, &block)
      self.section_data = section_data
      yield
      self.section_data = nil
    end
  
    def each_model(&block)
      raise "#each_model has not been implemented"
    end
  
    private
  
    def formatted_row(model, row_type)
      self.class.row_data = {}
      out = column_symbols.map do |key|
        formatted_cell_value(key, model, row_type)
      end
      self.class.row_data = {}
      out
    end
  
    def _calculators
      @_calculators ||= self.class.send(:instance_variable_get, :@cell_calculators).dup
    end
    
    def cell_calculator_for(key,row_type)
      calculator = _calculators[key] ||= {}
    
      if calculator[row_type].nil?
        base_calculator = base_calculator(key,calculator)
        calculator_for_row_type = if calculator[:through]
          calculator[:through] = [calculator[:through]] unless calculator[:through].is_a?(Enumerable)
          through_calculator(calculator[:through], base_calculator)
        else
          base_calculator
        end
        calculator[row_type] = calculator_for_row_type
      elsif !calculator[row_type].respond_to?(:call) 
        row_type_key = calculator[row_type]
        calculator[row_type] = Rapport.safe_send(row_type_key)
      end
    
      calculator[row_type]
    end
    
    def through_calculator(throughs, base_calculator)
      lambda do |m|
        path = m
        throughs.each do |hint|
          if path.respond_to?(hint)
            new_path = path.send(hint)
            path = new_path unless new_path.nil?
          end
        end
        base_calculator.call(path)
      end      
    end    
  
    def base_calculator(key, calculator)
      base_key = key
      if calculator[:map_to]
        return Rapport.safe_proc(calculator[:map_to]) if calculator[:map_to].respond_to?(:call)
        base_key = calculator[:map_to].to_sym
      end
      Rapport.safe_send(base_key)
    end
  
    def cell_format_for(key)
      _calculators[key][:"format_#{options[:format]}"] || _calculators[key][:format]
    end
  
  end
end