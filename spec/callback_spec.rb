require 'rails_helper'

describe 'Callbacks' do
  before do
    load Rails.root.join('app/models/chapter.rb')
  end

  describe 'before_save' do
    context 'when the record is created' do
      before do
        Chapter.narabikae :position, size: 500, scope: %i[course_id]
      end

      let(:course_a) { Course.new(name: 'Course A') }
      let(:course_b) { Course.new(name: 'Course B') }

      before do
        ActiveRecord::Base.transaction do
          course_a.chapters.build(title: 'Chapter 1')
          course_b.chapters.build(title: 'Chapter 1')

          course_a.save!
          course_b.save!
        end
      end

      it 'sets the position' do
        expect(course_a.chapters.first.position).to eq('a0')
        expect(course_b.chapters.first.position).to eq('a0')
      end
    end

    context 'when the records are created' do
      before do
        Chapter.narabikae :position, size: 500
      end

      before do
        Chapter.create([
          { title: 'Chapter 1' },
          { title: 'Chapter 2' },
          { title: 'Chapter 3' }
        ])
      end

      it { expect(Chapter.pluck(:position)).to eq(%w[a0 a1 a2]) }
    end
  end

  describe 'before_update' do
    before do
      Chapter.narabikae :position, size: 500, scope: %i[course_id]
    end

    let(:course_a) { Course.create(name: 'Course') }
    let(:course_b) { Course.create(name: 'Course') }

    let!(:chapter_a) { course_a.chapters.create(title: 'Chapter A') }
    let!(:chapter_b) { course_b.chapters.create(title: 'Chapter B') }

    context 'when the value in the scope is changed' do
      before { chapter_a.course_id = course_b.id }

      context "when position isn't changed" do
        before { chapter_a.save! }

        it { expect(chapter_a.position).to eq('a1') }
      end

      context "when position is changed" do
        before { chapter_a.update!(position: 'a5') }

        it { expect(chapter_a.position).to eq('a5') }
      end
    end

    context 'when the value in the scope is not changed' do
      context 'when position is not changed' do
        before { chapter_a.update!(title: 'Chapter A') }

        it { expect(chapter_a.position).to eq('a0') }
      end

      context 'when position is changed' do
        before { chapter_a.update!(position: 'a5') }

        it { expect(chapter_a.position).to eq('a5') }
      end
    end
  end

  after do
    Object.send(:remove_const, 'Chapter')
  end
end
