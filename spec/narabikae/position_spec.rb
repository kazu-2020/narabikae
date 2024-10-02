require 'rails_helper'

describe Narabikae::Position do
  describe '#create_last_position' do
    subject { position.create_last_position }

    let(:position) {
      described_class.new(
        Task.new,
        Narabikae::Option.new(
          field: :position,
          key_max_size: 30
        )
      )
    }

    context 'DB table is empty' do
      it { is_expected.to eq('a0') }
    end

    context 'DB table has records' do
      before do
        Task.create({ position: 'a0' })
        Task.create({ position: 'c112' })
        Task.create({ position: 'W112a' })
      end

      it { is_expected.to eq('c113') }
    end

    context 'when option has scope' do
      let(:position) {
        described_class.new(
          Task.new(user_id: 1),
          Narabikae::Option.new(
            field: :position,
            key_max_size: 30,
            scope: %i[user_id]
          )
        )
      }

      before do
        Task.create!(user_id: 1, position: 'a5')
        Task.create!(user_id: 2, position: 'a7')
      end

      it { is_expected.to eq('a6') }
    end
  end

  describe '#find_position_after' do
    subject { position.find_position_after(target) }

    let(:position) {
      described_class.new(
        Task.new,
        Narabikae::Option.new(
          field: :position,
          key_max_size: 30
        )
      )
    }

    context 'when target has valid position' do
      let(:target) { Task.new(position: 'a1') }

      it { is_expected.to eq('a2') }
    end

    context 'when target has invalid position' do
      let(:target) { Task.new(position: 'invalid') }

      it { is_expected.to be_nil }
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
      let(:position) {
        described_class.new(
          Task.new,
          Narabikae::Option.new(
            field: :position,
            key_max_size: 10
          )
        )
      }

      context 'when first generated key is invalid' do
        let(:target) { Task.new(position: 'a1') }

        before do
          Task.create!(position: 'a2')
        end

        it { is_expected.to match(/^a2.$/) }
      end

      context 'when all generated keys are invalid' do
        # size is 0 so that the key is invalid
        let(:position) {
          described_class.new(
            Task.new,
            Narabikae::Option.new(
              field: :position,
              key_max_size: 0
            )
          )
        }
        let(:target) { Task.new(position: 'a1') }

        before do
          Task.create!(position: 'a2')
        end

        it { is_expected.to eq(nil) }
      end

      context 'when challenge is nil or 0' do
        subject {
          position.find_position_after(target, challenge: 0)
        }

        let(:position) {
          described_class.new(
            Task.new,
            Narabikae::Option.new(
              field: :position,
              key_max_size: 0
            )
          )
        }

        let(:target) { Task.new(position: 'a1') }

        before do
          allow(position).to receive(:random_fractional)
        end

        it { is_expected.to be_nil }

        it 'does not try to generate key' do
          subject
          expect(position).not_to have_received(:random_fractional)
        end
      end
    end

    describe 'option has scope' do
      let(:position) {
        described_class.new(
          Task.new(user_id: 1),
          Narabikae::Option.new(
            field: :position,
            key_max_size: 30,
            scope: %i[user_id]
          )
        )
      }
      let(:target) { Task.new(position: 'a0') }

      before do
        Task.create!(user_id: 2, position: 'a1')
      end

      it { is_expected.to eq('a1') }
    end
  end

  describe '#find_position_before' do
    subject { position.find_position_before(target) }

    let(:position) {
      described_class.new(
        Task.new,
        Narabikae::Option.new(
          field: :position,
          key_max_size: 30
        )
      )
    }

    context 'when target has valid position' do
      let(:target) { Task.new(position: 'a0') }

      it { is_expected.to eq('Zz') }
    end

    context 'when target has invalid position' do
      let(:target) { Task.new(position: 'invalid') }

      it { is_expected.to be_nil }
    end

    # edge case: this situation is typically unlikely to occur.
    # see: https://github.com/kazu-2020/fractional_indexer/blob/82a1f0c680af6f4918694ad217113e4c161b6833/lib/fractional_indexer.rb#L94-L98
    context 'when target is the smallest positive integer' do
      let(:target) { Task.create(position: 'A' + '0' * 26) }

      it { is_expected.to be_nil }
    end

    context 'when target is one grater than the smallest positive integer' do
      let(:target) { Task.create(position: 'A' + '0' * 25 + '1') }

      it { is_expected.to eq('A' + '0' * 26 + 'V') }
    end

    context 'when target is nil' do
      let(:target) { nil }

      before do
        Task.create!(position: 'b10')
      end

      it 'try to generate key from the first position' do
        expect(subject).to eq('b0z')
      end
    end

    describe 'try to generate key until the challenge count reaches the limit' do
      let(:position) {
        described_class.new(
          Task.new,
          Narabikae::Option.new(
            field: :position,
            key_max_size: 10
          )
        )
      }

      context 'when first generated key is invalid' do
        let(:target) { Task.new(position: 'a1') }

        before do
          Task.create!(position: 'a0')
        end

        it { is_expected.to match(/^a0.$/) }
      end

      context 'when all generated keys are invalid' do
        # size is 0 so that the key is invalid
        let(:position) {
          described_class.new(
            Task.new,
            Narabikae::Option.new(
              field: :position,
              key_max_size: 0
            )
          )
        }
        let(:target) { Task.new(position: 'a1') }

        before do
          Task.create!(position: 'a0')
        end

        it { is_expected.to be_nil }
      end

      context 'when challenge is nil or 0' do
        subject { position.find_position_before(target, challenge: 0) }

        let(:position) {
          described_class.new(
            Task.new,
            Narabikae::Option.new(
              field: :position,
              key_max_size: 0
            )
          )
        }
        let(:target) { Task.new(position: 'a1') }

        before do
          allow(position).to receive(:random_fractional)
        end

        it { is_expected.to eq(nil) }

        it 'does not try to generate key' do
          subject
          expect(position).not_to have_received(:random_fractional)
        end
      end
    end

    context 'when option has scope' do
      let(:position) {
        described_class.new(
          Task.new(user_id: 1),
          Narabikae::Option.new(
            field: :position,
            key_max_size: 30,
            scope: %i[user_id]
          )
        )
      }
      let(:target) { Task.new(position: 'a1') }

      before do
        Task.create!(user_id: 2, position: 'a0')
      end

      it { is_expected.to eq('a0') }
    end
  end

  describe '#find_position_between' do
    subject {
      position.find_position_between(prev_target, next_target)
    }

    context 'when prev_target is nil' do
      let(:position) {
        described_class.new(
          Task.new,
          Narabikae::Option.new(
            field: :position,
            key_max_size: 30
          )
        )
      }
      let(:prev_target) { nil }
      let(:next_target) { Task.new(position: 'a0') }

      before do
        allow(position).to receive(:find_position_before).and_call_original
      end

      it { is_expected.to eq('Zz') }

      it 'calls #find_position_before' do
        subject

        expect(position).to have_received(:find_position_before).with(next_target)
      end
    end

    context 'when next_target is nil' do
      let(:position) {
        described_class.new(
          Task.new,
          Narabikae::Option.new(
            field: :position,
            key_max_size: 30
          )
        )
      }
      let(:prev_target) { Task.new(position: 'a0') }
      let(:next_target) { nil }

      before do
        allow(position).to receive(:find_position_after).and_call_original
      end

      it { is_expected.to eq('a1') }

      it 'calls #find_position_after' do
        subject

        expect(position).to have_received(:find_position_after).with(prev_target)
      end
    end

    context 'when prev_target and next_target is presence' do
      let(:position) {
        described_class.new(
          Task.new,
          Narabikae::Option.new(
            field: :position,
            key_max_size: 30
          )
        )
      }
      let(:prev_target) { Task.new(position: 'a1') }
      let(:next_target) { Task.new(position: 'a0') }


      it { is_expected.to eq('a0V') }
    end

    context 'when prev_target has invalid position and next_target has invalid position ' do
      let(:position) {
        described_class.new(
          Task.new,
          Narabikae::Option.new(
            field: :position,
            key_max_size: 30
          )
        )
      }
      let(:prev_target) { Task.new(position: 'invalid') }
      let(:next_target) { Task.new(position: 'invalid') }

      it { is_expected.to be_nil }
    end

    describe 'try to generate key until the challenge count reaches the limit' do
      context 'when first generated key is invalid' do
        let(:position) {
          described_class.new(
            Task.new,
            Narabikae::Option.new(
              field: :position,
              key_max_size: 10
            )
          )
        }
        let(:prev_target) { Task.new(position: 'a0') }
        let(:next_target) { Task.new(position: 'a2') }

        before do
          Task.create(position: 'a1')
        end

        it { is_expected.to match(/^a1.$/) }
      end

      context 'when all generated keys are invalid' do
        # size is 0 so that the key is invalid
        let(:position) {
          described_class.new(
            Task.new,
            Narabikae::Option.new(
              field: :position,
              key_max_size: 0
            )
          )
        }
        let(:prev_target) { Task.new(position: 'a0') }
        let(:next_target) { Task.new(position: 'a2') }

        it { is_expected.to eq(nil) }
      end

      context 'when challenge is nil or 0' do
        subject {
          position
            .find_position_between(prev_target, next_target, challenge: 0)
        }

        let(:position) {
          described_class.new(
            Task.new,
            Narabikae::Option.new(
              field: :position,
              key_max_size: 0
            )
          )
        }
        let(:prev_target) { Task.new(position: 'a0') }
        let(:next_target) { Task.new(position: 'a2') }

        before do
          Task.create(position: 'a1')
          allow(position).to receive(:random_fractional)
        end

        it { is_expected.to eq(nil) }

        it 'does not retry to generate key' do
          subject
          expect(position).not_to have_received(:random_fractional)
        end
      end
    end
  end

  describe 'private #current_first_position' do
    subject { position.send(:current_first_position) }

    let(:position) {
      described_class.new(
        Task.new,
        Narabikae::Option.new(
          field: :position,
          key_max_size: 30
        )
      )
    }

    context 'when DB table is empty' do
      it { is_expected.to be_nil }
    end

    context 'when DB table has records' do
      before do
        Task.create!(position: 'a0')
        Task.create!(position: 'Z91111')
      end

      it { is_expected.to eq('Z91111') }
    end

    context 'when option has scope' do
      let(:position) {
        described_class.new(
          Task.new(user_id: 1),
          Narabikae::Option.new(
            field: :position,
            key_max_size: 30,
            scope: %i[user_id]
          )
        )
      }

      before do
        Task.create!(user_id: 1, position: 'a9')
        Task.create!(user_id: 2, position: 'a1')
      end

      it { is_expected.to eq('a9') }
    end
  end

  describe 'private #current_last_position' do
    subject { position.send(:current_last_position) }

    let(:position) {
      described_class.new(
        Task.new,
        Narabikae::Option.new(
          field: :position,
          key_max_size: 30
        )
      )
    }

    context 'when DB table is empty' do
      it { is_expected.to be_nil }
    end

    context 'when DB table has records' do
      before do
        Task.create!(position: 'a0')
        Task.create!(position: 'Z91111')
      end

      it { is_expected.to eq('a0') }
    end

    context 'when option has scope' do
      let(:position) {
        described_class.new(
          Task.new(user_id: 1),
          Narabikae::Option.new(
            field: :position,
            key_max_size: 30,
            scope: %i[user_id]
          )
        )
      }

      before do
        Task.create!(user_id: 1, position: 'a9')
        Task.create!(user_id: 1, position: 'a8')
        Task.create!(user_id: 2, position: 'a1')
      end

      it { is_expected.to eq('a9') }
    end
  end


  describe 'private #capable?' do
    subject { position.send(:capable?, key) }

    let(:position) {
      described_class.new(
        Task.new,
        Narabikae::Option.new(
          field: :position,
          key_max_size: 10
        )
      )
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

  describe 'private #model_scope' do
    subject { position.send(:model_scope) }

    context "option's scope is []" do
      let(:position) {
        described_class.new(
          Task.new,
          Narabikae::Option.new(
            field: :position,
            key_max_size: 10
          )
        )
      }

      it { is_expected.to eq Task.where({}) }
    end

    context "option's scope include invalid value" do
      let(:position) {
        described_class.new(
          Task.new,
          Narabikae::Option.new(
            field: :position,
            key_max_size: 10,
            scope: [ :invalid ]
          )
        )
      }

      it { expect { subject }.to raise_error(NoMethodError).with_message("undefined method `invalid' for an instance of Task") }
    end

    context 'option has valid scope' do
      let(:position) {
        described_class.new(
          Task.new(id: 1, name: 'hello'),
          Narabikae::Option.new(
            field: :position,
            key_max_size: 10,
            scope: %i[id name]
          )
        )
      }

      it { is_expected.to eq Task.where(id: 1, name: 'hello') }
    end
  end

  describe 'private #uniq?' do
    subject { position.send(:uniq?, key) }

    let(:position) {
      described_class.new(
        Task.new,
        Narabikae::Option.new(
          field: :position,
          key_max_size: 10
        )
      )
    }
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

    context 'when option has scope' do
      let(:position) {
        described_class.new(
          Task.new(user_id: 1),
          Narabikae::Option.new(
            field: :position,
            key_max_size: 10,
            scope: %i[user_id]
          )
        )
      }
      let(:key) { 'a1' }

      before do
        Task.create!(user_id: 1, position: 'a0')
        Task.create!(user_id: 2, position: key)
      end

      it { is_expected.to eq(true) }
    end
  end

  describe 'private #valid?' do
    subject { position.send(:valid?, key) }

    let(:position) {
      described_class.new(
        Task.new,
        Narabikae::Option.new(
          field: :position,
          key_max_size: 10
        )
      )
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
