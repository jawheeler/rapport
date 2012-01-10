require File.dirname(__FILE__) + '/../../test_helper'
require 'rapport/report_generators/report_generator_simple_csv'

class ReportTest < Test::Unit::TestCase
  setup do
    @rg_csv = Rapport::ReportGeneratorSimpleCsv.new
  end
  
  context "cell_format Time" do
    setup do
      @time = Time.new
    end
    
    execute do
      @rg_csv.format(Time, @time)
    end
  
    should "format as a string" do
      assert_equal @time.strftime('%B %e, %Y'), @execute_result
    end
  end
  
  
  context "cell_format Date" do
    setup do
      @date = Date.new
    end
    
    execute do
      @rg_csv.format(Date, @date)
    end
    
    should "format the date as a time" do
      assert_equal Time.utc(@date.year, @date.month, @date.day ).strftime('%B %e, %Y'), @execute_result
    end
  end
  
  context ".generate" do
    setup do
      @report = Rapport::TestReport.new(:format => 'simple_csv', :to_string => true)
    end
    
    execute do
      @report.generate
    end
    
    should "write the header" do
      assert_match "Column 0,Column 1,Column 2,Column 3\n", @execute_result
    end
    
    should "write rows" do
      assert_match "1,T0 2,Formatted~2,~2~1\n", @execute_result
      assert_match "1,T1 3,Formatted~3,~3~1\n", @execute_result
    end
  end
end