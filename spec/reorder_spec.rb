require 'rails_helper'

describe 'reorder_<field>' do
  context 'without scope' do
    before do
      stub_const('ReorderSample', Class.new(ApplicationRecord) do
        self.table_name = 'samples'
      end)
      ReorderSample.narabikae :position, size: 100
    end

    it 'reassigns positions based on provided order' do
      record_a = ReorderSample.create!
      record_b = ReorderSample.create!
      record_c = ReorderSample.create!

      record_a.update_columns(order: 'c', position: 'z0')
      record_b.update_columns(order: 'a', position: 'z1')
      record_c.update_columns(order: 'b', position: 'z2')

      ReorderSample.reorder_position(:order)

      expect(ReorderSample.order(:position).pluck(:order)).to eq(%w[a b c])
    end

    it 'defaults to ordering by the field' do
      record_a = ReorderSample.create!
      record_b = ReorderSample.create!
      record_c = ReorderSample.create!

      record_a.update_columns(order: 'first', position: 'c0')
      record_b.update_columns(order: 'second', position: 'a0')
      record_c.update_columns(order: 'third', position: 'b0')

      ReorderSample.reorder_position

      expect(ReorderSample.order(:position).pluck(:order)).to eq(%w[second third first])
    end
  end

  context 'with scope' do
    before do
      stub_const('ScopedReorderSample', Class.new(ApplicationRecord) do
        self.table_name = 'samples'
      end)
      ScopedReorderSample.narabikae :position, size: 100, scope: %i[user_id]
    end

    it 'reorders within each scope' do
      record_a1 = ScopedReorderSample.create!(user_id: '1')
      record_a2 = ScopedReorderSample.create!(user_id: '1')
      record_b1 = ScopedReorderSample.create!(user_id: '2')
      record_b2 = ScopedReorderSample.create!(user_id: '2')

      record_a1.update_columns(order: 'b', position: 'z0')
      record_a2.update_columns(order: 'a', position: 'z1')
      record_b1.update_columns(order: 'd', position: 'z2')
      record_b2.update_columns(order: 'c', position: 'z3')

      ScopedReorderSample.reorder_position(:order)

      expect(ScopedReorderSample.where(user_id: '1').order(:position).pluck(:order)).to eq(%w[a b])
      expect(ScopedReorderSample.where(user_id: '2').order(:position).pluck(:order)).to eq(%w[c d])
    end
  end
end
