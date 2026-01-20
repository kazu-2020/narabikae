require "test_helper"

class NarabikaeOptionTest < ActiveSupport::TestCase
  test "wraps scope into an array of symbols" do
    option = Narabikae::Option.new(field: :position, key_max_size: 10, scope: :parent_id)

    assert_equal [ :parent_id ], option.scope
  end
end
