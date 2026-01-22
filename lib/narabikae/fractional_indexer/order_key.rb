# frozen_string_literal: true

module Narabikae
  class FractionalIndexer
    # OrderKey represents a fractional index key and provides methods to manipulate it.
    class OrderKey
      INTEGER_BASE_DIGIT = 2
      POSITIVE_SIGNS = ("a".."z")
      NEGATIVE_SIGNS = ("A".."Z")

      attr_reader :key, :indexer

      # Initializes a new instance of OrderKey.
      #
      # @param key [String, :zero] The key string or :zero symbol.
      # @param indexer [FractionalIndexer] The indexer instance.
      def initialize(key, indexer:)
        @indexer = indexer
        @key = key == :zero ? "a#{indexer.digits.first}" : key
      end

      # Checks if the key is negative.
      #
      # @param key [String] The key to check.
      # @return [Boolean]
      def negative?(key = self.key)
        NEGATIVE_SIGNS.cover?(key[0])
      end

      # Checks if the key is positive.
      #
      # @param key [String] The key to check.
      # @return [Boolean]
      def positive?(key = self.key)
        POSITIVE_SIGNS.cover?(key[0])
      end

      # Decrements the order key.
      #
      # @raise [FractionalIndexer::Error] If decrement is not possible.
      # @return [String]
      def decrement
        new_order_key = indexer.execute_decrement(self)
        raise_error("it cannot decrement for min integer") if new_order_key.nil?

        new_order_key
      end

      # Returns the fractional part of the key.
      #
      # @return [String]
      def fractional
        validate!

        key[integer_digits..]
      end

      # Increments the order key.
      #
      # @raise [FractionalIndexer::Error] If increment is not possible.
      # @return [String]
      def increment
        new_order_key = indexer.execute_increment(self)
        raise_error("it cannot increment for max integer") if new_order_key.nil?

        new_order_key
      end

      # Returns the integer part of the key.
      #
      # @return [String]
      def integer
        validate!

        key[0, integer_digits]
      end

      # Checks if the integer part is the maximum possible.
      # @return [Boolean]
      def maximum_integer?
        integer == maximum_integer
      end

      # Checks if the integer part is the minimum possible.
      # @return [Boolean]
      def minimum_integer?
        integer == minimum_integer
      end

      # Checks if the key is the absolute minimum possible.
      # @return [Boolean]
      def minimum?
        minimum_integer? && fractional.empty?
      end

      # Checks if the key is present (not nil or empty).
      # @return [Boolean]
      def present?
        !(key.nil? || key.empty?)
      end

      private

      # Returns the digits from the indexer.
      # @return [Array<String>]
      def digits
        indexer.digits
      end

      # Calculates the number of digits in the integer part of the key.
      #
      # @param key [String]
      # @return [Integer]
      def integer_digits(key = self.key)
        if positive?(key)
          key.ord - "a".ord + INTEGER_BASE_DIGIT
        elsif negative?(key)
          "Z".ord - key.ord + INTEGER_BASE_DIGIT
        else
          raise_error("prefix '#{key[0]}' is invalid. It should be a-z or A-Z.")
        end
      end

      # Returns the maximum possible integer part.
      # @return [String]
      def maximum_integer
        "z#{digits.last * POSITIVE_SIGNS.count}"
      end

      # Returns the minimum possible integer part.
      # @return [String]
      def minimum_integer
        "A#{digits.first * POSITIVE_SIGNS.count}"
      end

      # Raises a FractionalIndexer::Error with a specific description.
      # @param description [String, nil]
      # @raise [FractionalIndexer::Error]
      def raise_error(description = nil)
        raise FractionalIndexer::Error, "invalid order key: '#{key}' description: #{description}"
      end

      # Validates the fractional part.
      # @param fractional [String]
      # @return [Boolean]
      def valid_fractional?(fractional)
        !fractional.end_with?(digits.first)
      end

      # Validates the integer part.
      # @param integer [String]
      # @return [Boolean]
      def valid_integer?(integer)
        integer.length == integer_digits
      end

      # Validates the entire key.
      # @raise [FractionalIndexer::Error] If validation fails.
      # @return [void]
      def validate!
        integer = key[0, integer_digits]
        raise_error("integer '#{integer}' is invalid.") unless valid_integer?(integer)

        fractional = key[integer_digits..]
        raise_error("fractional '#{fractional}' is invalid.") unless valid_fractional?(fractional)
      end
    end
  end
end
