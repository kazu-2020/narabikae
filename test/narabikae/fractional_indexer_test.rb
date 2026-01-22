# frozen_string_literal: true

require "test_helper"

class Narabikae::FractionalIndexerTest < ActiveSupport::TestCase
  OrderKey = Narabikae::FractionalIndexer::OrderKey

  setup do
    @indexer = Narabikae::FractionalIndexer.new(base: 62)
    @indexer_10 = Narabikae::FractionalIndexer.new(base: 10)
    @indexer_62 = @indexer
  end

  # --- generate_key tests ---

  test "generate_key when prev_key is nil and next_key is nil" do
    assert_equal "a0", @indexer.generate_key(prev_key: nil, next_key: nil)
  end

  test "generate_key when prev_key is less than next_key" do
    error = assert_raises(Narabikae::FractionalIndexer::Error) do
      @indexer.generate_key(prev_key: "a0", next_key: "Z9")
    end
    assert_equal "a0 is not less than Z9", error.message
  end

  test "generate_key when prev_key is empty and next_key is 'a0'" do
    error = assert_raises(Narabikae::FractionalIndexer::Error) do
      @indexer.generate_key(prev_key: "", next_key: "a0")
    end
    assert_equal "prev_key and next_key cannot be empty", error.message
  end

  test "generate_key when prev_key is 'a0' and next_key is empty" do
    error = assert_raises(Narabikae::FractionalIndexer::Error) do
      @indexer.generate_key(prev_key: "a0", next_key: "")
    end
    assert_equal "prev_key and next_key cannot be empty", error.message
  end

  test "generate_key when prev_key is nil and next_key is 'a0'" do
    assert_equal "Zz", @indexer.generate_key(prev_key: nil, next_key: "a0")
  end

  test "generate_key when prev_key is 'a0' and next_key is nil" do
    assert_equal "a1", @indexer.generate_key(prev_key: "a0", next_key: nil)
  end

  test "generate_key when prev_key is 'a0' and next_key is 'a1'" do
    assert_equal "a0V", @indexer.generate_key(prev_key: "a0", next_key: "a1")
  end

  test "generate_key when prev_key is 'a0V' and next_key is 'a1'" do
    assert_equal "a0l", @indexer.generate_key(prev_key: "a0V", next_key: "a1")
  end

  test "generate_key when prev_key is 'Zz' and next_key is 'a0'" do
    assert_equal "ZzV", @indexer.generate_key(prev_key: "Zz", next_key: "a0")
  end

  test "generate_key when prev_key is 'Zz' and next_key is 'a1'" do
    assert_equal "a0", @indexer.generate_key(prev_key: "Zz", next_key: "a1")
  end

  test "generate_key when prev_key is nil and next_key is 'Y00'" do
    assert_equal "Xzzz", @indexer.generate_key(prev_key: nil, next_key: "Y00")
  end

  test "generate_key when prev_key is 'bzz' and next_key is nil" do
    assert_equal "c000", @indexer.generate_key(prev_key: "bzz", next_key: nil)
  end

  test "generate_key when prev_key is 'a0' and next_key is 'a0V'" do
    assert_equal "a0G", @indexer.generate_key(prev_key: "a0", next_key: "a0V")
  end

  test "generate_key when prev_key is 'a0' and next_key is 'a0G'" do
    assert_equal "a08", @indexer.generate_key(prev_key: "a0", next_key: "a0G")
  end

  test "generate_key when prev_key is 'b125' and next_key is 'b129'" do
    assert_equal "b127", @indexer.generate_key(prev_key: "b125", next_key: "b129")
  end

  test "generate_key when prev_key is 'a0' and next_key is 'a1V'" do
    assert_equal "a1", @indexer.generate_key(prev_key: "a0", next_key: "a1V")
  end

  test "generate_key when prev_key is 'Zz' and next_key is 'a01'" do
    assert_equal "a0", @indexer.generate_key(prev_key: "Zz", next_key: "a01")
  end

  test "generate_key when prev_key is nil and next_key is 'a0V'" do
    assert_equal "a0", @indexer.generate_key(prev_key: nil, next_key: "a0V")
  end

  test "generate_key when prev_key is nil and next_key is 'b999'" do
    assert_equal "b99", @indexer.generate_key(prev_key: nil, next_key: "b999")
  end

  test "generate_key when prev_key is nil and next_key is 'A00000000000000000000000000'" do
     assert_raises(Narabikae::FractionalIndexer::Error) do
       @indexer.generate_key(prev_key: nil, next_key: "A00000000000000000000000000")
     end
  end

  test "generate_key when prev_key is nil and next_key is minimum integer" do
    assert_raises(Narabikae::FractionalIndexer::Error) do
      @indexer.generate_key(prev_key: nil, next_key: "A" + "0" * 26)
    end
  end

  test "generate_key when prev_key is nil and next_key is 'A00000000000000000000000001'" do
    assert_equal "A00000000000000000000000000V", @indexer.generate_key(prev_key: nil, next_key: "A00000000000000000000000001")
  end

  test "generate_key when prev_key is nil and next_key is 'A000000000000000000000000001'" do
    assert_equal "A000000000000000000000000000V", @indexer.generate_key(prev_key: nil, next_key: "A000000000000000000000000001")
  end

  test "generate_key when prev_key is max integer - 1 + y and next_key is nil" do
    prev_key = "z" * 26 + "y"
    assert_equal "z" * 27, @indexer.generate_key(prev_key: prev_key, next_key: nil)
  end

  test "generate_key when prev_key is max integer and next_key is nil" do
    prev_key = "z" * 27
    assert_equal "z" * 27 + "V", @indexer.generate_key(prev_key: prev_key, next_key: nil)
  end

  test "generate_key when prev_key is 'a00' and next_key is nil" do
    assert_raises(Narabikae::FractionalIndexer::Error) do
      @indexer.generate_key(prev_key: "a00", next_key: nil)
    end
  end

  test "generate_key when prev_key is 'a00' and next_key is 'a1'" do
    assert_raises(Narabikae::FractionalIndexer::Error) do
      @indexer.generate_key(prev_key: "a00", next_key: "a1")
    end
  end

  test "generate_key when prev_key is '0' and next_key is '1'" do
    assert_raises(Narabikae::FractionalIndexer::Error) do
      @indexer.generate_key(prev_key: "0", next_key: "1")
    end
  end

  # --- generate_keys tests ---

  test "generate_keys with count 0" do
    indexer = Narabikae::FractionalIndexer.new(base: 10)
    assert_equal [], indexer.generate_keys(prev_key: "a0", next_key: nil, count: 0)
  end

  test "generate_keys with count -1" do
    indexer = Narabikae::FractionalIndexer.new(base: 10)
    assert_equal [], indexer.generate_keys(prev_key: "a0", next_key: nil, count: -1)
  end

  test "generate_keys with base 10 when prev_key nil and next_key nil count 5" do
    indexer = Narabikae::FractionalIndexer.new(base: 10)
    expected = [ "a0", "a1", "a2", "a3", "a4" ]
    assert_equal expected, indexer.generate_keys(prev_key: nil, next_key: nil, count: 5)
  end

  test "generate_keys with base 10 when prev_key a41 next_key nil count 5" do
    indexer = Narabikae::FractionalIndexer.new(base: 10)
    expected = [ "a5", "a6", "a7", "a8", "a9" ]
    assert_equal expected, indexer.generate_keys(prev_key: "a41", next_key: nil, count: 5)
  end

  test "generate_keys with base 10 when prev_key nil next_key a1 count 2" do
    indexer = Narabikae::FractionalIndexer.new(base: 10)
    expected = [ "Z9", "a0" ]
    assert_equal expected, indexer.generate_keys(prev_key: nil, next_key: "a1", count: 2)
  end

  test "generate_keys with base 10 when prev_key a0 next_key a2 count 20" do
    indexer = Narabikae::FractionalIndexer.new(base: 10)
    expected = [
          "a01",
          "a02",
          "a03",
          "a035",
          "a04",
          "a05",
          "a06",
          "a07",
          "a08",
          "a09",
          "a1",
          "a11",
          "a12",
          "a13",
          "a14",
          "a15",
          "a16",
          "a17",
          "a18",
          "a19"
        ]
    assert_equal expected, indexer.generate_keys(prev_key: "a0", next_key: "a2", count: 20)
  end

  test "generate_keys with base 10 when prev_key nil next_key A...1 count 5" do
    indexer = Narabikae::FractionalIndexer.new(base: 10)
    next_key = "A000000000000000000000000001"
    expected = [
          "A00000000000000000000000000005",
          "A0000000000000000000000000001",
          "A0000000000000000000000000002",
          "A0000000000000000000000000003",
          "A0000000000000000000000000005"
        ]
    assert_equal expected, indexer.generate_keys(prev_key: nil, next_key: next_key, count: 5)
  end

  # --- OrderKey tests (covering Decrementer/Incrementer/Validation) ---

  test "OrderKey.negative? when key is nil" do
    order_key = OrderKey.new(nil, indexer: @indexer)
    assert_raises(NoMethodError) { order_key.negative? }
  end

  test "OrderKey.negative? when key is empty" do
    order_key = OrderKey.new("", indexer: @indexer)
    assert_not order_key.negative?
  end

  test "OrderKey.negative? when key is negative" do
    order_key = OrderKey.new("Z0", indexer: @indexer)
    assert order_key.negative?
  end

  test "OrderKey.negative? when key is positive" do
    order_key = OrderKey.new("a0", indexer: @indexer)
    assert_not order_key.negative?
  end

  test "OrderKey.positive? when key is nil" do
    order_key = OrderKey.new(nil, indexer: @indexer)
    assert_raises(NoMethodError) { order_key.positive? }
  end

  test "OrderKey.positive? when key is empty" do
    order_key = OrderKey.new("", indexer: @indexer)
    assert_not order_key.positive?
  end

  test "OrderKey.positive? when key is negative" do
    order_key = OrderKey.new("Z0", indexer: @indexer)
    assert_not order_key.positive?
  end

  test "OrderKey.positive? when key is positive" do
    order_key = OrderKey.new("a0", indexer: @indexer)
    assert order_key.positive?
  end

  test "OrderKey zero when base is 10" do
    indexer = Narabikae::FractionalIndexer.new(base: 10)
    assert_equal "a0", OrderKey.new(:zero, indexer: indexer).key
  end

  test "OrderKey zero when base is 62" do
    indexer = Narabikae::FractionalIndexer.new(base: 62)
    assert_equal "a0", OrderKey.new(:zero, indexer: indexer).key
  end

  test "OrderKey zero when base is 94" do
    indexer = Narabikae::FractionalIndexer.new(base: 94)
    assert_equal "a!", OrderKey.new(:zero, indexer: indexer).key
  end

  test "OrderKey#decrement when key is 'A' + '0' * 26" do
    key = "A" + "0" * 26
    order_key = OrderKey.new(key, indexer: @indexer)
    error_message = "invalid order key: 'A00000000000000000000000000' description: it cannot decrement for min integer"
    error = assert_raises(Narabikae::FractionalIndexer::Error) { order_key.decrement }
    assert_equal error_message, error.message
  end

  test "OrderKey#decrement when key is 'a1'" do
    order_key = OrderKey.new("a1", indexer: @indexer)
    assert_equal "a0", order_key.decrement
  end

  test "OrderKey#decrement when key is 'a0'" do
    order_key = OrderKey.new("a0", indexer: @indexer)
    assert_equal "Zz", order_key.decrement
  end

  test "OrderKey#increment when key is 'z' + 'z' * 26" do
    key = "z" + "z" * 26
    order_key = OrderKey.new(key, indexer: @indexer)
    error_message = "invalid order key: 'zzzzzzzzzzzzzzzzzzzzzzzzzzz' description: it cannot increment for max integer"
    error = assert_raises(Narabikae::FractionalIndexer::Error) { order_key.increment }
    assert_equal error_message, error.message
  end

  test "OrderKey#increment when key is 'Zz'" do
    order_key = OrderKey.new("Zz", indexer: @indexer)
    assert_equal "a0", order_key.increment
  end

  test "OrderKey#increment when key is 'a1'" do
    order_key = OrderKey.new("a1", indexer: @indexer)
    assert_equal "a2", order_key.increment
  end

  test "OrderKey#fractional invalid" do
    key = "a0010"
    order_key = OrderKey.new(key, indexer: @indexer)
    error_message = "invalid order key: 'a0010' description: fractional '010' is invalid."
    error = assert_raises(Narabikae::FractionalIndexer::Error) { order_key.fractional }
    assert_equal error_message, error.message
  end

  test "OrderKey#fractional valid" do
    order_key = OrderKey.new("b120zZ", indexer: @indexer)
    assert_equal "0zZ", order_key.fractional
  end

  test "OrderKey#integer invalid digits" do
    key = "b1"
    order_key = OrderKey.new(key, indexer: @indexer)
    error_message = "invalid order key: 'b1' description: integer 'b1' is invalid."
    error = assert_raises(Narabikae::FractionalIndexer::Error) { order_key.integer }
    assert_equal error_message, error.message
  end

  test "OrderKey#integer invalid prefix" do
    key = "!9"
    order_key = OrderKey.new(key, indexer: @indexer)
    error_message = "invalid order key: '!9' description: prefix '!' is invalid. It should be a-z or A-Z."
    error = assert_raises(Narabikae::FractionalIndexer::Error) { order_key.integer }
    assert_equal error_message, error.message
  end

  test "OrderKey#integer valid digits" do
    order_key = OrderKey.new("d012A", indexer: @indexer)
    assert_equal "d012A", order_key.integer
  end

  test "OrderKey#integer with fractional" do
    order_key = OrderKey.new("b12z", indexer: @indexer)
    assert_equal "b12", order_key.integer
  end

  test "OrderKey#maximum_integer? true" do
    key = "z" + "z" * 26 + "a"
    order_key = OrderKey.new(key, indexer: @indexer)
    assert order_key.maximum_integer?
  end

  test "OrderKey#maximum_integer? false" do
    key = "z" + "z" * 25 + "a"
    order_key = OrderKey.new(key, indexer: @indexer)
    assert_not order_key.maximum_integer?
  end

  test "OrderKey#minimum_integer? true" do
    key = "A" + "0" * 26 + "z"
    order_key = OrderKey.new(key, indexer: @indexer)
    assert order_key.minimum_integer?
  end

  test "OrderKey#minimum_integer? false" do
    key = "A" + "0" * 25 + "1"
    order_key = OrderKey.new(key, indexer: @indexer)
    assert_not order_key.minimum_integer?
  end

  test "OrderKey#minimum? true" do
    key = "A" + "0" * 26
    order_key = OrderKey.new(key, indexer: @indexer)
    assert order_key.minimum?
  end

  test "OrderKey#minimum? false (with fractional)" do
    key = "A" + "0" * 26 + "2"
    order_key = OrderKey.new(key, indexer: @indexer)
    assert_not order_key.minimum?
  end

  test "OrderKey#present? true" do
    assert OrderKey.new("a0", indexer: @indexer).present?
  end

  test "OrderKey#present? false (nil)" do
    assert_not OrderKey.new(nil, indexer: @indexer).present?
  end

  test "OrderKey#present? false (empty)" do
    assert_not OrderKey.new("", indexer: @indexer).present?
  end

  # --- Direct FractionalIndexer execute_decrement/execute_increment tests (matching Decrementer/Incrementer specs) ---

  # Base 10 Decrement
  test "execute_decrement base 10: a1 -> a0" do
    assert_equal "a0", @indexer_10.execute_decrement(OrderKey.new("a1", indexer: @indexer_10))
  end

  test "execute_decrement base 10: a0 -> Z9" do
    assert_equal "Z9", @indexer_10.execute_decrement(OrderKey.new("a0", indexer: @indexer_10))
  end

  test "execute_decrement base 10: b00 -> a9" do
    assert_equal "a9", @indexer_10.execute_decrement(OrderKey.new("b00", indexer: @indexer_10))
  end

  test "execute_decrement base 10: Z0 -> Y99" do
    assert_equal "Y99", @indexer_10.execute_decrement(OrderKey.new("Z0", indexer: @indexer_10))
  end

  test "execute_decrement base 10: min value -> nil" do
    assert_nil @indexer_10.execute_decrement(OrderKey.new("A" + "0" * 26, indexer: @indexer_10))
  end

  # Base 62 Decrement
  test "execute_decrement base 62: b00 -> az" do
    assert_equal "az", @indexer_62.execute_decrement(OrderKey.new("b00", indexer: @indexer_62))
  end

  test "execute_decrement base 62: b10 -> b0z" do
    assert_equal "b0z", @indexer_62.execute_decrement(OrderKey.new("b10", indexer: @indexer_62))
  end

  test "execute_decrement base 62: c000 -> bzz" do
    assert_equal "bzz", @indexer_62.execute_decrement(OrderKey.new("c000", indexer: @indexer_62))
  end

  test "execute_decrement base 62: Zz -> Zy" do
    assert_equal "Zy", @indexer_62.execute_decrement(OrderKey.new("Zz", indexer: @indexer_62))
  end

  test "execute_decrement base 62: a0 -> Zz" do
    assert_equal "Zz", @indexer_62.execute_decrement(OrderKey.new("a0", indexer: @indexer_62))
  end

  test "execute_decrement base 62: Yzz -> Yzy" do
    assert_equal "Yzy", @indexer_62.execute_decrement(OrderKey.new("Yzz", indexer: @indexer_62))
  end

  test "execute_decrement base 62: Y00 -> Xzzz" do
    assert_equal "Xzzz", @indexer_62.execute_decrement(OrderKey.new("Y00", indexer: @indexer_62))
  end

  test "execute_decrement base 62: dAC00 -> dABzz" do
    assert_equal "dABzz", @indexer_62.execute_decrement(OrderKey.new("dAC00", indexer: @indexer_62))
  end

  test "execute_decrement base 62: min value -> nil" do
    assert_nil @indexer_62.execute_decrement(OrderKey.new("A" + "0" * 26, indexer: @indexer_62))
  end

  # Base 10 Increment
  test "execute_increment base 10: a0 -> a1" do
    assert_equal "a1", @indexer_10.execute_increment(OrderKey.new("a0", indexer: @indexer_10))
  end

  test "execute_increment base 10: a1 -> a2" do
    assert_equal "a2", @indexer_10.execute_increment(OrderKey.new("a1", indexer: @indexer_10))
  end

  test "execute_increment base 10: c999 -> d0000" do
    assert_equal "d0000", @indexer_10.execute_increment(OrderKey.new("c999", indexer: @indexer_10))
  end

  test "execute_increment base 10: Z999 -> a0" do
    assert_equal "a0", @indexer_10.execute_increment(OrderKey.new("Z999", indexer: @indexer_10))
  end

  test "execute_increment base 10: Y99 -> Z0" do
    assert_equal "Z0", @indexer_10.execute_increment(OrderKey.new("Y99", indexer: @indexer_10))
  end

  test "execute_increment base 10: max value -> nil" do
    key = "z" + "9" * 26
    assert_nil @indexer_10.execute_increment(OrderKey.new(key, indexer: @indexer_10))
  end

  # Base 62 Increment
  test "execute_increment base 62: az -> b00" do
    assert_equal "b00", @indexer_62.execute_increment(OrderKey.new("az", indexer: @indexer_62))
  end

  test "execute_increment base 62: a9 -> aA" do
    assert_equal "aA", @indexer_62.execute_increment(OrderKey.new("a9", indexer: @indexer_62))
  end

  test "execute_increment base 62: b0z -> b10" do
    assert_equal "b10", @indexer_62.execute_increment(OrderKey.new("b0z", indexer: @indexer_62))
  end

  test "execute_increment base 62: bzz -> c000" do
    assert_equal "c000", @indexer_62.execute_increment(OrderKey.new("bzz", indexer: @indexer_62))
  end

  test "execute_increment base 62: Zy -> Zz" do
    assert_equal "Zz", @indexer_62.execute_increment(OrderKey.new("Zy", indexer: @indexer_62))
  end

  test "execute_increment base 62: Yzy -> Yzz" do
    assert_equal "Yzz", @indexer_62.execute_increment(OrderKey.new("Yzy", indexer: @indexer_62))
  end

  test "execute_increment base 62: dABzz -> dAC00" do
    assert_equal "dAC00", @indexer_62.execute_increment(OrderKey.new("dABzz", indexer: @indexer_62))
  end

  test "execute_increment base 62: max value -> nil" do
    key = "z" + "z" * 26
    assert_nil @indexer_62.execute_increment(OrderKey.new(key, indexer: @indexer_62))
  end

  # --- Midpoint specific cases (from midpointer_spec.rb) ---

  test "midpoint base 10: nil, nil -> 5" do
    # generate_key(prev_key: "a0", next_key: "a1") calls midpoint("0", "1") -> "5"
    assert_equal "a05", Narabikae::FractionalIndexer.new(base: 10).generate_key(prev_key: "a0", next_key: "a1")
  end

  test "midpoint base 10 validation: prohibited trailing zero" do
    error = assert_raises(Narabikae::FractionalIndexer::Error) do
      @indexer_10.generate_key(prev_key: "a1", next_key: "a20")
    end
    assert_includes error.message, "fractional '0' is invalid"
  end
end
