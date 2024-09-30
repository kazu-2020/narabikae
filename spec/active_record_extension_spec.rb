require 'rails_helper'

describe Narabikae::ActiveRecordExtension do
  describe "#auto_set_position?" do
    subject { instance.auto_set_position? }

    context 'when record has invalid key' do
      let(:instance) {
        described_class.new(
          Task.build(position: 'invalid'),
          :position,
          Struct.new(:size, :scope).new(10, [])
        )
      }

      it { is_expected.to eq true }
    end

    context "when record don't have scope" do
      let(:instance) {
        described_class.new(
          Task.create(position: 'a0'),
          :position,
          Struct.new(:size, :scope).new(10, [])
        )
      }

      it { is_expected.to eq false }
    end

    context 'There is scope for record, but no change' do
      let(:instance) {
        described_class.new(
          Task.create(position: 'a0'),
          :position,
          Struct.new(:size, :scope).new(10, %i[user_id])
        )
      }

      it { is_expected.to eq false }
    end

    context 'There is scope for record, and there is change' do
      let(:instance) {
        described_class.new(
          record,
          :position,
          Struct.new(:size, :scope).new(10, %i[user_id])
        )
      }
      let(:record) { Task.create(position: 'a0') }

      before do
        record.user_id = 1
      end


      context "record won't save change to column" do
        it { is_expected.to eq true }
      end

      context 'record will save change to column' do
        before do
          record.position = 'a1'
        end

        it { is_expected.to eq false }
      end
    end
  end

  describe "#set_position" do
    subject { instance.set_position }

    let(:record) { Task.new }
    let(:instance) {
      described_class.new(
        record,
        :position,
        Struct.new(:size, :scope).new(10, [])
      )
    }

    it { expect { subject }.to change { record.position }.from(nil).to('a0') }
  end

  describe "#move_to_after" do
    subject { instance.move_to_after(target, challenge: 0) }

    context 'when the new position generation fails ' do
      let(:instance) {
        described_class.new(
          current,
          :position,
          Struct.new(:size, :scope).new(10, [])
        )
      }
      let(:current) { Task.create(position: 'a0') }
      let(:target) { Task.build(position: 'invalid') }


      it { expect(subject).to eq false }
      it { expect { subject }.not_to change { current.position } }
    end

    context 'when the new position generation succeeds' do
      let(:instance) {
        described_class.new(
          current,
          :position,
          Struct.new(:size, :scope).new(10, [])
        )
      }
      let(:current) { Task.create(position: 'a0') }
      let(:target) { Task.create(position: 'b10abc') }

      it { expect(subject).to eq true }
      it { expect { subject }.to change { current.position }.from('a0').to('b11') }
    end
  end

  describe "#move_to_before" do
    subject { instance.move_to_before(target, challenge: nil) }

    context 'when the new position generation fails ' do
      let(:instance) {
        described_class.new(
          current,
          :position,
          Struct.new(:size, :scope).new(10, [])
        )
      }
      let(:current) { Task.create(position: 'a0') }
      let(:target) { Task.build(position: 'invalid') }

      it { expect(subject).to eq false }
      it { expect { subject }.not_to change { current.position } }
    end

    context 'when the new position generation succeeds' do
      let(:instance) {
        described_class.new(
          current,
          :position,
          Struct.new(:size, :scope).new(10, [])
        )
      }
      let(:current) { Task.create(position: 'a0') }
      let(:target) { Task.create(position: 'b10abc') }

      it { expect(subject).to eq true }
      it { expect { subject }.to change { current.position }.from('a0').to('b10') }
    end
  end

  describe "#move_to_between" do
    subject { instance.move_to_between(prev_target, next_target, challenge: 5) }

    context 'when the new position generation fails ' do
      let(:instance) {
        described_class.new(
          current,
          :position,
          Struct.new(:size, :scope).new(10, [])
        )
      }
      let(:current) { Task.create(position: 'a0') }
      let(:prev_target) { Task.build(position: 'invalid') }
      let(:next_target) { Task.build(position: 'invalid') }

      it { expect(subject).to eq false }
      it { expect { subject }.not_to change { current.position } }
    end

    context 'when the new position generation succeeds' do
      let(:instance) {
        described_class.new(
          current,
          :position,
          Struct.new(:size, :scope).new(10, [])
        )
      }
      let(:current) { Task.create(position: 'a0') }
      let(:prev_target) { Task.create(position: 'b10abc') }
      let(:next_target) { Task.create(position: 'b20abc') }

      it { expect(subject).to eq true }
      it { expect { subject }.to change { current.position }.from('a0').to('b11') }
    end
  end
end
