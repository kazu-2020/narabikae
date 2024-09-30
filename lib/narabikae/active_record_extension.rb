module Narabikae
  class ActiveRecordExtension
    def initialize(record, column, option)
      @record = record
      @column = column
      @option = option

      @position_generator = Narabikae::Position.new(record, column, option)
    end

    def set_position
      record.send("#{column}=", position_generator.create_last_position)
    end

    def move_to_after(target)
      new_position = position_generator.find_position_after(target)
      return false if new_position.blank?

      record.send("#{column}=", new_position)
      record.save
    end

    def move_to_before(target)
      new_position = position_generator.find_position_before(target)
      return false if new_position.blank?

      record.send("#{column}=", new_position)
      record.save
    end

    def move_to_between(prev_target, next_target)
      new_position = position_generator.find_position_between(prev_target, next_target)
      return false if new_position.blank?

      record.send("#{column}=", new_position)
      record.save
    end

    private

    attr_reader :record, :column, :option, :position_generator
  end
end
