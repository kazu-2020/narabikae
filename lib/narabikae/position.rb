module Narabikae
  class Position
    # Initializes a new instance of the Position class.
    #
    # @param model  [Object] This params must be a base_class
    # @param column [Symbol] The column symbol. ex: :position
    # @param option [Option] this is a Option struct object
    def initialize(model, column, option)
      @model  = model
      @column = column
      @option = option
    end

    # Generates a new key for the last position
    #
    # @return [String] The newly generated key for the last position.
    def create_last_position
      FractionalIndexer.generate_key(prev_key: current_last_position)
    end

    # Finds the position after the specified target.
    # If generated key is invalid(ex: it already exists),
    # a new key is generated until the challenge count reaches the limit.
    # challenge count is 10 by default.
    #
    # @param target [#send(column)]
    # @param args [Hash] Additional arguments.
    # @option args [Integer] :challenge The number of times to attempt finding a valid position.
    # @return [String, nil] The generated key for the position after the target, or nil if no valid position is found.
    def find_position_after(target, **args)
      merged_args = { challenge: 10 }.merge(args)
      # when target is nil, try to generate key from the last position
      key = FractionalIndexer.generate_key(
              prev_key: target&.send(column) || current_last_position
            )
      return key if valid?(key)

      (merged_args[:challenge] || 0).times do
        key += random_fractional
        return key if valid?(key)
      end

      nil
    rescue FractionalIndexer::Error
      nil
    end

    #
    # Finds the position before the target position.
    # If generated key is invalid(ex: it already exists),
    # a new key is generated until the challenge count reaches the limit.
    # challenge count is 10 by default.
    #
    # @example
    #   position = Position.new
    #   position.find_position_before(target, challenge: 5)
    #
    # @param target [#send(column)]
    # @param args [Hash] Additional arguments.
    # @option args [Integer] :challenge The number of times to attempt finding a valid position.
    # @return [String, nil] The generated key for the position before the target, or nil if no valid position is found.
    def find_position_before(target, **args)
      merged_args = { challenge: 10 }.merge(args)
      # when target is nil, try to generate key from the first position
      key = FractionalIndexer.generate_key(
              next_key: target&.send(column) || current_first_position
            )
      return key if valid?(key)

      (merged_args[:challenge] || 0).times do
        key += random_fractional
        return key if valid?(key)
      end

      nil
    rescue FractionalIndexer::Error
      nil
    end

    private

    attr_reader :model, :column, :option

    def capable?(key)
      option.size >= key.size
    end

    def challenge_generate_key(time, &block)
      time.times do
        result = block.call

        return result if valid?(result)
      end
    end

    def current_first_position
      model.minimum(column)
    end

    def current_last_position
      model.maximum(column)
    end

    # generate a random fractional part
    #
    # @return [String] The random fractional part.
    # @see https://github.com/kazu-2020/fractional_indexer?tab=readme-ov-file#fractional-part
    def random_fractional
      # `fractional` represents the fractional part, but to ensure that the last digit is not zero value (ex: base_62 => '0'), the range is set to [1..].
      FractionalIndexer.configuration.digits[1..].sample
    end

    def uniq?(key)
      model.where(column => key).empty?
    end

    def valid?(key)
      return false if key.blank?

      capable?(key) && uniq?(key)
    end
  end
end
