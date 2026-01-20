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
      it {
        expect { subject }
          .to change { current.reload.position }
          .from('a0')
          .to(satisfy { |value| value.start_with?('a0V') && value.length == 4 })
      }
    end
  end

  describe 'move_to_<field>_between' do
    subject { current.move_to_position_between(prev_target, next_target) }

    let(:current) { Sample.create } # position: 'a0'

    context 'when prev_target is nil' do
      let(:prev_target) { nil }
      let(:next_target) { Sample.create } # position: 'a1'

      it { is_expected.to eq true }
      it {
        expect { subject }
          .to change { current.reload.position }
          .from('a0')
          .to(satisfy { |value| value.start_with?('a0V') && value.length == 4 })
      }
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


  describe 'set_<field>_after' do
    subject { current.set_position_after(target) }

    let(:current) { Sample.create } # position: 'a0'

    context 'when target is nil' do
      let(:target) { nil }

      it { is_expected.to eq('a1') }
      it { expect { subject }.to change { current.position }.from('a0').to('a1') }
      it { expect { subject }.not_to change { current.reload.position } }
    end
  end

  describe 'set_<field>_before' do
    subject { current.set_position_before(target) }

    let(:current) { Sample.create } # position: 'a0'

    context 'when target is nil' do
      let(:target) { nil }

      it { is_expected.to eq('Zz') }
      it { expect { subject }.to change { current.position }.from('a0').to('Zz') }
      it { expect { subject }.not_to change { current.reload.position } }
    end
  end

  describe 'set_<field>_between' do
    subject { current.set_position_between(prev_target, next_target) }

    let(:current) { Sample.create } # position: 'a0'

    context 'when prev_target is nil' do
      let(:prev_target) { nil }
      let(:next_target) { Sample.create } # position: 'a1'

      it { is_expected.to satisfy { |value| value.start_with?('a0V') && value.length == 4 } }
      it {
        expect { subject }
          .to change { current.position }
          .from('a0')
          .to(satisfy { |value| value.start_with?('a0V') && value.length == 4 })
      }
      it { expect { subject }.not_to change { current.reload.position } }
    end
  end


  describe '<field>_after=' do
    subject { current.position_after = target }

    let(:current) { Sample.create } # position: 'a0'
    let(:target) { Sample.create } # position: 'a1'

    it { is_expected.to eq target }
    it { expect { subject }.to change { current.position }.from('a0').to('a2') }
    it { expect { subject }.not_to change { current.reload.position } }
  end

  describe '<field>_between=' do
    subject { current.position_between = [ prev_target, next_target ] }

    let(:current) { Sample.create } # position: 'a0'
    let(:prev_target) { Sample.create } # position: 'a1'
    let(:next_target) { Sample.create } # position: 'a2'

    it { is_expected.to eq [ prev_target, next_target ] }
    it { expect { subject }.to change { current.position }.from('a0').to('a1V') }
    it { expect { subject }.not_to change { current.reload.position } }
  end
end
