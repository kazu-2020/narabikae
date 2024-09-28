module Narabikae
  class ActiveRecordHandler
    # Initializes a new instance of the ActiveRecordHandler class.
    #
    # @param record [Object] The ActiveRecord object.
    # @param column [Symbol] The column symbol.
    def initialize(record, column)
      @record  = record
      @column  = column
    end

    # Generates a new key for the last position
    #
    # @return [String] The newly generated key for the last position.
    def create_last_position
      FractionalIndexer.generate_key(prev_key: current_last_position)
    end

    private

    attr_reader :record, :column

    def current_last_position
      model.maximum(column)
    end

    def model
      record.class.base_class
    end
  end
end
