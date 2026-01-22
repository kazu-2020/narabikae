# frozen_string_literal: true

require_relative "fractional_indexer/order_key"

module Narabikae
  # FractionalIndexer provides logic for generating fractional index keys.
  class FractionalIndexer
    # Error raised by FractionalIndexer.
    class Error < StandardError; end

    # Supported bases and their corresponding digit characters.
    DIGITS_LIST = {
      10 => ("0".."9").to_a,
      62 => ("0".."9").to_a + ("A".."Z").to_a + ("a".."z").to_a,
      94 => ("!".."~").to_a
    }.freeze

    attr_reader :base, :digits

    # Initializes a new instance of FractionalIndexer.
    #
    # @param base [Integer] The base for fractional indexing (10, 62, or 94).
    def initialize(base: 62)
      @base = base
      @digits = DIGITS_LIST[base]
    end

    # Generates a new fractional index key.
    #
    # @param prev_key [String, nil] The key of the previous item.
    # @param next_key [String, nil] The key of the next item.
    # @raise [Error] If keys are empty or in invalid order.
    # @return [String, nil] The newly generated key.
    def generate_key(prev_key: nil, next_key: nil)
      return OrderKey.new(:zero, indexer: self).key if prev_key.nil? && next_key.nil?

      raise Error, "prev_key and next_key cannot be empty" if prev_key&.empty? || next_key&.empty?

      if !prev_key.nil? && !next_key.nil? && prev_key >= next_key
        raise Error, "#{prev_key} is not less than #{next_key}"
      end

      prev_order_key = OrderKey.new(prev_key, indexer: self)
      next_order_key = OrderKey.new(next_key, indexer: self)

      return decrement(next_order_key) unless prev_order_key.present?
      return increment(prev_order_key) unless next_order_key.present?

      if prev_order_key.integer == next_order_key.integer
        return prev_order_key.integer + midpoint(prev_order_key.fractional, next_order_key.fractional)
      end

      incremented_order_key = OrderKey.new(execute_increment(prev_order_key), indexer: self)
      if incremented_order_key.key < next_key
        incremented_order_key.key
      else
        prev_order_key.integer + midpoint(prev_order_key.fractional, nil)
      end
    end

    # Generates multiple fractional index keys.
    #
    # @param prev_key [String, nil] The key of the previous item.
    # @param next_key [String, nil] The key of the next item.
    # @param count [Integer] The number of keys to generate.
    # @return [Array<String>] The generated keys.
    def generate_keys(prev_key: nil, next_key: nil, count: 1)
      return [] if count <= 0
      return [ generate_key(prev_key: prev_key, next_key: next_key) ] if count == 1

      if next_key.nil?
        base_order_key = generate_key(prev_key: prev_key)
        result = [ base_order_key ]

        (count - 1).times do
          result << generate_key(prev_key: result.last)
        end

        return result
      end

      if prev_key.nil?
        base_order_key = generate_key(next_key: next_key)
        result = [ base_order_key ]

        (count - 1).times do
          result << generate_key(next_key: result.last)
        end

        return result.reverse
      end

      mid = count / 2
      base_order_key = generate_key(prev_key: prev_key, next_key: next_key)

      [
        *generate_keys(prev_key: prev_key, next_key: base_order_key, count: mid),
        base_order_key,
        *generate_keys(prev_key: base_order_key, next_key: next_key, count: count - mid - 1)
      ]
    end

    # Decrements the given order key.
    #
    # @param order_key [OrderKey, String] The key to decrement.
    # @raise [Error] If the key is the minimum possible value.
    # @return [String, nil] The decremented key.
    def decrement(order_key)
      order_key = OrderKey.new(order_key, indexer: self) unless order_key.is_a?(OrderKey)

      if order_key.minimum?
        raise Error, "order key not decremented: #{order_key.key} is the minimum value"
      end
      return order_key.integer + midpoint("", order_key.fractional) if order_key.minimum_integer?

      decremented_key = order_key.integer < order_key.key ? order_key.integer : execute_decrement(order_key)
      return nil if decremented_key.nil?

      decremented_order_key = OrderKey.new(decremented_key, indexer: self)
      return decremented_order_key.integer + midpoint(nil, nil) if decremented_order_key.minimum?

      decremented_order_key.key
    end

    # Increments the given order key.
    #
    # @param order_key [OrderKey, String] The key to increment.
    # @return [String, nil] The incremented key.
    def increment(order_key)
      order_key = OrderKey.new(order_key, indexer: self) unless order_key.is_a?(OrderKey)

      return order_key.integer + midpoint(order_key.fractional, "") if order_key.maximum_integer?

      execute_increment(order_key)
    end

    # Low-level decrement execution.
    # @param order_key [OrderKey]
    # @return [String, nil]
    def execute_decrement(order_key)
      prefix, *digs = order_key.integer.chars
      borrow = true

      (digs.length - 1).downto(0) do |i|
        decremented_index = digits.index(digs[i]) - 1

        if decremented_index == -1 # borrow?
          digs[i] = digits[-1]
        else
          digs[i] = digits[decremented_index]
          borrow  = false

          break
        end
      end

      return prefix + digs.join unless borrow

      return "Z#{digits[-1]}" if prefix == "a"
      return if prefix == "A"

      new_key = (prefix.ord - 1).chr
      new_key < "Z" ? digs.push(digits[-1]) : digs.pop

      new_key + digs.join
    end

    # Low-level increment execution.
    # @param order_key [OrderKey]
    # @return [String, nil]
    def execute_increment(order_key)
      prefix, *digs = order_key.integer.chars
      carry = true

      (digs.length - 1).downto(0) do |i|
        incremented_index = digits.index(digs[i]) + 1

        if incremented_index == digits.length # carry_over?
          digs[i] = digits[0]
        else
          digs[i] = digits[incremented_index]
          carry   = false

          break
        end
      end

      return prefix + digs.join unless carry

      return OrderKey.new(:zero, indexer: self).key if prefix == "Z"
      return if prefix == "z"

      new_key = (prefix.ord + 1).chr
      new_key > "a" ? digs.push("0") : digs.pop

      new_key + digs.join
    end

    private

    # Calculates the midpoint between two position strings.
    #
    # @param prev_pos [String, nil]
    # @param next_pos [String, nil]
    # @return [String]
    def midpoint(prev_pos, next_pos)
      prev_pos = prev_pos.to_s
      next_pos = next_pos.to_s

      return digits[digits.length / 2] if prev_pos.empty? && next_pos.empty?

      validate_positions!(prev_pos, next_pos)

      unless next_pos.empty?
        n = 0

        # Get a common prefix for prev_pos and next_pos.
        # Also add to the prefix the number of consecutive "0 "s in next_pos.
        # Example:
        #  prev_pos = "123", next_pos = "1230005"
        #  prefix = "123000"
        n += 1 while (prev_pos[n] || digits.first) == next_pos[n]

        return next_pos[0, n] + midpoint(prev_pos[n..], next_pos[n..]) if n.positive?
      end

      digit_a = prev_pos.empty?   ? 0             : digits.index(prev_pos[0])
      digit_b = next_pos.empty?   ? digits.length : digits.index(next_pos[0])

      if digit_b - digit_a > 1
        mid_digit = ((digit_a + digit_b) / 2.0).round

        return digits[mid_digit]
      end

      if next_pos.length > 1
        next_pos[0]
      else
        digits[digit_a] + midpoint(prev_pos[1..], nil)
      end
    end

    # Validates position strings.
    #
    # @param prev_pos [String]
    # @param next_pos [String]
    # @raise [Error] If validation fails.
    # @return [void]
    def validate_positions!(prev_pos, next_pos)
      raise Error, "prev_pos must be less than next_pos" if !next_pos.empty? && prev_pos >= next_pos

      # NOTE
      # In a string, "0.3" and "0.30" are mathematically equivalent.
      # Therefore, a trailing "0" is prohibited.
      return unless prev_pos.end_with?(digits.first) || next_pos.end_with?(digits.first)

      # Match original gem's error message more closely if possible,
      # but original used hardcoded "0" in error message too.
      raise Error, "prev_pos and next_pos cannot end with #{digits.first}"
    end
  end
end
