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

  test "find_position_after finds neighbor and generates midpoint without retry" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )
    target = Task.new(position: "a1")

    Task.create!(position: "a2")

    key = position.find_position_after(target)
    assert key > target.position
    assert key < "a2"
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

  test "find_position_before finds neighbor and generates midpoint without retry" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 10)
    )
    target = Task.new(position: "a1")

    Task.create!(position: "a0")

    key = position.find_position_before(target)
    assert key < target.position
    assert key > "a0"
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

  test "find_position_before with neighbor maintains order" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    target = Task.new(position: "a01")

    Task.create!(position: "a0")

    key = position.find_position_before(target)
    assert key < target.position
    assert key > "a0"
  end

  test "find_position_after with neighbor maintains order" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    target = Task.new(position: "aZ")

    Task.create!(position: "aa")

    key = position.find_position_after(target)
    assert key > target.position
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

  # --- Neighbor-aware optimization tests ---

  test "find_next_position_key returns nearest position after given key" do
    Task.create!(position: "a0")
    Task.create!(position: "a5")
    Task.create!(position: "b10")

    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_equal "a5", position.send(:find_next_position_key, "a0")
    assert_equal "b10", position.send(:find_next_position_key, "a5")
    assert_nil position.send(:find_next_position_key, "b10")
  end

  test "find_prev_position_key returns nearest position before given key" do
    Task.create!(position: "a0")
    Task.create!(position: "a5")
    Task.create!(position: "b10")

    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_nil position.send(:find_prev_position_key, "a0")
    assert_equal "a0", position.send(:find_prev_position_key, "a5")
    assert_equal "a5", position.send(:find_prev_position_key, "b10")
  end

  test "find_next_position_key respects scope" do
    Task.create!(user_id: 1, position: "a0")
    Task.create!(user_id: 1, position: "a5")
    Task.create!(user_id: 2, position: "a2")

    position = Narabikae::Position.new(
      Task.new(user_id: 1),
      Narabikae::Option.new(field: :position, key_max_size: 30, scope: %i[user_id])
    )

    # Should find "a5" (user 1), not "a2" (user 2)
    assert_equal "a5", position.send(:find_next_position_key, "a0")
  end

  test "find_prev_position_key respects scope" do
    Task.create!(user_id: 1, position: "a5")
    Task.create!(user_id: 2, position: "a3")

    position = Narabikae::Position.new(
      Task.new(user_id: 1),
      Narabikae::Option.new(field: :position, key_max_size: 30, scope: %i[user_id])
    )

    # Should return nil (no user 1 records before "a5"), not "a3" (user 2)
    assert_nil position.send(:find_prev_position_key, "a5")
  end

  test "find_next_position_key returns nil for nil key" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_nil position.send(:find_next_position_key, nil)
  end

  test "find_prev_position_key returns nil for nil key" do
    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )

    assert_nil position.send(:find_prev_position_key, nil)
  end

  test "find_position_after with many records between generates correct midpoint" do
    # Simulates a filtered view: user only sees target, but many records exist after it
    Task.create!(position: "a0")
    Task.create!(position: "a1")
    Task.create!(position: "a2")
    Task.create!(position: "a3")

    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    target = Task.new(position: "a0")

    # Should find "a1" as next neighbor and generate midpoint between "a0" and "a1"
    key = position.find_position_after(target)
    assert key > "a0"
    assert key < "a1"
  end

  test "find_position_before with many records before generates correct midpoint" do
    Task.create!(position: "a0")
    Task.create!(position: "a1")
    Task.create!(position: "a2")
    Task.create!(position: "a3")

    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    target = Task.new(position: "a3")

    # Should find "a2" as prev neighbor and generate midpoint between "a2" and "a3"
    key = position.find_position_before(target)
    assert key > "a2"
    assert key < "a3"
  end

  test "find_position_after at end of list appends after last" do
    Task.create!(position: "a0")
    Task.create!(position: "a5")

    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    target = Task.new(position: "a5")

    # No next neighbor, should generate key after "a5"
    key = position.find_position_after(target)
    assert key > "a5"
  end

  test "find_position_before at start of list prepends before first" do
    Task.create!(position: "a5")
    Task.create!(position: "a9")

    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 30)
    )
    target = Task.new(position: "a5")

    # No prev neighbor, should generate key before "a5"
    key = position.find_position_before(target)
    assert key < "a5"
  end

  # --- Ordering correctness in dense lists ---

  test "find_position_after lands immediately after target in dense list" do
    # Create a base list and insert many records after the same target,
    # simulating a user repeatedly adding tasks after the same position.
    keys = FractionalIndexer.generate_keys(count: 10)
    keys.each { |k| Task.create!(position: k) }

    target = Task.find_by(position: keys[5])

    # Build a dense cluster after the target (20 insertions)
    20.times do
      pos = Narabikae::Position.new(
        Task.new,
        Narabikae::Option.new(field: :position, key_max_size: 200)
      )
      key = pos.find_position_after(target)
      Task.create!(position: key)
    end

    # Now verify: find_position_after(target) should produce a key
    # that is LESS than the immediate next neighbor
    actual_next = Task.where("position > ?", target.position).order(:position).first

    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 200)
    )
    key = position.find_position_after(target)

    assert key > target.position, "Generated key should be after target"
    assert key < actual_next.position,
      "Generated key (#{key}) should be immediately after target, " \
      "but it exceeds the next neighbor (#{actual_next.position}). " \
      "This means the task would appear in the wrong position."
  end

  test "find_position_before lands immediately before target in dense list" do
    keys = FractionalIndexer.generate_keys(count: 10)
    keys.each { |k| Task.create!(position: k) }

    target = Task.find_by(position: keys[5])

    # Build a dense cluster before the target (20 insertions)
    20.times do
      pos = Narabikae::Position.new(
        Task.new,
        Narabikae::Option.new(field: :position, key_max_size: 200)
      )
      key = pos.find_position_before(target)
      Task.create!(position: key)
    end

    # Now verify: find_position_before(target) should produce a key
    # that is GREATER than the immediate previous neighbor
    actual_prev = Task.where("position < ?", target.position).order(position: :desc).first

    position = Narabikae::Position.new(
      Task.new,
      Narabikae::Option.new(field: :position, key_max_size: 200)
    )
    key = position.find_position_before(target)

    assert key < target.position, "Generated key should be before target"
    assert key > actual_prev.position,
      "Generated key (#{key}) should be immediately before target, " \
      "but it precedes the previous neighbor (#{actual_prev.position}). " \
      "This means the task would appear in the wrong position."
  end

  test "repeated find_position_after always lands immediately after target" do
    keys = FractionalIndexer.generate_keys(count: 10)
    keys.each { |k| Task.create!(position: k) }

    target = Task.find_by(position: keys[5])

    # Simulate 50 drag-to-reposition operations, each inserting the result
    50.times do |i|
      actual_next = Task.where("position > ?", target.position).order(:position).first

      position = Narabikae::Position.new(
        Task.new,
        Narabikae::Option.new(field: :position, key_max_size: 200)
      )
      key = position.find_position_after(target)

      assert key > target.position,
        "Iteration #{i}: key should be after target"
      assert key < actual_next.position,
        "Iteration #{i}: key (#{key}) exceeded next neighbor (#{actual_next.position}). " \
        "Task would appear #{Task.where('position > ? AND position < ?', target.position, key).count} " \
        "places away from intended position."

      Task.create!(position: key)
    end
  end
end
