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
      def narabikae(field = :position, size:, scope: [], default_position: :last)
        option = narabikae_option_store.register!(
                   field.to_sym,
                   Narabikae::Option.new(field: field, key_max_size: size, scope: scope, default_position: default_position)
                 )

        before_save -> {
          extension = Narabikae::ActiveRecordExtension.new(self, option)
          extension.set_position(option.default_position) if extension.auto_set_position?
        }

        define_method :"set_#{field}_after" do |target = nil, **args|
          extension = Narabikae::ActiveRecordExtension.new(self, option)
          extension.set_after(target, **args)
        end
        alias_method :"#{field}_after=", :"set_#{field}_after"

        define_method :"set_#{field}_before" do |target = nil, **args|
          extension = Narabikae::ActiveRecordExtension.new(self, option)
          extension.set_before(target, **args)
        end
        alias_method :"#{field}_before=", :"set_#{field}_before"

        define_method :"set_#{field}_between" do |prev_target = nil, next_target = nil, **args|
          extension = Narabikae::ActiveRecordExtension.new(self, option)
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

          extension = Narabikae::ActiveRecordExtension.new(self, option)
          extension.set_between(prev_target, next_target)
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

        define_singleton_method :"reorder_#{field}" do |*order_args, **order_kwargs|
          order_args << order_kwargs if order_kwargs.any?
          order_args = [ field ] if order_args.empty?

          scope_columns = option.scope
          relation = all
          scope_values =
            if scope_columns.empty?
              [ [] ]
            else
              relation.distinct.pluck(*scope_columns).map do |values|
                scope_columns.length == 1 ? [ values ] : values
              end
            end

          updated_count = 0

          scope_values.each do |values|
            relation.transaction do
              scoped = scope_columns.empty? ? relation : relation.where(scope_columns.zip(values).to_h)

              # Add _ prefix to all positions so on update they don't conflict with unique indexes
              manager = Arel::UpdateManager.new
              manager.table(relation.arel_table)
              manager.set([ [ relation.arel_table[field], Arel::Nodes::Concat.new(Arel::Nodes.build_quoted("_"), relation.arel_table[field]) ] ])
              manager.where(scope_columns.zip(values).map { |(column, value)| relation.arel_table[column].eq(value) }.inject(:and)) unless scope_columns.empty?
              relation.connection.update(manager)

              prev_key = nil
              scoped.order(*order_args).in_batches do |records|
                next if records.empty?

                keys = FractionalIndexer.generate_keys(prev_key: prev_key, count: records.size)
                records.each.with_index do |record, index|
                  record.update_columns(field => keys[index])
                end

                prev_key = keys.last
                updated_count += records.size
              end
            end
          end

          updated_count
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
