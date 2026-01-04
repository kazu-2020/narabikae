module Narabikae
  class Option
    attr_reader :field, :key_max_size, :scope, :default_position

    # Initializes a new instance of the Option class.
    #
    # @param field [Symbol]
    # @param key_max_size [Integer] The maximum size of the key.
    # @param scope [Symbol, Array<Symbol>] The scope of the option.
    # @param default_position [Symbol] The default position when creating or auto setting.
    def initialize(field:, key_max_size:, scope: [], default_position: :last)
      @field = field.to_sym
      @key_max_size = key_max_size.to_i
      @scope = Array.wrap(scope).map(&:to_sym)
      @default_position = (default_position || :last).to_sym

      unless %i[first last].include?(@default_position)
        raise ArgumentError, "default_position must be :first or :last"
      end
    end
  end
end
