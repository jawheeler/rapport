module Rapport
  class ReportGeneratorFake
    include ReportGenerator

    attr_accessor :options,:output,:report

    def initialize(report)
      @output = []
    end

    def generate_internal
      @output << report.column_names
      report.each_row do |row|
        @output << row
      end
      @output
    end

  end
end