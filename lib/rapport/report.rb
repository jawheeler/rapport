module Rapport
  module Report
  
    @@columns_name_index = 0
    @@columns_key_index = 1
  
    attr_accessor :row_data, :current_model, :options
  
    def report_generator
      ReportGenerator.from(self)
    end
    
    def formatter
      report_generator.formatter
    end
  
    def generate
      report_generator.generate
    end
    
    def options
      @options ||= {:format => 'fake'}
    end

    def each_row
      each_raw_row do |model, row_type|
        self.current_model = model # For error reporting
        yield formatted_row(model, row_type)
      end
    end

    def cell_calculators
      return {}
    end

    # Returns an array of tuples:  [ ['Column Header',:column_calculator],... ]
    def columns
      raise "#columns has not been implemented"
    end

    def column_names
      columns.map{|c| c[@@columns_name_index]}
    end

    def column_keys
      columns.map{|c| c[@@columns_key_index]}
    end

    def table_name
      @table_name ||= options[:report_table_name] || "reports_#{formatter.format_underscore(self.class).sub(/_?report_?/,'')}"
    end
  
    def raw_cell_value(key, model, row_type)
      self.row_data[key] = cell_calculator_for(key,row_type).call(model)
    end
  
    def formatted_cell_value(key, model, row_type)
      raw_value = raw_cell_value(key, model, row_type)
      formatter.format(cell_format_for(key), raw_value)
    end  

    def to_s
      "#{self.class} #{formatter}"
    end

    protected
  
    def section(symbol, section_data = {}, &block)
      self.instance_variable_set(symbol, section_data)
      yield
      self.instance_variable_set(symbol, nil)
    end

    def each_model
      raise "#each_model has not been implemented"
    end

    private
  
    def formatted_row(model, row_type)
      self.row_data = {}
      out = column_keys.map do |key|
        formatted_cell_value(key, model, row_type)
      end
      self.row_data = {}
      out
    end

    def calculators
      @calculators ||= cell_calculators
    end
  
    def base_calculator(key,calculator)
      base_key = key
      if calculator[:map_to]
        return safe_proc(calculator[:map_to]) if calculator[:map_to].respond_to?(:call)
        base_key = calculator[:map_to].to_sym
      end
      lambda_for_key(base_key)
    end
  
    def safe_proc(proc)
      lambda do |m|
        begin
          proc.call(m) 
        rescue NameError => ne 
          nil
        end
      end
    end
  
    def lambda_for_key(key)
      lambda{|m| !m.nil? and m.respond_to?(key) ? m.send(key) : nil }
    end

    def cell_calculator_for(key,row_type)
      calculator = calculators[key] ||= {}
    
      if calculator[row_type].nil?
        base_calculator = base_calculator(key,calculator)
        calculator_for_row_type = if calculator[:through]
          calculator[:through] = [calculator[:through]] unless calculator[:through].is_a?(Enumerable)
          lambda do |m|
            path = m
            calculator[:through].each do |hint|
              if path.respond_to?(hint)
                new_path = path.send(hint)
                path = new_path unless new_path.nil?
              end
            end
            base_calculator.call(path)
          end
        else
          base_calculator
        end
        calculator[row_type] = calculator_for_row_type
      elsif !calculator[row_type].respond_to?(:call) 
        row_type_key = calculator[row_type]
        calculator[row_type] = lambda_for_key(row_type_key)
      end
    
      calculator[row_type]
    end

    def cell_format_for(key)
      calculators[key][:"format_#{options[:format]}"] || calculators[key][:format]
    end
  
  end
end