require "test_helper"

class NarabikaeActiveRecordExtensionTest < ActiveSupport::TestCase
  test "auto_set_position? returns true when record has invalid key" do
    instance = Narabikae::ActiveRecordExtension.new(
      Task.new(position: "invalid"),
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    assert_equal true, instance.auto_set_position?
  end

  test "auto_set_position? returns false when record has no scope" do
    instance = Narabikae::ActiveRecordExtension.new(
      Task.create!(position: "a0"),
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    assert_equal false, instance.auto_set_position?
  end

  test "auto_set_position? returns false when scoped record has no change" do
    instance = Narabikae::ActiveRecordExtension.new(
      Task.create!(position: "a0"),
      :position,
      Narabikae::Configuration.new(key_max_size: 10, scope: %i[user_id])
    )

    assert_equal false, instance.auto_set_position?
  end

  test "auto_set_position? returns true when scope changes without position change" do
    record = Task.create!(position: "a0")
    record.user_id = 1

    instance = Narabikae::ActiveRecordExtension.new(
      record,
      :position,
      Narabikae::Configuration.new(key_max_size: 10, scope: %i[user_id])
    )

    assert_equal true, instance.auto_set_position?
  end

  test "auto_set_position? returns false when scope and position change" do
    record = Task.create!(position: "a0")
    record.user_id = 1
    record.position = "a1"

    instance = Narabikae::ActiveRecordExtension.new(
      record,
      :position,
      Narabikae::Configuration.new(key_max_size: 10, scope: %i[user_id])
    )

    assert_equal false, instance.auto_set_position?
  end

  test "set_position defaults to last" do
    record = Task.new
    instance = Narabikae::ActiveRecordExtension.new(
      record,
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    assert_nil record.position
    instance.set_position
    assert_equal "a0", record.position
  end

  test "set_position accepts :first" do
    Task.create!(position: "a0")
    record = Task.new
    instance = Narabikae::ActiveRecordExtension.new(
      record,
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    instance.set_position(:first)
    assert_equal "Zz", record.position
  end

  test "set_after returns false when position generation fails" do
    current = Task.create!(position: "a0")
    target = Task.new(position: "invalid")
    instance = Narabikae::ActiveRecordExtension.new(
      current,
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    assert_equal false, instance.set_after(target, challenge: 0)
    assert_equal "a0", current.position
    assert_equal "a0", current.reload.position
  end

  test "set_after assigns position when generation succeeds" do
    current = Task.create!(position: "a0")
    target = Task.create!(position: "b10abc")
    instance = Narabikae::ActiveRecordExtension.new(
      current,
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    assert_equal "b11", instance.set_after(target, challenge: 0)
    assert_equal "b11", current.position
    assert_equal "a0", current.reload.position
  end

  test "set_before returns false when position generation fails" do
    current = Task.create!(position: "a0")
    target = Task.new(position: "invalid")
    instance = Narabikae::ActiveRecordExtension.new(
      current,
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    assert_equal false, instance.set_before(target, challenge: nil)
    assert_equal "a0", current.position
    assert_equal "a0", current.reload.position
  end

  test "set_before assigns position when generation succeeds" do
    current = Task.create!(position: "a0")
    target = Task.create!(position: "b10abc")
    instance = Narabikae::ActiveRecordExtension.new(
      current,
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    assert_equal "b10", instance.set_before(target, challenge: nil)
    assert_equal "b10", current.position
    assert_equal "a0", current.reload.position
  end

  test "set_between returns false when position generation fails" do
    current = Task.create!(position: "a0")
    prev_target = Task.new(position: "invalid")
    next_target = Task.new(position: "invalid")
    instance = Narabikae::ActiveRecordExtension.new(
      current,
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    assert_equal false, instance.set_between(prev_target, next_target, challenge: 5)
    assert_equal "a0", current.position
    assert_equal "a0", current.reload.position
  end

  test "set_between assigns position when generation succeeds" do
    current = Task.create!(position: "a0")
    prev_target = Task.create!(position: "b10abc")
    next_target = Task.create!(position: "b20abc")
    instance = Narabikae::ActiveRecordExtension.new(
      current,
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    assert_equal "b11", instance.set_between(prev_target, next_target, challenge: 5)
    assert_equal "b11", current.position
    assert_equal "a0", current.reload.position
  end

  test "move_to_after returns false when position generation fails" do
    current = Task.create!(position: "a0")
    target = Task.new(position: "invalid")
    instance = Narabikae::ActiveRecordExtension.new(
      current,
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    assert_equal false, instance.move_to_after(target, challenge: 0)
    assert_equal "a0", current.position
  end

  test "move_to_after persists position when generation succeeds" do
    current = Task.create!(position: "a0")
    target = Task.create!(position: "b10abc")
    instance = Narabikae::ActiveRecordExtension.new(
      current,
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    assert_equal true, instance.move_to_after(target, challenge: 0)
    assert_equal "b11", current.reload.position
  end

  test "move_to_before returns false when position generation fails" do
    current = Task.create!(position: "a0")
    target = Task.new(position: "invalid")
    instance = Narabikae::ActiveRecordExtension.new(
      current,
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    assert_equal false, instance.move_to_before(target, challenge: nil)
    assert_equal "a0", current.position
  end

  test "move_to_before persists position when generation succeeds" do
    current = Task.create!(position: "a0")
    target = Task.create!(position: "b10abc")
    instance = Narabikae::ActiveRecordExtension.new(
      current,
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    assert_equal true, instance.move_to_before(target, challenge: nil)
    assert_equal "b10", current.reload.position
  end

  test "move_to_between returns false when position generation fails" do
    current = Task.create!(position: "a0")
    prev_target = Task.new(position: "invalid")
    next_target = Task.new(position: "invalid")
    instance = Narabikae::ActiveRecordExtension.new(
      current,
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    assert_equal false, instance.move_to_between(prev_target, next_target, challenge: 5)
    assert_equal "a0", current.position
  end

  test "move_to_between persists position when generation succeeds" do
    current = Task.create!(position: "a0")
    prev_target = Task.create!(position: "b10abc")
    next_target = Task.create!(position: "b20abc")
    instance = Narabikae::ActiveRecordExtension.new(
      current,
      :position,
      Narabikae::Configuration.new(key_max_size: 10)
    )

    assert_equal true, instance.move_to_between(prev_target, next_target, challenge: 5)
    assert_equal "b11", current.reload.position
  end
end
