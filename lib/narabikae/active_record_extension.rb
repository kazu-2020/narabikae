module Narabikae
  class ActiveRecordExtension
    def initialize(record, option)
      @record = record
      @option = option

      @position_generator = Narabikae::Position.new(record, option)
    end

    def auto_set_position?
      # check valid key for fractional_indexer
      # when invalid key, raise FractionalIndexer::Error
      FractionalIndexer.generate_key(prev_key: record.send(option.field))
      option.scope.any? { |s| record.will_save_change_to_attribute?(s) } && !record.will_save_change_to_attribute?(option.field)
    rescue FractionalIndexer::Error
      true
    end

    def set_position(position = option.default_position)
      new_position =
        case position
        when :first
          position_generator.create_first_position
        when :last
          position_generator.create_last_position
        end

      record.send("#{option.field}=", new_position)
    end

    def set_after(target, **args)
      new_position = position_generator.find_position_after(target, **args)
      return false if new_position.blank?

      record.send("#{option.field}=", new_position)
      true
    end

    def set_before(target, **args)
      new_position = position_generator.find_position_before(target, **args)
      return false if new_position.blank?

      record.send("#{option.field}=", new_position)
      true
    end

    def set_between(prev_target, next_target, **args)
      new_position = position_generator.find_position_between(prev_target, next_target, **args)
      return false if new_position.blank?

      record.send("#{option.field}=", new_position)
      true
    end

    def set_index(index)
      key = position_generator.find_position_at(index)
      return false if key.blank?

      record.send("#{option.field}=", key)
      true
    end

    def move_to_after(target, **args)
      return false unless set_after(target, **args)

      record.save
    end

    def move_to_before(target, **args)
      return false unless set_before(target, **args)

      record.save
    end

    def move_to_between(prev_target, next_target, **args)
      return false unless set_between(prev_target, next_target, **args)

      record.save
    end

    def move_to_index(index)
      return false unless set_index(index)

      record.save
    end

    private

    attr_reader :record, :option, :position_generator
  end
end
