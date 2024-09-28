require 'rails_helper'

describe Narabikae::ActiveRecordExtensions do
  describe 'before_create callback to insert position' do
    context 'call narabikae with default column' do
      before do
        Task.narabikae :position
      end

      it 'inserts a new record with a position' do
        task = Task.create

        expect(task.position).to eq('a0')
      end
    end
  end
end
