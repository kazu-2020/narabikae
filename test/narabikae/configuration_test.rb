require "test_helper"

class NarabikaeConfigurationTest < ActiveSupport::TestCase
  teardown do
    # Reset global configuration to standard defaults after each test
    Narabikae.config.key_max_size = 200
    Narabikae.config.scope = []
    Narabikae.config.default_position = :last
    Narabikae.config.base = 62
  end

  test "uses global configuration defaults" do
    Narabikae.config.key_max_size = 123
    Narabikae.config.base = 10

    klass = Class.new(ActiveRecord::Base) do
      self.table_name = "tasks"
      narabikae
    end

    config = klass.send(:narabikae_option_store).store[:position]

    assert_equal 123, config.key_max_size
    assert_equal 10, config.base
    assert_equal [], config.scope
    assert_equal :last, config.default_position
  end

  test "local overrides take precedence over global defaults" do
    Narabikae.config.key_max_size = 200
    Narabikae.config.base = 62

    klass = Class.new(ActiveRecord::Base) do
      self.table_name = "tasks"
      narabikae :rank, size: 50, base: 94, scope: [ :user_id ], default_position: :first
    end

    config = klass.send(:narabikae_option_store).store[:rank]

    assert_equal 50, config.key_max_size
    assert_equal 94, config.base
    assert_equal [ :user_id ], config.scope
    assert_equal :first, config.default_position
  end

  test "raises ArgumentError if size is missing (via global config)" do
    Narabikae.config.key_max_size = nil

    assert_raises(ArgumentError, "size is required") do
      Class.new(ActiveRecord::Base) do
        self.table_name = "tasks"
        narabikae
      end
    end
  end

  test "wraps scope into an array of symbols" do
    config = Narabikae::Configuration.new(key_max_size: 10, scope: :parent_id)
    assert_equal [ :parent_id ], config.scope
  end

  test "configuration validation" do
    config = Narabikae::Configuration.new(key_max_size: 10, base: 10)
    assert_equal 10, config.base

    assert_raises(ArgumentError) { Narabikae::Configuration.new(key_max_size: 10, base: 99) }
    assert_raises(ArgumentError) { Narabikae::Configuration.new(key_max_size: 10, default_position: :invalid) }
  end
end
