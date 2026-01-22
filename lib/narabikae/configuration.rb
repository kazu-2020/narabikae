module Narabikae
  class Configuration < ActiveSupport::OrderedOptions
    VALID_DEFAULT_POSITIONS = %i[first last].freeze
    VALID_BASES = [ 10, 62, 94 ].freeze

    def initialize(key_max_size: 200, scope: [], default_position: :last, base: 62)
      super()
      self.key_max_size = key_max_size
      self.scope = Array.wrap(scope).map(&:to_sym)
      self.default_position = (default_position || :last).to_sym
      self.base = base

      validate!
    end

    private

    def validate!
      raise ArgumentError, "size is required" if key_max_size.nil?

      unless VALID_DEFAULT_POSITIONS.include?(default_position)
        raise ArgumentError, "default_position must be :first or :last"
      end

      unless VALID_BASES.include?(base)
        raise ArgumentError, "unsupported base: #{base}, must be one of #{VALID_BASES.join(', ')}"
      end
    end
  end
end
