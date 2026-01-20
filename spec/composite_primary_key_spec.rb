require 'rails_helper'

describe 'Composite primary key models' do
  before(:all) do
    load Rails.root.join('app/models/composite_task.rb')
    CompositeTask.narabikae :position, size: 100, scope: %i[account_id]
  end

  describe 'auto-positioning' do
    it 'assigns positions within the composite key scope' do
      first = CompositeTask.create!(account_id: 1, task_id: 1)
      second = CompositeTask.create!(account_id: 1, task_id: 2)
      other_scope = CompositeTask.create!(account_id: 2, task_id: 1)

      expect(first.position).to eq('a0')
      expect(second.position).to eq('a1')
      expect(other_scope.position).to eq('a0')
    end
  end

  describe 'composite position inputs' do
    context 'when setting position after a position key' do
      let!(:current) { CompositeTask.create!(account_id: 1, task_id: 1) }
      let!(:target) { CompositeTask.create!(account_id: 1, task_id: 2) }

      it 'accepts position keys' do
        expect(current.set_position_after(target.position)).to eq('a2')
        expect(current.position).to eq('a2')
        expect(current.reload.position).to eq('a0')
      end
    end

    context 'when moving after a record' do
      let!(:current) { CompositeTask.create!(account_id: 1, task_id: 1) }
      let!(:target) { CompositeTask.create!(account_id: 1, task_id: 2) }

      it 'persists changes using records' do
        expect(current.move_to_position_after(target, challenge: 0)).to eq(true)
        expect(current.reload.position).to eq('a2')
      end
    end

    context 'when using the between setter with position keys' do
      let!(:current) { CompositeTask.create!(account_id: 1, task_id: 1) }
      let!(:prev_target) { CompositeTask.create!(account_id: 1, task_id: 2) }
      let!(:next_target) { CompositeTask.create!(account_id: 1, task_id: 3) }

      it 'accepts a hash payload of position keys' do
        current.position_between = { prev: prev_target.position, next: next_target.position }

        expect(current.position).to eq('a1V')
        expect(current.reload.position).to eq('a0')
      end
    end
  end
end
