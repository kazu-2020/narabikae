module Narabikae
  # OptionStore stores configuration for each field in a model.
  class OptionStore
    attr_reader :store

    # Initializes a new instance of OptionStore.
    def initialize
      @store = {}
    end

    # Registers a configuration for a specific field.
    #
    # @param field [Symbol] The field name.
    # @param option [Configuration] The configuration object.
    # @raise [Narabikae::Error] If field is already registered or dependency loop is detected.
    # @return [Configuration] The registered configuration object.
    def register!(field, option)
      if store.key?(field)
        raise Narabikae::Error, "the field `#{field}` is already registered"
      end
      if option.scope.include?(field)
        raise Narabikae::Error, "dependency loop detected: #{option.scope}"
      end
      if option.scope.any? { |s| store.key?(s) }
        raise Narabikae::Error, "the scope `#{option.scope}` is already registered as other field"
      end

      store[field] = option

      option
    end
  end
end
