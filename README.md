# Rapport

Rapport allows you to create tabular reports with a DSL, which can be outputted via customizable formatters.

## Quick-Start

### Creating a Report
  
    require 'rubygems'
    require 'rapport'

    class OrderReport
      include Rapport::Report

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
    
      def each_model
        AdditionalCharge.in_order_report.each do |additional_charge|
          yield additional_charge
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

## Copyright

Copyright (c) 2011 Andrew Wheeler. See LICENSE.txt for
further details.

