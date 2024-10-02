module Narabikae
  class OptionStore
    attr_reader :store

    def initialize
      @store = {}
    end

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
