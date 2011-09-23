# Rapport

Rapport allows you to create tabular reports with a DSL, which can be outputted via customizable formatters.

## Quick-Start

### Creating a Report

  To give a class reporting functionality, implement *columns*, *each_raw_row*, and optionally *cell_calculators*:
  
    require 'rubygems'
    require 'rapport'

    class OrderReport
      include Rapport::Report
    
      def columns
        [
          ['Order ID', :order_id],
          ['Type', :class],
          ['ID', :id],
          ['Price', :price]
        ]
      end
    
      def cell_calculators
        {
          :order_id => {
            :through => :order
            :map_to => :id
          },
          :price => {
            :additional_charge => :amount
          }
        }
      end
    
      def each_raw_row
        LineItem.scope(:created_at > 1.day.ago).each do |line_item|
          yield line_item
        end
        AdditionalCharge.scope(:created_at > 1.day.ago).each do |additional_charge|
          yield additional_charge, :additional_charge
        end
      end
    end
  
  



## Copyright

Copyright (c) 2011 Andrew Wheeler. See LICENSE.txt for
further details.

