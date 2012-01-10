module Rapport
  class ReportGeneratorFake
    include ReportGenerator

    attr_accessor :output

    generate_with do |report|
      @output << report.column_headers
      report.each_row do |row|
        @output << row
      end
      @output
    end

  end
end