require File.dirname(__FILE__) + '/../test_helper'

class ReportTest < Test::Unit::TestCase
  setup do
    @report = Rapport::TestReport.new(:format => 'test')
    @report_generator = @report.report_generator
  end
  
  context "ReportGenerator.generate_with" do
    setup do
      @class = Class.new
      @class.send(:include, Rapport::ReportGenerator)
      @proc = lambda { 'hello' }
    end
    
    execute do
      proc = @proc
      @class.class_eval do
        generate_with do
          proc.call
        end
      end
    end
    
    should "define #generate" do
      assert @class.public_method_defined?(:generate)
    end
    
    should "produce #generate with logging that returns whatever the generate_with block returns" do
      rg = @class.new
      rg.report = Rapport::TestReport.new
      Logger.any_instance.expects(:info).twice
      assert_equal 'hello', rg.generate
    end
    
    context "error handling" do
      setup do
        @proc = lambda { @report.current_model = 'current_model'; raise "Boom!" }
      end
      
      should "log the current model" do
        rg = @class.new
        rg.report = @report = Rapport::TestReport.new
        @error = ''
        Logger.any_instance.expects(:info)
        Logger.any_instance.expects(:error).with{|message| @error = message }
        rg.generate
        assert_match /current_model/, @error
        assert_match /#{@report}/, @error
      end
    end
    
  end
  
  context "cell formatter" do
    setup do
      @cf = @report_generator.cell_formatter
    end

    context ".dup" do
      setup do
        @cf.add_cell_format(:test) {|value| "Test#{value}" }
        @dup = @cf.dup
      end
      
      should "inherit procs from parent" do
        assert_equal "TestMe", @dup.format(:test, "Me")
      end
      
      should "added cell formats should not affect parent" do
        @dup.add_cell_format(:dup_test) {|value| "Dup#{value}"}
        assert_equal "DupMe", @dup.format(:dup_test, "Me")
        assert_equal "Me", @cf.format(:dup_test, "Me")
      end
      
      should "overridden cell formats should not affect parent" do
        @dup.add_cell_format(:test) {|value| "DupTest#{value}" }
        assert_equal "DupTestMe", @dup.format(:test, "Me")
        assert_equal "TestMe", @cf.format(:test, "Me")        
      end
    end
    
    context ".add_cell_format" do
      setup do
        @proc = Proc.new {|x| "Test#{x}" } 
      end
      
      execute do
        @cf.add_cell_format(@type, &@proc)
      end
      
      share_should("format for symbol") do
        assert_equal "TestMe", @cf.format(:string, "Me")
      end
      
      share_should("format for class") do
        assert_equal "TestMe", @cf.format(nil, "Me")
      end
      
      use_should("format for symbol").when("symbol type") do
        @type = :string       
      end
      
      context "symbol type" do
        setup do
          @type = String
        end

        use_should("format for symbol")
        use_should("format for class")
      end
    end
    
    context ".format" do
      setup do
        @value = "Me"
      end
      
      execute do
        @cf.format(@type, @value)
      end
      
      share_should "return value" do
        assert_equal @value, @execute_result
      end
      
      context "type is a proc" do
        setup do
          @type = lambda{|v| "Lambda#{v}" }
        end
        
        should "call the lambda" do
          assert_equal "LambdaMe", @execute_result
        end
      end
      
      context "type has been added" do
        setup do
          @type = :happy
        end
        
        should "format happily" do
          assert_equal "HappyMe", @execute_result
        end
      end
      
      use_should("return value").when("type has not been added") do
        @type = :sad
      end
      
      use_should("return value").when("type is nil") do
        @type = nil
      end 
    end
  end
end
  