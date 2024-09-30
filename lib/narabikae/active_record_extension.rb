module Narabikae
  class ActiveRecordExtension
    def initialize(record, column, option)
      @record = record
      @column = column
      @option = option

      @position_generator = Narabikae::Position.new(record, column, option)
    end

    def auto_set_position?
      # check valid key for fractional_indexer
      # when invalid key, raise FractionalIndexer::Error
      FractionalIndexer.generate_key(prev_key: record.send(column))
      !!option.scope&.any? { |scope| record.will_save_change_to_attribute?(scope) } && !record.will_save_change_to_attribute?(column)
    rescue FractionalIndexer::Error
      true
    end

    def set_position
      record.send("#{column}=", position_generator.create_last_position)
    end

    def move_to_after(target, **args)
      new_position = position_generator.find_position_after(target, **args)
      return false if new_position.blank?

      record.send("#{column}=", new_position)
      record.save
    end

    def move_to_before(target, **args)
      new_position = position_generator.find_position_before(target, **args)
      return false if new_position.blank?

      record.send("#{column}=", new_position)
      record.save
    end

    def move_to_between(prev_target, next_target, **args)
      new_position = position_generator.find_position_between(prev_target, next_target, **args)
      return false if new_position.blank?

      record.send("#{column}=", new_position)
      record.save
    end

    private

    attr_reader :record, :column, :option, :position_generator
  end
end
