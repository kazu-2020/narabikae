require 'rails_helper'

describe 'Composite primary key models' do
  before(:all) do
    load Rails.root.join('app/models/composite_task.rb')
    CompositeTask.narabikae :position, size: 100, scope: %i[account_id]
  end

  describe 'auto-positioning and indexes' do
    it 'assigns positions within the composite key scope' do
      first = CompositeTask.create!(account_id: 1, task_id: 1)
      second = CompositeTask.create!(account_id: 1, task_id: 2)
      other_scope = CompositeTask.create!(account_id: 2, task_id: 1)

      expect(first.position).to eq('a0')
      expect(second.position).to eq('a1')
      expect(other_scope.position).to eq('a0')
      expect(second.position_index).to eq(1)
      expect(other_scope.position_index).to eq(0)
    end
  end

  describe 'composite id inputs' do
    context 'when setting position after an id array' do
      let!(:current) { CompositeTask.create!(account_id: 1, task_id: 1) }
      let!(:target) { CompositeTask.create!(account_id: 1, task_id: 2) }

      it 'accepts composite ids' do
        expect(current.set_position_after(target.id)).to eq('a2')
        expect(current.position).to eq('a2')
        expect(current.reload.position).to eq('a0')
      end
    end

    context 'when moving after an id array' do
      let!(:current) { CompositeTask.create!(account_id: 1, task_id: 1) }
      let!(:target) { CompositeTask.create!(account_id: 1, task_id: 2) }

      it 'persists changes using composite ids' do
        expect(current.move_to_position_after(target.id, challenge: 0)).to eq(true)
        expect(current.reload.position).to eq('a2')
      end
    end

    context 'when using the between setter with composite ids' do
      let!(:current) { CompositeTask.create!(account_id: 1, task_id: 1) }
      let!(:prev_target) { CompositeTask.create!(account_id: 1, task_id: 2) }
      let!(:next_target) { CompositeTask.create!(account_id: 1, task_id: 3) }

      it 'accepts a hash payload of id arrays' do
        current.position_between = { prev: prev_target.id, next: next_target.id }

        expect(current.position).to eq('a1V')
        expect(current.reload.position).to eq('a0')
      end
    end
  end

  describe 'reorder_position' do
    it 'reorders within composite key scope groups' do
      CompositeTask.create!(account_id: 1, task_id: 1, name: 'b')
      CompositeTask.create!(account_id: 1, task_id: 2, name: 'a')
      CompositeTask.create!(account_id: 2, task_id: 1, name: 'c')

      updated = CompositeTask.reorder_position(:name)

      expect(updated).to eq(3)
      expect(CompositeTask.where(account_id: 1).order(:position).pluck(:name)).to eq(%w[a b])
      expect(CompositeTask.where(account_id: 2).order(:position).pluck(:name)).to eq(['c'])
    end
  end
end
