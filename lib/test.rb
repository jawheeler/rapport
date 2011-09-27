class Foo
  instance_variable_set(:@hello, [1])
  
  def self.inherited(subclass)
    subclass.instance_variable_set( :@hello, self.instance_variable_get(:@hello).dup )
  end
  
  def self.hello
    @hello
  end
  
end