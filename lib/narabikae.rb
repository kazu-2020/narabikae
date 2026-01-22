require "narabikae/version"

require "narabikae/active_record_extension"
require "narabikae/configuration"
require "narabikae/option_store"
require "narabikae/position"

require "narabikae/fractional_indexer"
require "active_support"
require "active_support/ordered_options"
require "active_record"

# Narabikae is a Ruby gem that provides fractional indexing for ActiveRecord models.
module Narabikae
  mattr_accessor :config, default: Narabikae::Configuration.new

  # Configures the global defaults for Narabikae.
  #
  # @yield [config] The global configuration object.
  # @return [void]
  def self.configure
    yield config
  end

  class Error < StandardError; end

  # Extension module to be included in ActiveRecord::Base.
  module Extension
    extend ActiveSupport::Concern

    class_methods do
      # Enables fractional indexing for the model.
      #
      # @param field [Symbol] The field name used for ordering (default: :position).
      # @param options [Hash] Configuration overrides.
      # @option options [Integer] :size The maximum size of the fractional index key (alias for :key_max_size).
      # @option options [Integer] :key_max_size The maximum size of the fractional index key.
      # @option options [Array<Symbol>, Symbol] :scope The scope columns for ordering.
      # @option options [Symbol] :default_position The default position (:first or :last).
      # @option options [Integer] :base The base for fractional indexing (10, 62, or 94).
      # @return [void]
      def narabikae(field = :position, **options)
        field = field.to_sym

        if options.key?(:size)
          options[:key_max_size] = options.delete(:size)
        end

        config = narabikae_option_store.register!(
                          field,
                          Narabikae::Configuration.new(**Narabikae.config, **options)
                        )

        before_save -> {
          extension = Narabikae::ActiveRecordExtension.new(self, field, config)
          extension.set_position(config.default_position) if extension.auto_set_position?
        }

        define_method :"set_#{field}_after" do |target = nil, **args|
          extension = Narabikae::ActiveRecordExtension.new(self, field, config)
          extension.set_after(target, **args)
        end
        alias_method :"#{field}_after=", :"set_#{field}_after"

        define_method :"set_#{field}_before" do |target = nil, **args|
          extension = Narabikae::ActiveRecordExtension.new(self, field, config)
          extension.set_before(target, **args)
        end
        alias_method :"#{field}_before=", :"set_#{field}_before"

        define_method :"set_#{field}_between" do |prev_target = nil, next_target = nil, **args|
          extension = Narabikae::ActiveRecordExtension.new(self, field, config)
          extension.set_between(prev_target, next_target, **args)
        end
        define_method :"#{field}_between=" do |value|
          prev_target = nil
          next_target = nil

          case value
          when Array
            prev_target, next_target = value
          when Hash
            payload = value.with_indifferent_access
            prev_target = payload[:prev_target] || payload[:prev]
            next_target = payload[:next_target] || payload[:next]
          else
            prev_target = value
          end

          extension = Narabikae::ActiveRecordExtension.new(self, field, config)
          extension.set_between(prev_target, next_target)
        end

        define_method :"move_to_#{field}_after" do |target = nil, **args|
          extension = Narabikae::ActiveRecordExtension.new(self, field, config)
          extension.move_to_after(target, **args)
        end

        define_method :"move_to_#{field}_before" do |target = nil, **args|
          extension = Narabikae::ActiveRecordExtension.new(self, field, config)
          extension.move_to_before(target, **args)
        end

        define_method :"move_to_#{field}_between" do |prev_target = nil, next_target = nil, **args|
          extension = Narabikae::ActiveRecordExtension.new(self, field, config)
          extension.move_to_between(prev_target, next_target, **args)
        end
      end

      private

      # Returns the option store for the model.
      # @return [Narabikae::OptionStore]
      def narabikae_option_store
        @_narabikae_option_store ||= Narabikae::OptionStore.new
      end
    end
  end
end

ActiveSupport.on_load :active_record do |base|
  base.include Narabikae::Extension
end
