module MethodHooks
  @@new_method = true

  def self.extended(base)
    base.send :include, InstanceMethods
  end

  private

  def method_added(method_name)
    return if @@new_method == false || [:call_before_callbacks, :call_around_callbacks, :call_after_callbacks].include?(method_name)

    method = instance_method(method_name)
    undef_method(method_name)

    @@new_method = false

    define_method(method_name) do |*args, &block|
      call_before_callbacks(method_name)
      return_value = call_around_callbacks(method_name) { method.bind(self).call(*args, &block) }
      call_after_callbacks(method_name)

      return_value
    end

    @@new_method = true
  end

  def before_callbacks
    @@before_callbacks ||= {}
  end

  def around_callbacks
    @@around_callbacks ||= {}
  end

  def after_callbacks
    @@after_callbacks ||= {}
  end

  def before(*method_names, &block)
    method_names.each do |method_name|
      before_callbacks[method_name] = block
    end
  end

  def around(*method_names, &block)
    method_names.each do |method_name|
      around_callbacks[method_name] = block
    end
  end

  def after(*method_names, &block)
    method_names.each do |method_name|
      after_callbacks[method_name] = block
    end
  end

  module InstanceMethods

    private

    def call_before_callbacks(method_name)
      callback = self.class.send(:before_callbacks)[method_name]
      callback.call if callback
    end

    def call_around_callbacks(method_name, &block)
      callback = self.class.send(:around_callbacks)[method_name]
      return_value = nil

      method = -> { return_value = block.call }

      if callback
        callback.call(method)
      else
        method.call
      end

      return_value
    end

    def call_after_callbacks(method_name)
      callback = self.class.send(:after_callbacks)[method_name]
      callback.call if callback
    end

  end
end
