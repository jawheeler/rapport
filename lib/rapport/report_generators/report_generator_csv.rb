require 'zip/zip'
require 'fastercsv'

module Rapport
  class ReportGeneratorCsv
    include ReportGenerator

    generate_with do |report|
      if report.options[:to_string].nil?
        FasterCSV.open(output_filename, 'w') {|csv| generate_internal(report, csv) }

        zip_output_file! if report.options[:zip]
    
        output_filename
      else
        FasterCSV.generate {|csv| generate_internal(report, csv) }
      end
    end
    
    cell_format(:cents) do |value| 
      !value.nil? && 
      ("%.2f" % (value.to_s.to_d / '100'.to_d))
    end
    
    cell_format(Time) do |value|
      value.strftime('%B %e, %Y')
    end
    
    cell_format(Date) do |value|
      format_as(Time,Time.utc(value.year, value.month, value.day))
    end

    def zip_output_file!
      zip_file_name = output_filename.sub(/(\.[^\.]*)?$/,'.zip')
      Zip::ZipFile.open(zip_file_name, Zip::ZipFile::CREATE) do |zipfile|
        zipfile.add(File.basename(output_filename),output_filename)
      end
      @output_filename = zip_file_name
    end
  
    def report_name
      report.table_name.sub('reports_','')
    end
    
    private
    
    def self.generate_internal(report, csv)
      i = 0
      csv << report.column_headers
      report.each_row do |row|
        csv << row
        Rapport.logger.debug(row.inspect) if i%1000==0
        i+=1
      end      
    end

  end
end