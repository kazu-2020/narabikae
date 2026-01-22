module Narabikae
  class ActiveRecordExtension
    attr_reader :record, :config, :position_generator, :field

    def initialize(record, field, config)
      @record = record
      @field = field
      @config = config

      @position_generator = Narabikae::Position.new(record, field, config)
    end

    def auto_set_position?
      # check valid key for fractional_indexer
      # when invalid key, raise FractionalIndexer::Error
      position_generator.indexer.generate_key(prev_key: record.send(field))
      record.send(field).nil? ||
        (config.scope.any? { |s| record.will_save_change_to_attribute?(s) } && !record.will_save_change_to_attribute?(field))
    rescue FractionalIndexer::Error
      true
    end

    def set_position(position = config.default_position)
      new_position =
        case position
        when :first
          position_generator.create_first_position
        when :last
          position_generator.create_last_position
        end

      record.send("#{field}=", new_position)
    end

    def set_after(target, **args)
      new_position = position_generator.find_position_after(target, **args)
      return false if new_position.blank?

      record.send("#{field}=", new_position)
    end

    def set_before(target, **args)
      new_position = position_generator.find_position_before(target, **args)
      return false if new_position.blank?

      record.send("#{field}=", new_position)
    end

    def set_between(prev_target, next_target, **args)
      new_position = position_generator.find_position_between(prev_target, next_target, **args)
      return false if new_position.blank?

      record.send("#{field}=", new_position)
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
  end
end
