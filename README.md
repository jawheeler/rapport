# Rapport

Rapport allows you to create tabular reports with a DSL, which can be outputted via customizable formatters.

## Quick-Start

### Creating a Report

  To give a class reporting functionality, implement *columns*, *each_raw_row*, and optionally *cell_calculators*:
  
    require 'rubygems'
    require 'rapport'

    class Foo
      include Rapport::Report
    
      def columns
        [
          ['Name', :name],
          ['Rank', :rank],
          ['Serial Number', :ssn]
        ]
      end
    
      def cell_calculators
        {
          :name => {
            :through => :user
            :map_to => lambda {|model| model.first_name + model.last_name }
          },
          :rank => {
            :army => :abbreviated_rank
          }
        }
      end
    
      def each_raw_row
        Soldier.all(:include => :user).each do |soldier|
          yield soldier, soldier.type.to_s
        end
      end
    end
  
  



## Copyright

Copyright (c) 2011 Andrew Wheeler. See LICENSE.txt for
further details.

