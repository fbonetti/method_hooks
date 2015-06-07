class Model
  extend MethodHooks

  before :save do
    puts 'before'
  end

  around :save do |method|
    puts 'before_around'
    method.call
    puts 'after_around'
  end

  after :save, :foo do
    puts 'after'
  end

  def save
    puts 'save'
  end

  def foo
    puts 'foo'
  end

end

model = Model.new
model.save
model.foo

=begin

Outputs the following:

before
before_around
save
after_around
after
foo
after

=end