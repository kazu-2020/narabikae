require 'rails_helper'

describe 'call narabikae' do
  describe 'The method you expect to be used is dynamically defined.' do
    before do
      load Rails.root.join('app/models/sample.rb')
      Sample.narabikae :order, size: 100
      Sample.narabikae :position, size: 500
    end

    it 'The method you expect to be used is dynamically defined.' do
      expect(Sample.new).to respond_to(:move_to_order_after)
      expect(Sample.new).to respond_to(:move_to_order_before)
      expect(Sample.new).to respond_to(:move_to_order_between)

      expect(Sample.new).to respond_to(:move_to_position_after)
      expect(Sample.new).to respond_to(:move_to_position_before)
      expect(Sample.new).to respond_to(:move_to_position_between)
    end

    after do
      Object.send(:remove_const, 'Sample')
    end
  end

  describe 'duplicate definition is not allowed.' do
    before do
      load Rails.root.join('app/models/sample.rb')
      Sample.narabikae :order, size: 100
    end

    it { expect { Sample.narabikae :order, size: 100 }.to raise_error(Narabikae::Error).with_message('the field `order` is already registered') }

    after do
      Object.send(:remove_const, 'Sample')
    end
  end
end
