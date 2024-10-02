require 'rails_helper'

describe 'move_to_<field>_xxx' do
  before(:all) do
    load Rails.root.join('app/models/sample.rb')
    Sample.narabikae :position, size: 100
    Sample.narabikae :order, size: 100
  end

  describe 'move_to_<field>_after' do
    subject { current.move_to_position_after(target) }

    let!(:current) { Sample.create } # position: 'a0'

    context 'when target is nil' do
      let(:target) { nil }

      it { is_expected.to eq true }
      it { expect { subject }.to change { current.reload.position }.from('a0').to('a1') }
    end

    context 'when target is not nil' do
      let(:target) { Sample.create } # position: 'a1'

      it { is_expected.to eq true }
      it { expect { subject }.to change { current.reload.position }.from('a0').to('a2') }
    end
  end

  describe 'move_to_<field>_before' do
    subject { current.move_to_position_before(target) }

    let(:current) { Sample.create } # position: 'a0'

    context 'when target is nil' do
      let(:target) { nil }

      it { is_expected.to eq true }
      it { expect { subject }.to change { current.reload.position }.from('a0').to('Zz') }
    end

    context 'when target is not nil' do
      let(:target) { Sample.create } # position: 'a1'

      it { is_expected.to eq true }
      it { expect { subject }.to change { current.reload.position }.from('a0').to(/^a0.$/) }
    end
  end

  describe 'move_to_<field>_between' do
    subject { current.move_to_position_between(prev_target, next_target) }

    let(:current) { Sample.create } # position: 'a0'

    context 'when prev_target is nil' do
      let(:prev_target) { nil }
      let(:next_target) { Sample.create } # position: 'a1'

      it { is_expected.to eq true }
      it { expect { subject }.to change { current.reload.position }.from('a0').to(/^a0.$/) }
    end

    context 'when next_target is nil' do
      let(:prev_target) { Sample.create } # position: 'a1'
      let(:next_target) { nil }

      it { is_expected.to eq true }
      it { expect { subject }.to change { current.reload.position }.from('a0').to('a2') }
    end

    context 'when prev_target and next_target are not nil' do
      let(:prev_target) { Sample.create } # position: 'a1'
      let(:next_target) { Sample.create } # position: 'a2'

      it { is_expected.to eq true }
      it { expect { subject }.to change { current.reload.position }.from('a0').to('a1V') }
    end
  end
end
