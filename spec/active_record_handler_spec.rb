require 'rails_helper'

describe Narabikae::ActiveRecordHandler do
  describe '#create_last_position' do
    subject { described_class.new(task, :position).create_last_position }

    context 'DB table is empty' do
      let(:task) { Task.new }

      it { is_expected.to eq('a0') }
    end

    context 'DB table has records' do
      let(:task) { Task.new }

      before do
        Task.insert({ position: 'a0' })
        Task.insert({ position: 'c112' })
        Task.insert({ position: 'W112a' })
      end

      it { is_expected.to eq('c113') }
    end
  end
end
