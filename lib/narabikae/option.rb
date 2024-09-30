module Narabikae
  class Option
    attr_reader :field, :key_max_size, :scope

    # Initializes a new instance of the Option class.
    #
    # @param field [Symbol]
    # @param key_max_size [Integer] The maximum size of the key.
    # @param scope [Array<Symbol>] The scope of the option.
    def initialize(field:, key_max_size:, scope: [])
      @field = field.to_sym
      @key_max_size = key_max_size.to_i
      @scope = scope.is_a?(Array) ? scope.map(&:to_sym) : []
    end
  end
end
