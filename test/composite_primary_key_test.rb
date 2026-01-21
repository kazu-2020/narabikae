require "test_helper"

class CompositePrimaryKeyTest < ActiveSupport::TestCase
  setup do
    load Rails.root.join("app/models/composite_task.rb")
    CompositeTask.narabikae :position, size: 100, scope: %i[account_id]
  end

  teardown do
    Object.send(:remove_const, "CompositeTask") if Object.const_defined?("CompositeTask")
  end

  test "assigns positions within the composite key scope" do
    first = CompositeTask.create!(account_id: 1, task_id: 1)
    second = CompositeTask.create!(account_id: 1, task_id: 2)
    other_scope = CompositeTask.create!(account_id: 2, task_id: 1)

    assert_equal "a0", first.position
    assert_equal "a1", second.position
    assert_equal "a0", other_scope.position
  end

  test "accepts position keys when setting after" do
    current = CompositeTask.create!(account_id: 1, task_id: 1)
    target = CompositeTask.create!(account_id: 1, task_id: 2)

    assert_equal "a2", current.set_position_after(target.position)
    assert_equal "a2", current.position
    assert_equal "a0", current.reload.position
  end

  test "persists changes when moving after a record" do
    current = CompositeTask.create!(account_id: 1, task_id: 1)
    target = CompositeTask.create!(account_id: 1, task_id: 2)

    assert_equal true, current.move_to_position_after(target, challenge: 0)
    assert_equal "a2", current.reload.position
  end

  test "accepts a hash payload of position keys in between setter" do
    current = CompositeTask.create!(account_id: 1, task_id: 1)
    prev_target = CompositeTask.create!(account_id: 1, task_id: 2)
    next_target = CompositeTask.create!(account_id: 1, task_id: 3)

    current.position_between = { prev: prev_target.position, next: next_target.position }

    assert_equal "a1V", current.position
    assert_equal "a0", current.reload.position
  end
end
