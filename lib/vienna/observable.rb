module Vienna
  module Observable

    # Gets the attribute by the given name. This currently will only
    # retrieve simple properties, by trying for a method with the given
    # name first, then trying with a "?" prefix for boolean attributes.
    # If neither are methods on this object, then nil is returned.
    #
    # @param [String, Symbol] name attribute name to get
    # @return [Object, nil]
    def get_attribute(name)
      if respond_to? name
        __send__ name
      elsif respond_to? "#{name}?"
        __send__ "#{name}?"
      end
    end

    def set_attribute(name, val)
      if respond_to? "#{name}="
        __send__ "#{name}=", val
      end
    end

    # Start observing an attribute on this object. This will replace the
    # setter method for the given attribute with a singleton one on this
    # instance that calls super, to use the default implementation, and
    # will then loop over all registered observers, passing the new value
    # to the each block.
    #
    #   class Foo
    #     attr_accessor :name
    #   end
    #
    #   obj = Foo.new
    #   obj.observe(:name) { |val| "name is #{val}" }
    #
    #   obj.name = 'adam'
    #   obj.name = 'tom'
    #
    #   # => name is "adam"
    #   # => "name is tom"
    #
    # The handler block gets passed two args; the new value of the
    # attribute, and the old value:
    #
    #   obj.observe(:first_name) do |new_value, old_value|
    #     puts "changed name from #{old_value} to #{new_value}"
    #   end
    #
    # @param [String, Symbol] name attribute name to start observing
    def observe(name, &handler)
      observers = (@__observers ||= {})

      unless handlers = observers[name]
        old_value = get_attribute(name)
        handlers  = observers[name] = []

        if respond_to? "#{name}="
          define_singleton_method("#{name}=") do |val|
            super val
            handlers.each { |h| h.call val, old_value }
            old_value = val
          end
        end
      end

      handlers << handler
    end

  end
end

class Object
  include Vienna::Observable
end