require_relative "./active_record_handler"

module Narabikae
  module ActiveRecordExtensions
    extend ActiveSupport::Concern

    class_methods do
      def narabikae(column = :position, **options)
        column = column.to_sym

        narabikae_column_store[column] = []

        before_create do
          self.send("#{column}=", Narabikae::ActiveRecordHandler.new(self, column).create_last_position)
        end
      end

      private

      def narabikae_column_store
        @_narabikae_column_store ||= {}
      end
    end
  end
end
