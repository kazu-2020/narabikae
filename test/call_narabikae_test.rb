require "test_helper"

class CallNarabikaeTest < ActiveSupport::TestCase
  setup do
    load Rails.root.join("app/models/sample.rb")
  end

  teardown do
    Object.send(:remove_const, "Sample") if Object.const_defined?("Sample")
  end

  test "defines dynamic methods for each field" do
    Sample.narabikae :order, size: 100
    Sample.narabikae :position, size: 500

    sample = Sample.new

    assert_respond_to sample, :set_order_after
    assert_respond_to sample, :set_order_before
    assert_respond_to sample, :set_order_between
    assert_respond_to sample, :order_after=
    assert_respond_to sample, :order_before=
    assert_respond_to sample, :order_between=

    assert_respond_to sample, :move_to_order_after
    assert_respond_to sample, :move_to_order_before
    assert_respond_to sample, :move_to_order_between

    assert_respond_to sample, :set_position_after
    assert_respond_to sample, :set_position_before
    assert_respond_to sample, :set_position_between
    assert_respond_to sample, :position_after=
    assert_respond_to sample, :position_before=
    assert_respond_to sample, :position_between=

    assert_respond_to sample, :move_to_position_after
    assert_respond_to sample, :move_to_position_before
    assert_respond_to sample, :move_to_position_between
  end
end

class CallNarabikaeDuplicateDefinitionTest < ActiveSupport::TestCase
  setup do
    load Rails.root.join("app/models/sample.rb")
  end

  teardown do
    Object.send(:remove_const, "Sample") if Object.const_defined?("Sample")
  end

  test "raises when registering the same field twice" do
    Sample.narabikae :order, size: 100

    error = assert_raises(Narabikae::Error) do
      Sample.narabikae :order, size: 100
    end

    assert_equal "the field `order` is already registered", error.message
  end
end
