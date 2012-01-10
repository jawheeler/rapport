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

Rapport.logger = Logger.new(
  File.open(
    File.join(
      File.dirname(__FILE__), 
      'logs', 
      'test.log'
    ),
    'w'
  )
)

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

class Rapport::TestReport
  include Rapport::Report

  def initialize(options = {})
    self.options = options
  end

  def each_model
    struct = Struct.new(:calc0, :m1)
    (0..2).each do |r|
      (0..3).map { |c| yield struct.new(r, c), :type0 }
    end
    raise options[:exception] if options[:exception]
    (0..2).each do |r|
      (0..3).map { |c| yield struct.new(r, c), :type1 }
    end
  end

  column "Column 0", :calc0

  column "Column 1", :calc1, :type0 => lambda { |m| 'T0 ' + m.m1.to_s },
                             :type1 => lambda { |m| 'T1 ' + m.m1.to_s },
                             :format => :happy
                          
  column "Column 2", :calc2, :map_to => lambda { |m| '~' + m.m1.to_s },
                             :format  => lambda { |value| "Formatted" + value }

  column "Column 3", :calc3, :map_to => lambda { |m| row_data[:calc2] + '~' + m.calc0.to_s },
                             :format_special => lambda { |value| "Formatted Special" + value }

end

class Rapport::ReportGeneratorTest
  include Rapport::ReportGenerator

  generate_with do |report|
    output = "START\n"
    each_row do |row|
      output << (0...row.length).to_a.zip(row).join("-")
      output << "\n"
    end
    output << "END\n"
    output
  end

  cell_format(:happy) {|value| "Happy#{value}"}
    
  cell_format(Time) {|value| value.strftime("%H:%m")}
end



