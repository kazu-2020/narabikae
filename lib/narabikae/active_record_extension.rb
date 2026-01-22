module Narabikae
  # ActiveRecordExtension handles the actual position updates for ActiveRecord models.
  class ActiveRecordExtension
    attr_reader :record, :config, :position_generator, :field

    # Initializes a new instance of ActiveRecordExtension.
    #
    # @param record [ActiveRecord::Base] The record being positioned.
    # @param field [Symbol] The field name used for ordering.
    # @param config [Narabikae::Configuration] The configuration for this field.
    def initialize(record, field, config)
      @record = record
      @field = field
      @config = config

      @position_generator = Narabikae::Position.new(record, field, config)
    end

    # Checks if the position should be automatically set.
    #
    # @return [Boolean] True if the position should be automatically set.
    def auto_set_position?
      # check valid key for fractional_indexer
      # when invalid key, raise FractionalIndexer::Error
      position_generator.indexer.generate_key(prev_key: record.send(field))
      record.send(field).nil? ||
        (config.scope.any? { |s| record.will_save_change_to_attribute?(s) } && !record.will_save_change_to_attribute?(field))
    rescue FractionalIndexer::Error
      true
    end

    # Sets the position of the record.
    #
    # @param position [Symbol] The position to set (:first or :last).
    # @return [void]
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

    # Sets the position of the record after the target.
    #
    # @param target [ActiveRecord::Base, String, nil] The target record or key.
    # @param args [Hash] Additional arguments for the position generator.
    # @return [String, Boolean] The new position key, or false if generation fails.
    def set_after(target, **args)
      new_position = position_generator.find_position_after(target, **args)
      return false if new_position.blank?

      record.send("#{field}=", new_position)
    end

    # Sets the position of the record before the target.
    #
    # @param target [ActiveRecord::Base, String, nil] The target record or key.
    # @param args [Hash] Additional arguments for the position generator.
    # @return [String, Boolean] The new position key, or false if generation fails.
    def set_before(target, **args)
      new_position = position_generator.find_position_before(target, **args)
      return false if new_position.blank?

      record.send("#{field}=", new_position)
    end

    # Sets the position of the record between two targets.
    #
    # @param prev_target [ActiveRecord::Base, String, nil] The previous target record or key.
    # @param next_target [ActiveRecord::Base, String, nil] The next target record or key.
    # @param args [Hash] Additional arguments for the position generator.
    # @return [String, Boolean] The new position key, or false if generation fails.
    def set_between(prev_target, next_target, **args)
      new_position = position_generator.find_position_between(prev_target, next_target, **args)
      return false if new_position.blank?

      record.send("#{field}=", new_position)
    end

    # Moves the record to a position after the target and saves it.
    #
    # @param target [ActiveRecord::Base, String, nil] The target record or key.
    # @param args [Hash] Additional arguments.
    # @return [Boolean] True if successful.
    def move_to_after(target, **args)
      return false unless set_after(target, **args)

      record.save
    end

    # Moves the record to a position before the target and saves it.
    #
    # @param target [ActiveRecord::Base, String, nil] The target record or key.
    # @param args [Hash] Additional arguments.
    # @return [Boolean] True if successful.
    def move_to_before(target, **args)
      return false unless set_before(target, **args)

      record.save
    end

    # Moves the record to a position between two targets and saves it.
    #
    # @param prev_target [ActiveRecord::Base, String, nil] The previous target.
    # @param next_target [ActiveRecord::Base, String, nil] The next target.
    # @param args [Hash] Additional arguments.
    # @return [Boolean] True if successful.
    def move_to_between(prev_target, next_target, **args)
      return false unless set_between(prev_target, next_target, **args)

      record.save
    end
  end
end
