module Narabikae
  # Position class handles the low-level calculation of fractional index positions.
  class Position
    attr_reader :indexer, :record, :config, :field

    # Initializes a new instance of the Position class.
    #
    # @param record  [Object] Active Record object.
    # @param field [Symbol] The field name used for ordering.
    # @param config [Configuration]
    def initialize(record, field, config)
      @record = record
      @field = field
      @config = config
      @indexer = FractionalIndexer.new(base: config.base)
    end

    # Generates a new key for the last position
    #
    # @return [String] The newly generated key for the last position.
    def create_last_position
      @indexer.generate_key(prev_key: current_last_position)
    end

    # Generates a new key for the first position
    #
    # @return [String] The newly generated key for the first position.
    def create_first_position
      @indexer.generate_key(next_key: current_first_position)
    end

    # Finds the position after the specified target.
    # If generated key is invalid(ex: it already exists),
    # a new key is generated until the challenge count reaches the limit.
    # challenge count is 10 by default.
    #
    # @param target [ActiveRecord::Base, String]
    # @param challenge [Integer] The number of times to attempt finding a valid position.
    # @return [String, nil] The generated key for the position after the target, or nil if no valid position is found.
    def find_position_after(target, challenge: 10)
      # when target is nil, try to generate key from the last position
      target_key = extract_target_key(target) || current_last_position
      key = @indexer.generate_key(prev_key: target_key)
      return key if valid?(key)

      (challenge || 0).times do |i|
        break if key.nil?
        key = @indexer.generate_key(prev_key: target_key, next_key: key)
        break if key.nil?
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
    # @param target [ActiveRecord::Base, String]
    # @param challenge [Integer] The number of times to attempt finding a valid position.
    # @return [String, nil] The generated key for the position before the target, or nil if no valid position is found.
    def find_position_before(target, challenge: 10)
      # when target is nil, try to generate key from the first position
      target_key = extract_target_key(target) || current_first_position
      key = @indexer.generate_key(next_key: target_key)
      return key if valid?(key)

      (challenge || 0).times do |i|
        break if key.nil?
        key = @indexer.generate_key(prev_key: key, next_key: target_key)
        break if key.nil?
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
      key = @indexer.generate_key(
              prev_key: prev_key,
              next_key: next_key,
            )
      return key if valid?(key)

      (challenge || 0).times do |i|
        break if key.nil?
        key = @indexer.generate_key(prev_key: key, next_key: next_key)
        break if key.nil?
        key += random_fractional
        return key if valid?(key)
      end

      nil
    rescue FractionalIndexer::Error
      nil
    end

    private

    # Checks if the key size is within the allowed maximum.
    # @param key [String]
    # @return [Boolean]
    def capable?(key)
      return false if key.nil?
      config.key_max_size >= key.size
    end

    # Returns the first position in the current scope.
    # @return [String, nil]
    def current_first_position
      model.merge(model_scope).minimum(field)
    end

    # Returns the last position in the current scope.
    # @return [String, nil]
    def current_last_position
      model.merge(model_scope).maximum(field)
    end

    # Returns the base class of the record, unscoped.
    # @return [ActiveRecord::Relation]
    def model
      record.class.base_class.unscoped
    end

    # generate a random fractional part
    #
    # @return [String] The random fractional part.
    # @see https://github.com/kazu-2020/fractional_indexer?tab=readme-ov-file#fractional-part
    def random_fractional
      # `fractional` represents the fractional part, but to ensure that the last digit is not zero value (ex: base_62 => '0'), the range is set to [1..].
      @indexer.digits[1..].sample
    end

    # Returns the scope relation for the model.
    # @return [ActiveRecord::Relation]
    def model_scope
      model.where(record.slice(*config.scope))
    end

    # Checks if the key is unique within the scope.
    # @param key [String]
    # @return [Boolean]
    def uniq?(key)
      model.where(field => key).merge(model_scope).empty?
    end

    # Checks if the key is valid (not blank, capable, and unique).
    # @param key [String]
    # @return [Boolean]
    def valid?(key)
      return false if key.blank?

      capable?(key) && uniq?(key)
    end

    # Extracts the position key from a target (record or string).
    #
    # @param target [ActiveRecord::Base, String, nil]
    # @raise [Narabikae::Error] If target is invalid.
    # @return [String, nil]
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
      raise Narabikae::Error, "target missing #{field} field" unless target.respond_to?(field)

      target.send(field)
    end

    # Returns the table name for a class or instance.
    # @param value [Object]
    # @return [String, nil]
    def table_name_for_class(value)
      klass = value.class
      return unless klass.respond_to?(:table_name)

      klass.table_name
    end

    # Identifies columns where the target's scope values differ from the record's.
    # @param target [ActiveRecord::Base]
    # @return [Array<Symbol>]
    def mismatched_scope_columns(target)
      config.scope.select do |column|
        !target.respond_to?(column) ||
          !record.respond_to?(column) ||
          target.public_send(column) != record.public_send(column)
      end
    end
  end
end
