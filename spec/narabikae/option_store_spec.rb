require 'rails_helper'

describe Narabikae::OptionStore do
  describe "#register!" do
    subject { instance.register!(field, option) }

    let(:instance) { described_class.new }

    context 'when field is already registered' do
      let(:field) { :position }
      let(:option) { Narabikae::Option.new(field: :position, key_max_size: 10) }

      before { instance.register!(field, option) }

      it { expect { subject }.to raise_error(Narabikae::Error).with_message("the field `position` is already registered") }
    end

    context 'when dependency loop detected' do
      let(:field) { :position }
      let(:option) { Narabikae::Option.new(field: :position, key_max_size: 10, scope: %i[position]) }

      it { expect { subject }.to raise_error(Narabikae::Error).with_message("dependency loop detected: [:position]") }
    end

    context 'when scope is already registered as other field' do
      let(:field) { :position }
      let(:option) { Narabikae::Option.new(field: :position, key_max_size: 10, scope: %i[user_id]) }

      before do
        instance.register!(
          :user_id,
          Narabikae::Option.new(field: :user_id, key_max_size: 10)
        )
      end

      it { expect { subject }.to raise_error(Narabikae::Error).with_message("the scope `[:user_id]` is already registered as other field") }
    end

    context 'when field is not registered' do
      let(:field) { :position }
      let(:option) { Narabikae::Option.new(field: :position, key_max_size: 10) }

      it { is_expected.to eq option }
    end
  end
end
