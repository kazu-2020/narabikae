require "test_helper"

class NarabikaePositionTest < ActiveSupport::TestCase
  test "create_last_position returns a0 when table is empty" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_equal "a0", position.create_last_position
  end

  test "create_last_position returns next key when table has records" do
    Task.create!(position: "a0")
    Task.create!(position: "c112")
    Task.create!(position: "W112a")

    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_equal "c113", position.create_last_position
  end

  test "create_last_position respects scope" do
    Task.create!(user_id: 1, position: "a5")
    Task.create!(user_id: 2, position: "a7")

    position = Narabikae::Position.new(
      Task.new(user_id: 1),
      Narabikae::Option.new(field: :position, key_max_size: 30, scope: %i[user_id])
    )

    assert_equal "a6", position.create_last_position
  end

  test "create_first_position returns a0 when table is empty" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_equal "a0", position.create_first_position
  end

  test "create_first_position returns previous key when table has records" do
    Task.create!(position: "a0")
    Task.create!(position: "b0")
    Task.create!(position: "c0")

    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_equal "Zz", position.create_first_position
  end

  test "create_first_position respects scope" do
    Task.create!(user_id: 1, position: "a0")
    Task.create!(user_id: 2, position: "a7")

    position = Narabikae::Position.new(
      Task.new(user_id: 1),
      Narabikae::Option.new(field: :position, key_max_size: 30, scope: %i[user_id])
    )

    assert_equal "Zz", position.create_first_position
  end

  test "find_position_after accepts target record" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    target = Task.new(position: "a1")

    assert_equal "a2", position.find_position_after(target)
  end

  test "find_position_after accepts position key string" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_equal "a2", position.find_position_after("a1")
  end

  test "find_position_after returns nil for invalid target" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    target = Task.new(position: "invalid")

    assert_nil position.find_position_after(target)
  end

  test "find_position_after handles largest positive integer" do
    target = Task.create!(position: "z" + "z" * 26)
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_equal "z" + "z" * 26 + "V", position.find_position_after(target)
  end

  test "find_position_after uses last position when target is nil" do
    Task.create!(position: "b10")
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_equal "b11", position.find_position_after(nil)
  end

  test "find_position_after retries when first generated key is invalid" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )
    target = Task.new(position: "a1")

    position.expects(:random_fractional).returns("C")
    Task.create!(position: "a2")

    key = position.find_position_after(target)
    assert_equal "a1VC", key
    assert key > target.position
  end

  test "find_position_after returns nil when all generated keys are invalid" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 0)
    )
    target = Task.new(position: "a1")

    Task.create!(position: "a2")

    assert_nil position.find_position_after(target)
  end

  test "find_position_after returns nil when challenge is nil or 0" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 0)
    )
    target = Task.new(position: "a1")

    assert_nil position.find_position_after(target, challenge: 0)
  end

  test "find_position_after respects scope" do
    position = Narabikae::Position.new(
      Task.new(user_id: 1),
      Narabikae::Option.new(field: :position, key_max_size: 30, scope: %i[user_id])
    )
    target = Task.new(position: "a0", user_id: 1)

    Task.create!(user_id: 2, position: "a1")

    assert_equal "a1", position.find_position_after(target)
  end

  test "find_position_after raises on target model mismatch" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    error = assert_raises(Narabikae::Error) do
      position.find_position_after(Course.new)
    end

    assert_includes error.message, "table"
    assert_includes error.message, "tasks"
    assert_includes error.message, "courses"
  end

  test "find_position_after raises on invalid target type" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    error = assert_raises(Narabikae::Error) do
      position.find_position_after(1)
    end

    assert_includes error.message, "position key"
  end

  test "find_position_after raises on scope mismatch" do
    position = Narabikae::Position.new(
      Task.new(user_id: 1),
      Narabikae::Option.new(field: :position, key_max_size: 30, scope: %i[user_id])
    )

    error = assert_raises(Narabikae::Error) do
      position.find_position_after(Task.new(position: "a0", user_id: 2))
    end

    assert_includes error.message, "scope"
    assert_includes error.message, "user_id"
  end

  test "find_position_before accepts target record" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    target = Task.new(position: "a0")

    assert_equal "Zz", position.find_position_before(target)
  end

  test "find_position_before returns nil for invalid target" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    target = Task.new(position: "invalid")

    assert_nil position.find_position_before(target)
  end

  test "find_position_before handles smallest positive integer" do
    target = Task.create!(position: "A" + "0" * 26)
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_nil position.find_position_before(target)
  end

  test "find_position_before handles one greater than smallest positive integer" do
    target = Task.create!(position: "A" + "0" * 25 + "1")
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_equal "A" + "0" * 26 + "V", position.find_position_before(target)
  end

  test "find_position_before uses first position when target is nil" do
    Task.create!(position: "b10")
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_equal "b0z", position.find_position_before(nil)
  end

  test "find_position_before retries when first generated key is invalid" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )
    target = Task.new(position: "a1")

    position.expects(:random_fractional).returns("Z")
    Task.create!(position: "a0")

    key = position.find_position_before(target)
    assert_equal "a0VZ", key
    assert key < target.position
  end

  test "find_position_before returns nil when all generated keys are invalid" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 0)
    )
    target = Task.new(position: "a1")

    Task.create!(position: "a0")

    assert_nil position.find_position_before(target)
  end

  test "find_position_before returns nil when challenge is nil or 0" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 0)
    )
    target = Task.new(position: "a1")

    assert_nil position.find_position_before(target, challenge: 0)
  end

  test "find_position_before respects scope" do
    position = Narabikae::Position.new(
      Task.new(user_id: 1),
      Narabikae::Option.new(field: :position, key_max_size: 30, scope: %i[user_id])
    )
    target = Task.new(position: "a1", user_id: 1)

    Task.create!(user_id: 2, position: "a0")

    assert_equal "a0", position.find_position_before(target)
  end

  test "find_position_between delegates to find_position_before when prev is nil" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    next_target = Task.new(position: "a0")

    position.expects(:find_position_before).with(next_target, challenge: 10).returns("Zz")

    assert_equal "Zz", position.find_position_between(nil, next_target)
  end

  test "find_position_between delegates to find_position_after when next is nil" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    prev_target = Task.new(position: "a0")

    position.expects(:find_position_after).with(prev_target, challenge: 10).returns("a1")

    assert_equal "a1", position.find_position_between(prev_target, nil)
  end

  test "find_position_between works when both targets are present" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_equal "a0V", position.find_position_between(Task.new(position: "a1"), Task.new(position: "a0"))
  end

  test "find_position_between treats nil prev position as before" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    next_target = Task.new(position: "a0")

    assert_equal "Zz", position.find_position_between(Task.new(position: nil), next_target)
  end

  test "find_position_between treats nil next position as after" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    prev_target = Task.new(position: "a0")

    assert_equal "a1", position.find_position_between(prev_target, Task.new(position: nil))
  end

  test "find_position_between returns nil for invalid targets" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_nil position.find_position_between(Task.new(position: "invalid"), Task.new(position: "invalid"))
  end

  test "find_position_between retries when first generated key is invalid" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )
    prev_target = Task.new(position: "a0")
    next_target = Task.new(position: "a2")

    position.expects(:random_fractional).returns("t")
    Task.create!(position: "a1")

    key = position.find_position_between(prev_target, next_target)
    assert_equal "a1Vt", key
    assert key > prev_target.position
    assert key < next_target.position
  end

  test "find_position_between returns nil when all generated keys are invalid" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 0)
    )

    assert_nil position.find_position_between(Task.new(position: "a0"), Task.new(position: "a2"))
  end

  test "find_position_between returns nil when challenge is nil or 0" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 0)
    )
    prev_target = Task.new(position: "a0")
    next_target = Task.new(position: "a2")

    Task.create!(position: "a1")

    assert_nil position.find_position_between(prev_target, next_target, challenge: 0)
  end

  test "current_first_position returns nil when table is empty" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_nil position.send(:current_first_position)
  end

  test "current_first_position returns minimum position" do
    Task.create!(position: "a0")
    Task.create!(position: "Z91111")

    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_equal "Z91111", position.send(:current_first_position)
  end

  test "current_first_position respects scope" do
    Task.create!(user_id: 1, position: "a9")
    Task.create!(user_id: 2, position: "a1")

    position = Narabikae::Position.new(
      Task.new(user_id: 1),
      Narabikae::Option.new(field: :position, key_max_size: 30, scope: %i[user_id])
    )

    assert_equal "a9", position.send(:current_first_position)
  end

  test "current_last_position returns nil when table is empty" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_nil position.send(:current_last_position)
  end

  test "current_last_position returns maximum position" do
    Task.create!(position: "a0")
    Task.create!(position: "Z91111")

    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_equal "a0", position.send(:current_last_position)
  end

  test "current_last_position respects scope" do
    Task.create!(user_id: 1, position: "a9")
    Task.create!(user_id: 1, position: "a8")
    Task.create!(user_id: 2, position: "a1")

    position = Narabikae::Position.new(
      Task.new(user_id: 1),
      Narabikae::Option.new(field: :position, key_max_size: 30, scope: %i[user_id])
    )

    assert_equal "a9", position.send(:current_last_position)
  end

  test "capable? returns true when key is shorter than max" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )

    assert_equal true, position.send(:capable?, "a0" + "a" * 7)
  end

  test "capable? returns true when key equals max" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )

    assert_equal true, position.send(:capable?, "a0" + "a" * 8)
  end

  test "capable? returns false when key exceeds max" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )

    assert_equal false, position.send(:capable?, "a0" + "a" * 9)
  end

  test "model_scope returns all records when scope is empty" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )

    assert_equal Task.where({}), position.send(:model_scope)
  end

  test "model_scope raises when scope includes invalid value" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10, scope: [ :invalid ])
    )

    assert_raises(NoMethodError) { position.send(:model_scope) }
  end

  test "model_scope uses record attributes for scope" do
    position = Narabikae::Position.new(
      Task.new(id: 1, name: "hello"),
      Narabikae::Option.new(field: :position, key_max_size: 10, scope: %i[id name])
    )

    assert_equal Task.where(id: 1, name: "hello"), position.send(:model_scope)
  end

  test "uniq? returns false when key already in use" do
    Task.create!(position: "a1")

    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )

    assert_equal false, position.send(:uniq?, "a1")
  end

  test "uniq? returns true when key not in use" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )

    assert_equal true, position.send(:uniq?, "a1")
  end

  test "uniq? respects scope" do
    Task.create!(user_id: 1, position: "a0")
    Task.create!(user_id: 2, position: "a1")

    position = Narabikae::Position.new(
      Task.new(user_id: 1),
      Narabikae::Option.new(field: :position, key_max_size: 10, scope: %i[user_id])
    )

    assert_equal true, position.send(:uniq?, "a1")
  end

  test "valid? returns false for nil key" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )

    assert_equal false, position.send(:valid?, nil)
  end

  test "valid? returns false for empty key" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )

    assert_equal false, position.send(:valid?, "")
  end

  test "valid? returns false when key exceeds max size" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )

    assert_equal false, position.send(:valid?, "a0" + "a" * 9)
  end

  test "valid? returns false when key is not unique" do
    Task.create!(position: "a1")

    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )

    assert_equal false, position.send(:valid?, "a1")
  end

  test "valid? returns true for valid key" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )

    assert_equal true, position.send(:valid?, "a0")
  end

  test "find_position_between uses minmax when prev and next are reversed" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    prev_target = Task.new(position: "a1")
    next_target = Task.new(position: "a0")

    key = position.find_position_between(prev_target, next_target)
    assert key.start_with?("a0")
    assert key > "a0"
    assert key < "a1"

    assert_not prev_target.position < key && key < next_target.position
  end

  test "find_position_before retry maintains order" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    target = Task.new(position: "a01")

    position.expects(:random_fractional).returns("Z")
    Task.create!(position: "a0")

    key = position.find_position_before(target)
    assert key < target.position
    assert_equal "a00VZ", key
  end

  test "find_position_after retry maintains order" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    target = Task.new(position: "aZ")

    position.expects(:random_fractional).returns("Z")
    Task.create!(position: "aa")

    key = position.find_position_after(target)
    assert key > target.position
    assert_equal "aZVZ", key
    assert key < "aa"
  end

  test "find_position_between maintains order with minmax" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    prev_target = Task.new(position: "a1")
    next_target = Task.new(position: "a0")
    Task.create!(position: "a0V")

    key = position.find_position_between(prev_target, next_target)

    assert key.start_with?("a0")
    assert key > "a0"
    assert key < "a1"
  end
end
