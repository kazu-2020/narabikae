module Narabikae
  class Option
    attr_reader :key_max_size, :scope

    # Initializes a new instance of the Option class.
    #
    # @param key_max_size [Integer] The maximum size of the key.
    # @param scope [Array<Symbol>] The scope of the option.
    def initialize(key_max_size:, scope: [])
      @key_max_size = key_max_size.to_i
      @scope = scope.is_a?(Array) ? scope.map(&:to_sym) : []
    end
  end
end
