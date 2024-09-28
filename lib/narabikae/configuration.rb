module Narabikae
  class Configuration
    # Sets the base value for FractionalIndexer configuration.
    #
    # @param int [Integer] The base value can be 10, 62, 94, with the default being 94.
    # @return [void]
    def base=(int)
      FractionalIndexer.configure do |config|
        config.base = "base_#{int}".to_sym
      end
    end

    # @return [Array] The string of digits configured for the FractionalIndexer.
    # @see https://github.com/kazu-2020/fractional_indexer?tab=readme-ov-file#configure
    def digits
      FractionalIndexer.configuration.digits
    end
  end
end
