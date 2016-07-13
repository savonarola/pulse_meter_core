module PulseMeter
  class Observer
    extend PulseMeter::Mixins::Utils

    class << self
      # Removes observation from instance method
      # @param klass [Class] class
      # @param method [Symbol] instance method name
      def unobserve_method(klass, method)
        with_observer = method_with_observer(method)
        if has_method?(klass, with_observer)
          block = unchain_block(method)
          klass.class_eval &block
        end
      end

      # Removes observation from class method
      # @param klass [Class] class
      # @param method [Symbol] class method name
      def unobserve_class_method(klass, method)
        with_observer = method_with_observer(method)
        method_owner = metaclass(klass)
        if has_method?(method_owner, with_observer)
          block = unchain_block(method)
          method_owner.instance_eval &block
        end
      end

      # Registeres an observer for instance method
      # @param klass [Class] class
      # @param method [Symbol] instance method
      # @param sensor [Object] notifications receiver
      # @param proc [Proc] proc to be called in context of receiver each time observed method called
      def observe_method(klass, method, sensor, &proc)
        with_observer = method_with_observer(method)
        unless has_method?(klass, with_observer)
          block = chain_block(method, sensor, &proc)
          klass.class_eval &block
        end
      end

      # Registeres an observer for class method
      # @param klass [Class] class
      # @param method [Symbol] class method
      # @param sensor [Object] notifications receiver
      # @param proc [Proc] proc to be called in context of receiver each time observed method called
      def observe_class_method(klass, method, sensor, &proc)
        with_observer = method_with_observer(method)
        method_owner = metaclass(klass)
        unless has_method?(method_owner, with_observer)
          block = chain_block(method, sensor, &proc)
          method_owner.instance_eval &block
        end
      end

      protected

      def define_instrumented_method(method_owner, method, receiver, &handler)
        with_observer = method_with_observer(method)
        without_observer = method_without_observer(method)
        method_owner.send(:define_method, with_observer) do |*args, &block|
          start_time = Time.now
          begin
            self.send(without_observer, *args, &block)
          ensure
            begin
              delta = ((Time.now - start_time) * 1000).to_i
              receiver.instance_exec(delta, *args, &handler)
            rescue StandardError
            end
          end
        end
      end

      private

      def unchain_block(method)
        with_observer = method_with_observer(method)
        without_observer = method_without_observer(method)
        me = self

        Proc.new do
          if me.send(:has_method?, self, without_observer)
            alias_method(method, without_observer)
            remove_method(without_observer)
          else
            #for inherited child methods if we unobserve them after parent class
            remove_method(method)
          end
          remove_method(with_observer)
        end
      end

      def chain_block(method, receiver, &handler)
        with_observer = method_with_observer(method)
        without_observer = method_without_observer(method)
        me = self

        Proc.new do
          me.send(:define_without_observer, self, method, without_observer)
          me.send(:define_instrumented_method, self, method, receiver, &handler)
          alias_method(method, with_observer)
        end
      end

      def define_without_observer(method_owner, method, without_observer)
        if has_method?(method_owner, method)
          #for redefined methods
          unless has_method?(method_owner, without_observer)
            method_owner.send(:alias_method, without_observer, method)
          end
        else
          #for inherited methods
          unless method_owner.method_defined?(without_observer)
            method_owner.send(:alias_method, without_observer, method)
          end
        end
      end

      def has_method?(method_owner, method)
        method_owner.instance_methods(false).include?(method.to_sym)
      end

      def metaclass(klass)
        klass.class_eval do
          class << self
            self
          end
        end
      end

      def method_with_observer(method)
        "#{method}_with_#{underscore(self).tr('/', '_')}"
      end

      def method_without_observer(method)
        "#{method}_without_#{underscore(self).tr('/', '_')}"
      end
    end
  end
end
