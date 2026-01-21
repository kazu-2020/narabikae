require "test_helper"

class NarabikaeOptionStoreTest < ActiveSupport::TestCase
  test "raises when field is already registered" do
    instance = Narabikae::OptionStore.new
    option = Narabikae::Option.new(field: :position, key_max_size: 10)

    instance.register!(:position, option)

    error = assert_raises(Narabikae::Error) do
      instance.register!(:position, option)
    end

    assert_equal "the field `position` is already registered", error.message
  end

  test "raises when dependency loop detected" do
    instance = Narabikae::OptionStore.new
    option = Narabikae::Option.new(field: :position, key_max_size: 10, scope: %i[position])

    error = assert_raises(Narabikae::Error) do
      instance.register!(:position, option)
    end

    assert_equal "dependency loop detected: [:position]", error.message
  end

  test "raises when scope is already registered as another field" do
    instance = Narabikae::OptionStore.new

    instance.register!(
      :user_id,
      Narabikae::Option.new(field: :user_id, key_max_size: 10)
    )

    error = assert_raises(Narabikae::Error) do
      instance.register!(:position, Narabikae::Option.new(field: :position, key_max_size: 10, scope: %i[user_id]))
    end

    assert_equal "the scope `[:user_id]` is already registered as other field", error.message
  end

  test "registers option when field is not registered" do
    instance = Narabikae::OptionStore.new
    option = Narabikae::Option.new(field: :position, key_max_size: 10)

    assert_equal option, instance.register!(:position, option)
  end
end
