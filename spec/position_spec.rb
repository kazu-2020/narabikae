require 'rails_helper'

describe Narabikae::Position do
  describe '#create_last_position' do
    subject { described_class.new(Task, :position, {}).create_last_position }

    context 'DB table is empty' do
      it { is_expected.to eq('a0') }
    end

    context 'DB table has records' do
      before do
        Task.insert({ position: 'a0' })
        Task.insert({ position: 'c112' })
        Task.insert({ position: 'W112a' })
      end

      it { is_expected.to eq('c113') }
    end
  end

  describe '#find_position_after' do
    subject {
      described_class
        .new(Task, :position, Struct.new(:size).new(30))
        .find_position_after(target)
    }

    context 'when target has valid position' do
      let(:target) { Task.build(position: 'a1') }

      it { is_expected.to eq('a2') }
    end

    context 'when target has invalid position' do
      let(:target) { Task.build(position: 'invalid') }

      it { is_expected.to eq(nil) }
    end

    context 'when target is the largest positive integer' do
      let(:target) { Task.create(position: 'z' + 'z' * 26) }

      it { is_expected.to eq('z' + 'z' * 26 + 'V') }
    end

    context 'when target is nil' do
      let(:target) { nil }

      before do
        Task.create!(position: 'b10')
      end

      it 'try to generate key from the last position' do
        expect(subject).to eq('b11')
      end
    end

    describe 'try to generate key until the challenge count reaches the limit' do
      subject {
        described_class
          .new(Task, :position, Struct.new(:size).new(10))
          .find_position_after(target)
      }

      context 'when first generated key is invalid' do
        let(:target) { Task.build(position: 'a1') }

        before do
          Task.create!(position: 'a2')
        end

        it { is_expected.to match(/^a2.$/) }
      end

      context 'when all generated keys are invalid' do
        # size is 0 so that the key is invalid
        let(:stub) {
          described_class.new(Task, :position, Struct.new(:size).new(0))
        }
        let(:target) { Task.build(position: 'a1') }

        before do
          allow(described_class).to receive(:new).and_return(stub)

          Task.create!(position: 'a2')
          Task.create!(position: 'a2a')
        end

        it { is_expected.to eq(nil) }
      end

      context 'when challenge is nil or 0' do
        subject {
          described_class
            .new(Task, :position, Struct.new(:size).new(10))
            .find_position_after(target, challenge: 0)
        }

        let(:stub) {
          described_class.new(Task, :position, Struct.new(:size).new(0))
        }
        let(:target) { Task.build(position: 'a1') }

        before do
          allow(described_class).to receive(:new).and_return(stub)
          allow(stub).to receive(:random_fractional).and_return('V')
        end

        it { is_expected.to eq(nil) }

        it 'does not try to generate key' do
          subject
          expect(stub).not_to have_received(:random_fractional)
        end
      end
    end
  end

  describe 'private #capable?' do
    subject {
      described_class
        .new(Task, :position, Struct.new(:size).new(10))
        .send(:capable?, key)
    }

    context 'when key is less than' do
      let(:key) { 'a0' + 'a' * 7 }

      it { is_expected.to eq(true) }
    end

    context 'when key is equal to' do
      let(:key) { 'a0' + 'a' * 8 }

      it { is_expected.to eq(true) }
    end

    context 'when key is greater than' do
      let(:key) { 'a0' + 'a' * 9 }

      it { is_expected.to eq(false) }
    end
  end

  describe 'private #uniq?' do
    subject { described_class.new(Task, :position, {}).send(:uniq?, key) }

    let(:task) { Task.new }
    let(:key) { 'a1' }

    context 'when key is already in use' do
      before do
        Task.create!(position: key)
      end

      it { is_expected.to eq(false) }
    end

    context 'when key is not in use' do
      it { is_expected.to eq(true) }
    end
  end

  describe 'private #valid?' do
    subject {
      described_class
        .new(Task, :position, Struct.new(:size).new(10))
        .send(:valid?, key)
    }

    context 'when key is nil' do
      let(:key) { nil }
      it { is_expected.to eq(false) }
    end

    context 'when key is empty' do
      let(:key) { '' }
      it { is_expected.to eq(false) }
    end

    context 'when #capable? return false' do
      let(:key) { 'a0' + 'a' * 9 }

      it { is_expected.to eq(false) }
    end

    context 'when #uniq? return false' do
      let(:key) { 'a1' }

      before do
        Task.create!(position: key)
      end

      it { is_expected.to eq(false) }
    end

    context 'when key is valid' do
      let(:key) { 'a0' }

      it { is_expected.to eq(true) }
    end
  end
end
