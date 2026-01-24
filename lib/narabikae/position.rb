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
    #
    # Uses an optimized neighbor-aware approach: queries the database for the
    # next record's position and generates a key between the target and its
    # neighbor. This avoids blind key generation and reduces collision retries.
    #
    # Falls back to retry with random fractional for concurrent write race conditions.
    #
    # @param target [ActiveRecord::Base, String]
    # @param challenge [Integer] The number of times to attempt finding a valid position.
    # @return [String, nil] The generated key for the position after the target, or nil if no valid position is found.
    def find_position_after(target, challenge: 10)
      # when target is nil, try to generate key from the last position
      target_key = extract_target_key(target) || current_last_position
      next_key = find_next_position_key(target_key)
      key = FractionalIndexer.generate_key(prev_key: target_key, next_key: next_key)
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

    # Finds the position before the target position.
    #
    # Uses an optimized neighbor-aware approach: queries the database for the
    # previous record's position and generates a key between the neighbor and
    # the target. This avoids blind key generation and reduces collision retries.
    #
    # Falls back to retry with random fractional for concurrent write race conditions.
    #
    # @param target [ActiveRecord::Base, String]
    # @param challenge [Integer] The number of times to attempt finding a valid position.
    # @return [String, nil] The generated key for the position before the target, or nil if no valid position is found.
    def find_position_before(target, challenge: 10)
      # when target is nil, try to generate key from the first position
      target_key = extract_target_key(target) || current_first_position
      prev_key = find_prev_position_key(target_key)
      key = FractionalIndexer.generate_key(prev_key: prev_key, next_key: target_key)
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
    # @param prev_target [ActiveRecord::Base, String] The previous target.
    # @param next_target [ActiveRecord::Base, String] The next target.
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

    # Finds the position key of the next record after the given key within scope.
    # Uses an indexed query for O(1) lookup.
    #
    # @param key [String] The position key to search after.
    # @return [String, nil] The next position key, or nil if no record exists after.
    def find_next_position_key(key)
      return nil if key.nil?

      model.merge(model_scope)
           .where(model.arel_table[option.field].gt(key))
           .order(option.field => :asc)
           .pick(option.field)
    end

    # Finds the position key of the previous record before the given key within scope.
    # Uses an indexed query for O(1) lookup.
    #
    # @param key [String] The position key to search before.
    # @return [String, nil] The previous position key, or nil if no record exists before.
    def find_prev_position_key(key)
      return nil if key.nil?

      model.merge(model_scope)
           .where(model.arel_table[option.field].lt(key))
           .order(option.field => :desc)
           .pick(option.field)
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
      return target if target.is_a?(String)
      unless target.is_a?(ActiveRecord::Base)
        raise Narabikae::Error, "target must be an ActiveRecord object or position key string"
      end

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
