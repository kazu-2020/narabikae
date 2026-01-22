require "test_helper"

class NarabikaeOptionStoreTest < ActiveSupport::TestCase
  test "registers option" do
    instance = Narabikae::OptionStore.new
    config = Narabikae::Configuration.new(key_max_size: 10)

    instance.register!(:position, config)

    assert_equal config, instance.store[:position]
  end

  test "raises error when field is already registered" do
    instance = Narabikae::OptionStore.new
    config = Narabikae::Configuration.new(key_max_size: 10)

    instance.register!(:position, config)

    assert_raises(Narabikae::Error) do
      instance.register!(:position, config)
    end
  end

  test "raises error when dependency loop detected" do
    instance = Narabikae::OptionStore.new
    config = Narabikae::Configuration.new(key_max_size: 10, scope: %i[position])

    assert_raises(Narabikae::Error) do
      instance.register!(:position, config)
    end
  end

  test "raises error when scope is already registered as other field" do
    instance = Narabikae::OptionStore.new
    instance.register!(:user_id, Narabikae::Configuration.new(key_max_size: 10))

    assert_raises(Narabikae::Error) do
      instance.register!(:position, Narabikae::Configuration.new(key_max_size: 10, scope: %i[user_id]))
    end
  end
end
