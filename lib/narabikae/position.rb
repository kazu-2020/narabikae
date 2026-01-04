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
    # @param target [Integer, String, #send(field)]
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
    # @param target [Integer, String, #send(field)]
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
    # @param prev_target [Integer, String, #send(field)] The previous target.
    # @param next_target [Integer, String, #send(field)] The next target.
    # @param challenge [Integer] The number of times to attempt finding a valid position.
    # @return [string, nil] The position between the two targets, or nil if no valid position is found.
    def find_position_between(prev_target, next_target, challenge: 10)
      prev_key = extract_target_key(prev_target)
      next_key = extract_target_key(next_target)
      return find_position_before(next_target, challenge: challenge) if prev_key.blank?
      return find_position_after(prev_target, challenge: challenge) if next_key.blank?

      prev_key, next_key = [ prev_key, next_key ].minmax
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

    # Returns the position key for a 0-based index.
    #
    # @param index [Integer]
    # @return [String, nil]
    def find_position_at(index)
      return if index.nil?

      FractionalIndexer.generate_keys(count: index + 1).last
    end

    # Returns the positional index for the current record within its scope.
    #
    # @return [Integer, nil]
    def index
      key = record.send(option.field)
      return if key.blank?

      model.merge(model_scope).where(model.arel_table[option.field].lt(key)).count
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
      record.class.base_class.unscoped
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
      target = model.find(target) unless target.is_a?(ActiveRecord::Base)

      record_table = table_name_for_class(record)
      target_table = table_name_for_class(target)
      unless target_table && record_table && target_table == record_table
        raise Narabikae::Error,
              "target model mismatch: expected table #{record_table || 'unknown'}, got #{target_table || 'unknown'}"
      end

      mismatched_columns = mismatched_scope_columns(target)
      if mismatched_columns.any?
        raise Narabikae::Error, "target scope mismatch for columns: #{mismatched_columns.join(', ')}"
      end
      raise Narabikae::Error, "target missing #{option.field} field" unless target.respond_to?(option.field)

      target.send(option.field)
    end

    def table_name_for_class(value)
      klass = value.class
      return unless klass.respond_to?(:table_name)

      klass.table_name
    end

    def mismatched_scope_columns(target)
      option.scope.select do |column|
        !target.respond_to?(column) ||
          !record.respond_to?(column) ||
          target.public_send(column) != record.public_send(column)
      end
    end
  end
end
