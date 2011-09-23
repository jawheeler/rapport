require 'zip/zip'

module Rapport
  class ReportGeneratorCsv
    include ReportGenerator

    generate_with do
      i=0
      FasterCSV.open(output_filename, 'w') do |csv|
        csv << report.column_names
        report.each_row do |row|
          csv << row
          logger.debug(row.inspect) if i%1000==0
          i+=1
        end
      end

      zip_output_file! if options[:zip]
      send_email if options[:emails]
      send_ftp if options[:ftps]
    
      return output_filename
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
  
    def output_filename
      @output_filename ||= File.join((@options[:output_dir] || File.join(report.base_path,'tmp')) , "#{report_name}_#{Time.now.strftime('%Y-%m-%d-%H%M%S')}.csv")
    end
  end
end