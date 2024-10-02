require "narabikae/version"

require "narabikae/active_record_extension"
require "narabikae/configuration"
require "narabikae/option"
require "narabikae/option_store"
require "narabikae/position"

require "fractional_indexer"
require "active_support"
require "active_record"

module Narabikae
  class Error < StandardError; end

  @configuration = Narabikae::Configuration.new

  def self.configure
    yield configuration if block_given?

    configuration
  end

  def self.configuration
    @configuration
  end

  module Extension
    extend ActiveSupport::Concern

    class_methods do
      def narabikae(field = :position, size:, scope: [])
        option = narabikae_option_store.register!(
                   field.to_sym,
                   Narabikae::Option.new(field: field, key_max_size: size, scope: scope)
                 )

        before_create do
          extension = Narabikae::ActiveRecordExtension.new(self, option)
          extension.set_position
        end

        before_update do
          extension = Narabikae::ActiveRecordExtension.new(self, option)
          extension.set_position if extension.auto_set_position?
        end

        define_method :"move_to_#{field}_after" do |target = nil, **args|
          extension = Narabikae::ActiveRecordExtension.new(self, option)
          extension.move_to_after(target, **args)
        end

        define_method :"move_to_#{field}_before" do |target = nil, **args|
          extension = Narabikae::ActiveRecordExtension.new(self, option)
          extension.move_to_before(target, **args)
        end

        define_method :"move_to_#{field}_between" do |prev_target = nil, next_target = nil, **args|
          extension = Narabikae::ActiveRecordExtension.new(self, option)
          extension.move_to_between(prev_target, next_target, **args)
        end
      end

      private

      def narabikae_option_store
        @_narabikae_option_store ||= Narabikae::OptionStore.new
      end
    end
  end
end

ActiveSupport.on_load :active_record do |base|
  base.include Narabikae::Extension
end
