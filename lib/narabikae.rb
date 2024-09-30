require "narabikae/version"

require "narabikae/active_record_extension"
require "narabikae/configuration"
require "narabikae/position"

require "fractional_indexer"

module Narabikae
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

    Option = Struct.new("Option", :size, :scope)

    class_methods do
      def narabikae(column = :position, size:, scope: [])
        column = column.to_sym

        narabikae_column_store[column] = Option.new(size, scope)

        before_create do
          Narabikae::ActiveRecordExtension.new(self, column, Option.new(size)).set_position
        end

        define_method :"move_to_#{column}_after" do |target, **args|
          Narabikae::ActiveRecordExtension.new(self, column, Option.new(size)).move_to_after(target, **args)
        end

        define_method :"move_to_#{column}_before" do |target, **args|
          Narabikae::ActiveRecordExtension.new(self, column, Option.new(size)).move_to_before(target, **args)
        end

        define_method :"move_to_#{column}_between" do |prev_target, next_target, **args|
          Narabikae::ActiveRecordExtension.new(self, column, Option.new(size)).move_to_between(prev_target, next_target, **args)
        end
      end

      private

      def narabikae_column_store
        @_narabikae_column_store ||= {}
      end
    end
  end
end

ActiveSupport.on_load :active_record do |base|
  base.include Narabikae::Extension
end
