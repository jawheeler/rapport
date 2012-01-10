# Rapport

Rapport allows you to create tabular reports with a DSL, which can be outputted via customizable formatters.

## Quick-Start

Include the Rapport::Report module in any object to allow it to generate reports in the pre-built formatters (csv, fake) or
in a custom formatter. Use an easy DSL to write all your reports once, and all your formats once, and then mix and match as you please.

### Creating a Report

    require 'rubygems'
    require 'rapport'

    class OrderReport
      include Rapport::Report
      
      def initialize(options)
        self.options = options
      end
      
      # Add columns to the report with column(column_header, *args)
      # Column Header is what appears in the report, and *args specify how to calculate the values using the model
      #
      #   examples:
      #     column('column header')
      #     column('column header', :column_symbol)
      #     column('column header', :model_type => :column_symbol, ...)
      #
      # All equivalent:
      # column 'Product ID', :map_to => lambda {|model| !model.nil? and model.respond_to?(:product_id) ? model.product_id : nil }
      # column 'Product ID', :map_to => :product_id
      # column 'Product ID', :product_id
      column 'Product ID'         # by default converts 'Product ID' to :product_id
      
      # special calculation depending on type of model
      column 'Price',         :additional_charge => :amount,
                              :line_item => :price,  # not required; defaults to :price
                              :special_line_item => lambda {|line_item| line_item.price - line_item.tax },
                              # Display price (in cents) as dollars
                              :format => :cents 
      
      # Navigate an object heirarchy using :through
      column 'Order ID',      :through -> :order, :map_to => :id                    
      column 'Customer Name', :through => [:order, :customer], :map_to => lambda {|customer| "#{customer.first_name} #{customer.last_name}" }

      # Implement each_model to specify which models belong to the report.
      # The method should yield each model, and optionally specify the model type in order to customize how the value is calculated.
      def each_model
        AdditionalCharge.in_order_report.each do |additional_charge|
          yield additional_charge # equivalent to yield additional_charge, :additional_charge
        end
           
        LineItem.in_order_report.each do |line_item|
          if line_item.special?
            yield line_item, :special_line_item  # uses special price calculation above 
          else
            yield line_item  # equivalent to yield line_item, :line_item
          end
        end
      end
    end

### Running a Report

    order_report = OrderReport.new(:format => 'csv', :output_dir => 'my_dir')
    order_report.generate # generates a csv file named 'my_dir/OrderReport_{timestamp}.csv
    
    order_report = OrderReport.new(:format => 'my_custom')
    order_report.generate # generates the same report, but in your custom format

### Creating a Custom Format
    module Rapport
      class ReportGeneratorMyCustom
        include ReportGenerator

        generate_with do |report|
          File.open(output_filename,'w') do |file|
            file.puts(report.column_headers.join('|'))
            report.each_row do |row|
              file.puts(row.join('|'))
            end
          end
        end

      end
    end

## Copyright

Copyright (c) 2011 Andrew Wheeler. See LICENSE.txt for
further details.

