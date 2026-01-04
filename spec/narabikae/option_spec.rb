require 'rails_helper'

describe Narabikae::Option do
  describe '#initialize' do
    context 'when scope is a single symbol' do
      subject(:option) do
        described_class.new(field: :position, key_max_size: 10, scope: :parent_id)
      end

      it 'wraps the scope into an array of symbols' do
        expect(option.scope).to eq([:parent_id])
      end
    end
  end
end
