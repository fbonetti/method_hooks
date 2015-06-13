require "method_hooks/version"

module MethodHooks
  @new_method = true

  def self.extended(base)
    base.send :include, InstanceMethods
  end

  private

  def inherited(child_class)
      parent_before = before_callbacks
      parent_after = after_callbacks
      parent_around = around_callbacks

      child_class.class_eval do
          @before_callbacks = parent_before
          @around_callbacks = parent_around
          @after_callbacks = parent_after
      end

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
    method_names.each do |method_name|
      before_callbacks[method_name] << block
    end
  end

  def around(*method_names, &block)
    method_names.each do |method_name|
      around_callbacks[method_name] << block
    end
  end

  def after(*method_names, &block)
    method_names.each do |method_name|
      after_callbacks[method_name] << block
    end
  end

  module InstanceMethods

    private

    def call_before_callbacks(method_name)
      callbacks = self.class.send(:before_callbacks)[method_name]
      callbacks.each do |callback|
        instance_eval(&callback)
      end
    end

    def call_around_callbacks(method_name, &block)
      callbacks = self.class.send(:around_callbacks)[method_name]
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
      callbacks = self.class.send(:after_callbacks)[method_name]
      callbacks.each do |callback|
        instance_eval(&callback)
      end
    end

  end
end
