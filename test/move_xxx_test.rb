require "test_helper"

class MoveXxxTest < ActiveSupport::TestCase
  setup do
    load Rails.root.join("app/models/sample.rb")
    Sample.narabikae :position, size: 100
    Sample.narabikae :order, size: 100
  end

  teardown do
    Object.send(:remove_const, "Sample") if Object.const_defined?("Sample")
  end

  test "move_to_position_after moves to end when target is nil" do
    current = Sample.create

    assert_equal "a0", current.position
    assert_equal true, current.move_to_position_after(nil)
    assert_equal "a1", current.reload.position
  end

  test "move_to_position_after moves after target" do
    current = Sample.create
    target = Sample.create

    assert_equal "a0", current.position
    assert_equal true, current.move_to_position_after(target)
    assert_equal "a2", current.reload.position
  end

  test "move_to_position_before moves to start when target is nil" do
    current = Sample.create

    assert_equal "a0", current.position
    assert_equal true, current.move_to_position_before(nil)
    assert_equal "Zz", current.reload.position
  end

  test "move_to_position_before moves before target" do
    current = Sample.create
    target = Sample.create

    assert_equal true, current.move_to_position_before(target)

    new_position = current.reload.position
    assert new_position.start_with?("a0V")
    assert_equal 4, new_position.length
  end

  test "move_to_position_between behaves like before when prev is nil" do
    current = Sample.create
    next_target = Sample.create

    assert_equal true, current.move_to_position_between(nil, next_target)

    new_position = current.reload.position
    assert new_position.start_with?("a0V")
    assert_equal 4, new_position.length
  end

  test "move_to_position_between behaves like after when next is nil" do
    current = Sample.create
    prev_target = Sample.create

    assert_equal true, current.move_to_position_between(prev_target, nil)
    assert_equal "a2", current.reload.position
  end

  test "move_to_position_between places between targets" do
    current = Sample.create
    prev_target = Sample.create
    next_target = Sample.create

    assert_equal true, current.move_to_position_between(prev_target, next_target)
    assert_equal "a1V", current.reload.position
  end

  test "set_position_after updates in-memory only" do
    current = Sample.create

    assert_equal "a0", current.position
    assert_equal "a1", current.set_position_after(nil)
    assert_equal "a1", current.position
    assert_equal "a0", current.reload.position
  end

  test "set_position_before updates in-memory only" do
    current = Sample.create

    assert_equal "a0", current.position
    assert_equal "Zz", current.set_position_before(nil)
    assert_equal "Zz", current.position
    assert_equal "a0", current.reload.position
  end

  test "set_position_between updates in-memory only" do
    current = Sample.create
    next_target = Sample.create

    assert_equal "a0", current.position

    new_position = current.set_position_between(nil, next_target)
    assert new_position.start_with?("a0V")
    assert_equal 4, new_position.length
    assert_equal new_position, current.position
    assert_equal "a0", current.reload.position
  end

  test "position_after= updates in-memory only" do
    current = Sample.create
    target = Sample.create

    assert_equal target, (current.position_after = target)
    assert_equal "a2", current.position
    assert_equal "a0", current.reload.position
  end

  test "position_between= updates in-memory only" do
    current = Sample.create
    prev_target = Sample.create
    next_target = Sample.create

    assert_equal [ prev_target, next_target ], (current.position_between = [ prev_target, next_target ])
    assert_equal "a1V", current.position
    assert_equal "a0", current.reload.position
  end
end
