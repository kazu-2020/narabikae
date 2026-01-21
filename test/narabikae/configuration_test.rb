require "test_helper"

class NarabikaeConfigurationTest < ActiveSupport::TestCase
  teardown do
    Narabikae.configure { |config| config.base = 62 }
  end

  test "sets base value when valid" do
    Narabikae.configure do |config|
      config.base = 10
    end

    assert_equal FractionalIndexer::Configuration::DIGITS_LIST[:base_10], Narabikae.configuration.digits
  end

  test "defaults to base_62 when invalid" do
    Narabikae.configure do |config|
      config.base = nil
    end

    assert_equal FractionalIndexer::Configuration::DIGITS_LIST[:base_62], Narabikae.configuration.digits
  end
end
