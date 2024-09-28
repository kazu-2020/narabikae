require "narabikae/version"
require "narabikae/railtie"

require "fractional_indexer"

module Narabikae
  autoload :ActiveRecordExtensions, "narabikae/active_record_extensions"
  autoload :Configuration,          "narabikae/configuration"

  @configuration = Configuration.new

  def self.configure
    yield configuration if block_given?

    configuration
  end

  def self.configuration
    @configuration
  end
end

ActiveSupport.on_load :active_record do |base|
  base.include Narabikae::ActiveRecordExtensions
end
