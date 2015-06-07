# MethodHooks

Allows you to add `before`, `around`, and `after` callbacks to **any** method.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'method_hooks'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install method_hooks

## Usage

```ruby
class Model
  extend Callbacks

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
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/method_hooks/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
