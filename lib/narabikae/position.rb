module Narabikae
  class Position
    # Initializes a new instance of the Position class.
    #
    # @param record  [Object] Active Record object.
    # @param column [Symbol] The column symbol. ex: :position
    # @param option [Option] this is a Option struct object
    def initialize(record, column, option)
      @record = record
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

    # Finds the position between two targets.
    #
    # @param prev_target [#send(column)] The previous target.
    # @param next_target [#send(column)] The next target.
    # @param args [Hash] Additional arguments.
    # @option args [Integer] :challenge The number of times to attempt finding a valid position.
    # @return [string, nil] The position between the two targets, or nil if no valid position is found.
    def find_position_between(prev_target, next_target, **args)
      return find_position_before(next_target, **args) if prev_target.blank?
      return find_position_after(prev_target, **args)  if next_target.blank?

      merged_args = { challenge: 10 }.merge(args)

      prev_key, next_key = [ prev_target.send(column), next_target.send(column) ].minmax
      key = FractionalIndexer.generate_key(
              prev_key: prev_key,
              next_key: next_key,
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

    attr_reader :record, :column, :option

    def capable?(key)
      option.size >= key.size
    end

    def current_first_position
      model.merge(model_scope).minimum(column)
    end

    def current_last_position
      model.merge(model_scope).maximum(column)
    end

    def model
      record.class.base_class
    end

    # generate a random fractional part
    #
    # @return [String] The random fractional part.
    # @see https://github.com/kazu-2020/fractional_indexer?tab=readme-ov-file#fractional-part
    def random_fractional
      # `fractional` represents the fractional part, but to ensure that the last digit is not zero value (ex: base_62 => '0'), the range is set to [1..].
      FractionalIndexer.configuration.digits[1..].sample
    end

    def model_scope
      option_scope = option.scope.is_a?(Array) ? option.scope : []
      model.where(record.slice(*option_scope))
    end

    def uniq?(key)
      model.where(column => key).merge(model_scope).empty?
    end

    def valid?(key)
      return false if key.blank?

      capable?(key) && uniq?(key)
    end
  end
end
