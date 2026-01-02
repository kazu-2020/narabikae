module Narabikae
  class Position
    # Initializes a new instance of the Position class.
    #
    # @param record  [Object] Active Record object.
    # @param option [Option]
    def initialize(record, option)
      @record = record
      @option = option
    end

    # Generates a new key for the last position
    #
    # @return [String] The newly generated key for the last position.
    def create_last_position
      FractionalIndexer.generate_key(prev_key: current_last_position)
    end

    # Generates a new key for the first position
    #
    # @return [String] The newly generated key for the first position.
    def create_first_position
      FractionalIndexer.generate_key(next_key: current_first_position)
    end

    # Finds the position after the specified target.
    # If generated key is invalid(ex: it already exists),
    # a new key is generated until the challenge count reaches the limit.
    # challenge count is 10 by default.
    #
    # @param target [#send(field)]
    # @param challenge [Integer] The number of times to attempt finding a valid position.
    # @return [String, nil] The generated key for the position after the target, or nil if no valid position is found.
    def find_position_after(target, challenge: 10)
      # when target is nil, try to generate key from the last position
      target_key = extract_target_key(target) || current_last_position
      key = FractionalIndexer.generate_key(prev_key: target_key)
      return key if valid?(key)

      (challenge || 0).times do |i|
        key = FractionalIndexer.generate_key(prev_key: target_key, next_key: key)
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
    # @param target [#send(field)]
    # @param challenge [Integer] The number of times to attempt finding a valid position.
    # @return [String, nil] The generated key for the position before the target, or nil if no valid position is found.
    def find_position_before(target, challenge: 10)
      # when target is nil, try to generate key from the first position
      target_key = extract_target_key(target) || current_first_position
      key = FractionalIndexer.generate_key(next_key: target_key)
      return key if valid?(key)

      (challenge || 0).times do |i|
        key = FractionalIndexer.generate_key(prev_key: key, next_key: target_key)
        key += random_fractional
        return key if valid?(key)
      end

      nil
    rescue FractionalIndexer::Error
      nil
    end

    # Finds the position between two targets.
    #
    # @param prev_target [#send(field)] The previous target.
    # @param next_target [#send(field)] The next target.
    # @param challenge [Integer] The number of times to attempt finding a valid position.
    # @return [string, nil] The position between the two targets, or nil if no valid position is found.
    def find_position_between(prev_target, next_target, challenge: 10)
      return find_position_before(next_target, challenge: challenge) if prev_target.blank?
      return find_position_after(prev_target, challenge: challenge)  if next_target.blank?

      prev_key, next_key = [ extract_target_key(prev_target), extract_target_key(next_target) ].minmax
      key = FractionalIndexer.generate_key(
              prev_key: prev_key,
              next_key: next_key,
            )
      return key if valid?(key)

      (challenge || 0).times do |i|
        key = FractionalIndexer.generate_key(prev_key: key, next_key: next_key)
        key += random_fractional
        return key if valid?(key)
      end

      nil
    rescue FractionalIndexer::Error
      nil
    end

    private

    attr_reader :record, :option

    def capable?(key)
      option.key_max_size >= key.size
    end

    def current_first_position
      model.merge(model_scope).minimum(option.field)
    end

    def current_last_position
      model.merge(model_scope).maximum(option.field)
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
      model.where(record.slice(*option.scope))
    end

    def uniq?(key)
      model.where(option.field => key).merge(model_scope).empty?
    end

    def valid?(key)
      return false if key.blank?

      capable?(key) && uniq?(key)
    end

    def extract_target_key(target)
      return if target.nil?
      return target if target.is_a?(String)

      target.send(option.field)
    end
  end
end
