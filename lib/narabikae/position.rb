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

    # Finds the position after the specified target.
    # If generated key is invalid(ex: it already exists),
    # a new key is generated until the challenge count reaches the limit.
    # challenge count is 10 by default.
    #
    # @param target [#send(field)]
    # @param args [Hash] Additional arguments.
    # @option args [Integer] :challenge The number of times to attempt finding a valid position.
    # @return [String, nil] The generated key for the position after the target, or nil if no valid position is found.
    def find_position_after(target, **args)
      merged_args = { challenge: 10 }.merge(args)
      # when target is nil, try to generate key from the last position
      target_key = target&.send(option.field) || current_last_position
      key = FractionalIndexer.generate_key(prev_key: target_key)
      return key if valid?(key)

      (merged_args[:challenge] || 0).times do
        safe_chars = find_safe_chars_after(key, target_key)
        break if safe_chars.empty? # No safe characters available (shouldn't happen for after)

        char = safe_chars.sample
        key += char
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
    # @param args [Hash] Additional arguments.
    # @option args [Integer] :challenge The number of times to attempt finding a valid position.
    # @return [String, nil] The generated key for the position before the target, or nil if no valid position is found.
    def find_position_before(target, **args)
      merged_args = { challenge: 10 }.merge(args)
      # when target is nil, try to generate key from the first position
      target_key = target&.send(option.field) || current_first_position
      key = FractionalIndexer.generate_key(next_key: target_key)
      return key if valid?(key)

      (merged_args[:challenge] || 0).times do
        safe_chars = find_safe_chars_before(key, target_key)
        break if safe_chars.empty? # No safe characters available

        char = safe_chars.sample
        key += char
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
    # @param args [Hash] Additional arguments.
    # @option args [Integer] :challenge The number of times to attempt finding a valid position.
    # @return [string, nil] The position between the two targets, or nil if no valid position is found.
    def find_position_between(prev_target, next_target, **args)
      return find_position_before(next_target, **args) if prev_target.blank?
      return find_position_after(prev_target, **args)  if next_target.blank?

      merged_args = { challenge: 10 }.merge(args)

      prev_key, next_key = [ prev_target.send(option.field), next_target.send(option.field) ].minmax
      key = FractionalIndexer.generate_key(
              prev_key: prev_key,
              next_key: next_key,
            )
      return key if valid?(key)

      (merged_args[:challenge] || 0).times do
        safe_chars = find_safe_chars_between(key, prev_key, next_key)
        break if safe_chars.empty? # No safe characters available

        char = safe_chars.sample
        key += char
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

    def find_safe_chars_before(base_key, target_key)
      # Use digits[1..] to avoid trailing zeros in fractional part
      digits = FractionalIndexer.configuration.digits[1..]

      # If base_key is already >= target_key, no character can fix this
      return [] if base_key >= target_key

      # Special case: if we need '0' to maintain order, include it
      # This happens when base_key + '0' < target_key but base_key + '1' >= target_key
      if base_key + "0" < target_key && base_key + "1" >= target_key
        return [ "0" ]
      end

      # Find the first character that would make base_key + char >= target_key
      # Since digits are ordered, all characters before this are safe
      boundary_index = digits.find_index { |char| base_key + char >= target_key }

      if boundary_index.nil?
        # All characters are safe
        digits
      elsif boundary_index == 0
        # No characters are safe (except possibly '0' handled above)
        []
      else
        # Characters before boundary_index are safe
        digits[0...boundary_index]
      end
    end

    def find_safe_chars_after(base_key, target_key)
      # For find_position_after, any character maintains order
      # since base_key > target_key and base_key + char > base_key > target_key
      # Use digits[1..] to avoid trailing zeros in fractional part
      FractionalIndexer.configuration.digits[1..]
    end

    def find_safe_chars_between(base_key, prev_key, next_key)
      # Use digits[1..] to avoid trailing zeros in fractional part
      digits = FractionalIndexer.configuration.digits[1..]
      all_digits = FractionalIndexer.configuration.digits

      # Find minimum character where base_key + char > prev_key
      min_char_index = all_digits.find_index { |char| base_key + char > prev_key }
      return [] if min_char_index.nil?

      # Find first character where base_key + char >= next_key
      max_char_index = all_digits.find_index { |char| base_key + char >= next_key }

      # Special case: if only '0' works, return it
      if min_char_index == 0 && max_char_index == 1
        return [ "0" ]
      end

      # Filter to only include non-zero digits that are in the safe range
      safe_chars = []
      digits.each do |char|
        char_value = all_digits.index(char)
        if char_value >= min_char_index && (max_char_index.nil? || char_value < max_char_index)
          safe_chars << char
        end
      end

      safe_chars
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
  end
end
