# frozen_string_literal: true

module Narabikae
  class FractionalIndexer
    class OrderKey
      INTEGER_BASE_DIGIT = 2
      POSITIVE_SIGNS = ("a".."z")
      NEGATIVE_SIGNS = ("A".."Z")

      attr_reader :key, :indexer

      def initialize(key, indexer:)
        @indexer = indexer
        @key = key == :zero ? "a#{indexer.digits.first}" : key
      end

      def negative?(key = self.key)
        NEGATIVE_SIGNS.cover?(key[0])
      end

      def positive?(key = self.key)
        POSITIVE_SIGNS.cover?(key[0])
      end

      def decrement
        new_order_key = indexer.execute_decrement(self)
        raise_error("it cannot decrement for min integer") if new_order_key.nil?

        new_order_key
      end

      def fractional
        validate!

        key[integer_digits..]
      end

      def increment
        new_order_key = indexer.execute_increment(self)
        raise_error("it cannot increment for max integer") if new_order_key.nil?

        new_order_key
      end

      def integer
        validate!

        key[0, integer_digits]
      end

      def maximum_integer?
        integer == maximum_integer
      end

      def minimum_integer?
        integer == minimum_integer
      end

      def minimum?
        minimum_integer? && fractional.empty?
      end

      def present?
        !(key.nil? || key.empty?)
      end

      private

      def digits
        indexer.digits
      end

      def integer_digits(key = self.key)
        if positive?(key)
          key.ord - "a".ord + INTEGER_BASE_DIGIT
        elsif negative?(key)
          "Z".ord - key.ord + INTEGER_BASE_DIGIT
        else
          raise_error("prefix '#{key[0]}' is invalid. It should be a-z or A-Z.")
        end
      end

      def maximum_integer
        "z#{digits.last * POSITIVE_SIGNS.count}"
      end

      def minimum_integer
        "A#{digits.first * POSITIVE_SIGNS.count}"
      end

      def raise_error(description = nil)
        raise FractionalIndexer::Error, "invalid order key: '#{key}' description: #{description}"
      end

      def valid_fractional?(fractional)
        !fractional.end_with?(digits.first)
      end

      def valid_integer?(integer)
        integer.length == integer_digits
      end

      def validate!
        integer = key[0, integer_digits]
        raise_error("integer '#{integer}' is invalid.") unless valid_integer?(integer)

        fractional = key[integer_digits..]
        raise_error("fractional '#{fractional}' is invalid.") unless valid_fractional?(fractional)
      end
    end
  end
end
