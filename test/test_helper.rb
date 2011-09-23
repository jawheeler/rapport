require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'shoulda'
require 'mocha'
require 'shared_should'
require 'always_execute'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rapport'

class Object
  class Bypass
    instance_methods.each do |m|
      undef_method m unless m =~ /^__/
    end

    def initialize(ref)
      @ref = ref
    end

    def method_missing(sym, *args)
      @ref.__send__(sym, *args)
    end
  end

  def bypass
    Bypass.new(self)
  end
end

class Test::Unit::TestCase
  share_should("return nil") do
    assert_equal nil, @execute_result
  end
end

class TestReport
  include Rapport::Report
  
  def each_raw_row
    (0..2).each do |r|
      yield [(0..3).map { |c| "t0 #{c}#{r}" }, :type0]
    end
    raise options[:exception] if options[:exception]
    (0..2).each do |r|
      yield [(0..3).map { |c| "t1 #{c}#{r}" }, :type1]
    end
  end

  def columns
    (0..4).map { |c| ["Column Header #{c}", :"calc#{c}"] }
  end

  def cell_calculators
    super.merge!(
        :calc1 => {
            :type0 => lambda { |m| 'T0' + m[1] },
            :type1 => lambda { |m| 'T1' + m[1] }
        },
        :calc2 => {
            :map_to => lambda { |m| 'D' + m[2] },
            :format  => lambda { |value| "Formatted" + value }
        },
        :calc3 => {
            :map_to        => lambda { |m| row_data[:calc2] + m[3] },
            :format_special => lambda { |value| "Formatted Special" + value }
        }
    )
  end
end

