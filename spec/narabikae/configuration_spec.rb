require 'rails_helper'

describe Narabikae::Configuration do
  describe '#base=' do
    context 'when setting the valid base value' do
      before do
        Narabikae.configure do |config|
          config.base = 10
        end
      end

      it 'sets the base value' do
        expect(Narabikae.configuration.digits).to eq(FractionalIndexer::Configuration::DIGITS_LIST[:base_10])
      end
    end

    context 'when setting the invalid base value' do
      before do
        Narabikae.configure do |config|
          config.base = nil
        end
      end

      it 'sets the default base value' do
        expect(Narabikae.configuration.digits).to eq(FractionalIndexer::Configuration::DIGITS_LIST[:base_62])
      end
    end
  end
end
