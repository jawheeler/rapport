require File.dirname(__FILE__) + '/../test_helper'

class ReportTest < Test::Unit::TestCase
  setup do
    @report = TestReport.new
  end
  
  context ".each_row" do
    execute do
      execute_result = []
      @report.each_row {|row| execute_result << row}
      execute_result
    end
  
    should "return a row for each raw row" do
      raw_rows = []
      @report.each_model {|row| raw_rows << row}
      assert_equal raw_rows.length, @execute_result.length
    end
  
    should "return formatted rows" do
      assert_match /Formatted/, @execute_result[0][2]
    end
  end
  
  context ".column_headers" do
    execute do
      @report.column_headers
    end
  
    should "return column headers only" do
      @execute_result.each do |column_header|
        assert_match /Column/, column_header
      end
    end
  end
  
  context ".column_symbols" do
    execute do
      @report.column_symbols
    end
  
    should "return symbols only" do
      @execute_result.each do |column_symbol|
        assert_match /calc/, column_symbol.to_s
      end
    end
  end
  
  context ".table_name" do
    should "return a configured table name" do
      @report.options[:report_table_name] = 'llama'
      assert_equal 'llama', @report.table_name
    end
  
    should "return a table name based on the reports actual class if :report_class isn't configured" do
      assert_equal 'reports_test', @report.table_name
    end
  
  end
  
  context ".cell_calculator_for" do
  
    setup do
      @lambda = lambda{ 'hi' }
    end
  
    execute do
      @report.bypass._calculators[:key] = @cell_calculator
      @report.bypass.cell_calculator_for(:key, :row_type)
    end
  
    share_setup("with :through") do
      @cell_calculator[:through] = :child
    end      
  
    share_should("return a proc") do
      assert @execute_result.respond_to?(:call)
    end
  
    share_should "return the lambda" do
      assert_equal @lambda, @execute_result
    end
  
    share_should "wrap the lambda" do
      assert_equal 'hi', @execute_result.call(Struct.new(:child).new)
    end
  
    share_should("return a proc sending") do |symbols|
      model = mock('model')
      symbols = [symbols] if symbols.is_a?(Symbol)
      symbols.each do |symbol|
        model.expects(symbol).returns(model)
      end
      @execute_result.call(model)
    end     
  
    share_should("return a proc never sending") do |symbols|
      model = mock('model')
      symbols = [symbols] if symbols.is_a?(Symbol)
      symbols.each do |symbol|
        model.expects(symbol).never
      end
      @execute_result.call(model)
    end      
  
    context "explicit row type with lambda" do
      setup do
        @cell_calculator = {
          :row_type => @lambda
        }
      end
    
      use_should("return the lambda")
      use_setup("with :through").use_should("return the lambda")
    end
  
    context "explicit row type with symbol" do
      setup do
        @cell_calculator = {
          :row_type => :foo
        }
      end
    
      use_should("return a proc sending").given("method"){ :foo }
          
      use_setup("with :through").context do
        use_should("return a proc sending").given("method"){ :foo }
        use_should("return a proc never sending").given("through"){ :child }
      end
    end
  
    context "map_to with lambda" do
      setup do
        @cell_calculator = {
          :map_to => @lambda
        }
      end
    
      use_should("wrap the lambda")
    
      use_setup("with :through").context do
        use_should("return a proc sending").given("through"){ :child }
        use_should("wrap the lambda")
      end
    end
  
    context "map_to with symbol" do
      setup do
        @cell_calculator = {
          :map_to => :foo
        }
      end
    
      use_should("return a proc")
      use_should("return a proc sending").given("method"){ :foo }
    
      use_setup("with :through").use_should("return a proc sending").given("through and method"){ [:child, :foo] }
  
    end
  
    context "through list" do
      setup do
        @cell_calculator = {
          :through => [:first, :second]
        }
      end
    
      should "work for a model with first and second" do
        model = mock
        first_model = mock
        second_model = mock
        model.expects(:first).returns(first_model)
        first_model.expects(:second).returns(second_model)
        second_model.expects(:key)
        @execute_result.call(model)
      end
    
      should "work for a model with only first" do
        model = mock
        first_model = mock
        model.expects(:first).returns(first_model)
        first_model.expects(:key)
        @execute_result.call(model)
      end
    
      should "use second if model returns nil for first" do
        model = mock
        second_model = mock
        model.expects(:first).returns(nil)
        model.expects(:second).returns(second_model)
        second_model.expects(:key)
        @execute_result.call(model)
      end
    
      should "work for a model with only second" do
        model = mock
        second_model = mock
        model.expects(:second).returns(second_model)
        second_model.expects(:key)
        @execute_result.call(model)
      end
    
      should "work for a model with neither" do
        model = mock
        model.expects(:key)
        @execute_result.call(model)
      end
    end
  end # end .cell_calculator_for
  
  context ".safe_proc" do
    setup do
      @orig_proc = lambda{|m| m.foo }
    end
       
    execute do
      @proc = Rapport.safe_proc(@orig_proc)
      @proc.call(@model)
    end
  
    use_should("return nil").when("model doesn't respond correctly") { @model = Struct.new(:no_foo).new('happy') }
  
    context "nil model" do
      setup do
        @model = nil
      end
    
    
      use_should("return nil").when("unhappy proc")
    
      context "happy proc" do
        setup do
          @orig_proc = lambda { 'happy' }
        end
      
        should "be happy" do
          assert_equal 'happy', @execute_result
        end          
      end
    end
  
    context "happy model" do
      setup do
        @model = Struct.new(:foo).new('happy')
      end
    
      should "be happy" do
        assert_equal 'happy', @execute_result
      end
    end
  end
end