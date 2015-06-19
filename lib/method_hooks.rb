require "method_hooks/version"
require "active_support/core_ext/object/deep_dup"

module MethodHooks
  @new_method = true

  def self.extended(base)
    base.send :include, InstanceMethods
  end

  private

  def inherited(child_class)
    child_class.instance_variable_set(:@new_method, true)
    child_class.instance_variable_set(:@inherited_before_callbacks, all_before_callbacks.deep_dup)
    child_class.instance_variable_set(:@inherited_around_callbacks, all_around_callbacks.deep_dup)
    child_class.instance_variable_set(:@inherited_after_callbacks, all_after_callbacks.deep_dup)

    super
  end

  def method_added(method_name)
    super
    return if @new_method == false || [:initialize, :call_before_callbacks, :call_around_callbacks, :call_after_callbacks].include?(method_name)

    method = instance_method(method_name)
    undef_method(method_name)

    @new_method = false

    define_method(method_name) do |*args, &block|
      call_before_callbacks(method_name)
      return_value = call_around_callbacks(method_name) { method.bind(self).call(*args, &block) }
      call_after_callbacks(method_name)

      return_value
    end

    @new_method = true
  end

  def all_before_callbacks
    before_callbacks.merge(inherited_before_callbacks) {|key, this, other| this + other}
  end

  def all_around_callbacks
    around_callbacks.merge(inherited_around_callbacks) {|key, this, other| this + other}
  end

  def all_after_callbacks
    after_callbacks.merge(inherited_after_callbacks) {|key, this, other| this + other}
  end

  def inherited_before_callbacks
    @inherited_before_callbacks ||= Hash.new { |hash, key| hash[key] = Array.new }
  end

  def inherited_around_callbacks
    @inherited_around_callbacks ||= Hash.new { |hash, key| hash[key] = Array.new }
  end

  def inherited_after_callbacks
    @inherited_after_callbacks ||= Hash.new { |hash, key| hash[key] = Array.new }
  end

  def before_callbacks
    @before_callbacks ||= Hash.new { |hash, key| hash[key] = Array.new }
  end

  def around_callbacks
    @around_callbacks ||= Hash.new { |hash, key| hash[key] = Array.new }
  end

  def after_callbacks
    @after_callbacks ||= Hash.new { |hash, key| hash[key] = Array.new }
  end

  def before(*method_names, &block)
    if block.nil?
      callback_method = method_names.pop
      block = proc { method(callback_method).call }
    end

    method_names.each do |method_name|
      before_callbacks[method_name] << block
    end
  end

  def around(*method_names, &block)
    if block.nil?
      callback_method = method_names.pop
      block = proc { |method| method(callback_method).call(method) }
    end

    method_names.each do |method_name|
      around_callbacks[method_name] << block
    end
  end

  def after(*method_names, &block)
    if block.nil?
      callback_method = method_names.pop
      block = proc { method(callback_method).call }
    end

    method_names.each do |method_name|
      after_callbacks[method_name] << block
    end
  end

  module InstanceMethods

    private

    def call_before_callbacks(method_name)
      callbacks = self.class.send(:all_before_callbacks)[method_name]
      callbacks.each do |callback|
        instance_eval(&callback)
      end
    end

    def call_around_callbacks(method_name, &block)
      callbacks = self.class.send(:all_around_callbacks)[method_name]
      return_value = nil

      method = -> { return_value = block.call }

      if callbacks.empty?
        method.call
      else
        callbacks.each do |callback|
          instance_exec(method, &callback)
        end
      end

      return_value
    end

    def call_after_callbacks(method_name)
      callbacks = self.class.send(:all_after_callbacks)[method_name]
      callbacks.each do |callback|
        instance_eval(&callback)
      end
    end

  end
end
