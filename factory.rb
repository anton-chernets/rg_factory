# Class Factory behave like class Struct
class Factory

  # Collapsing arguments and get block
  def self.new(*arguments, &block)

    raise ArgumentError, 'wrong number of arguments (given 0, expected 1+)' if arguments.empty?
    raise TypeError, 'Symbols expected' unless arguments.all? { |key| key.is_a?(Symbol) }

    # Get incoming subclass name
    subclass_name = nil
    subclass_name = arguments.shift if arguments.first.is_a?(String)

    # Initialize subclass
    subclass = Class.new do

      define_method(:initialize) do |*subclass_arguments|
        raise ArgumentError, "#{class_name} size differs" if arguments.size > subclass_arguments.size
        arguments.zip(subclass_arguments) do |key, value|
          instance_variable_set("@#{key}", value)
        end
      end

      arguments.each do |key|
        define_method key do
          instance_variable_get "@#{key}"
        end
        define_method("#{key}=") do
          |value| instance_variable_set("@#{key}", value)
        end
      end

      def to_s
        data = to_h.collect { |key, value| "#{key}='#{value}'" }.join(', ')
        "#<factory #{self.class.name} #{data}>"
      end
      alias_method :inspect, :to_s

      def to_h
        Hash[instance_variables.map { |key| [key, instance_variable_get(key)] }]
      end

      def values
        instance_variables.map { |key| instance_variable_get key }
      end

      alias_method :to_a, :values

      def eql?(other)
        self.class == other.class && self.values == other.values
      end

      alias_method :==, :eql?

      define_method(:[]) do |key|
        if key.is_a?(Integer)
          raise IndexError, 'index_error' unless key.between?(0, members.size-1)
          send(members[key])
        else
          instance_variable_get "@#{key}"
        end
      end

      define_method(:[]=) do |key, value|
        instance_variable_set("@#{key}", value)
      end

      def values_at(*indexes)
        values.values_at *indexes
      end

      def each(&block)
        values.each(&block)
      end

      def each_pair(&block)
        to_h.each(&block)
      end

      def members
        instance_variables.map { |key| :"#{key.to_s.delete('@')}" }
      end

      def dig(*args)
        to_h.send(:dig, *args)
      end

      def select(&block)
        values.select &block
      end

      def size
      to_h.size
      end

      alias_method :length, :size

    end

    # Set in subclass incoming method
    subclass.class_eval &block if block_given?

    # Set incoming subclass name
    const_set(subclass_name.capitalize, subclass) if subclass_name

    subclass
  end
end