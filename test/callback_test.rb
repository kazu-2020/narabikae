require "test_helper"

class CallbacksTest < ActiveSupport::TestCase
  setup do
    load Rails.root.join("app/models/chapter.rb")
  end

  teardown do
    Object.send(:remove_const, "Chapter") if Object.const_defined?("Chapter")
  end

  test "sets position on create with scope" do
    Chapter.narabikae :position, size: 500, scope: %i[course_id]

    course_a = Course.new(name: "Course A")
    course_b = Course.new(name: "Course B")

    ActiveRecord::Base.transaction do
      course_a.chapters.build(title: "Chapter 1")
      course_b.chapters.build(title: "Chapter 1")

      course_a.save!
      course_b.save!
    end

    assert_equal "a0", course_a.chapters.first.position
    assert_equal "a0", course_b.chapters.first.position
  end

  test "keeps provided position on create" do
    Chapter.narabikae :position, size: 500, scope: %i[course_id]

    course = Course.create!(name: "Course A")
    chapter = course.chapters.build(title: "Chapter 1")

    chapter.position = "a5"
    chapter.save!

    assert_equal "a5", chapter.position
  end

  test "assigns sequential positions on create without scope" do
    Chapter.narabikae :position, size: 500

    Chapter.create!([
      { title: "Chapter 1" },
      { title: "Chapter 2" },
      { title: "Chapter 3" }
    ])

    assert_equal %w[a0 a1 a2], Chapter.pluck(:position)
  end

  test "recalculates position when scope changes without explicit position update" do
    Chapter.narabikae :position, size: 500, scope: %i[course_id]

    course_a = Course.create!(name: "Course")
    course_b = Course.create!(name: "Course")

    chapter_a = course_a.chapters.create!(title: "Chapter A")
    course_b.chapters.create!(title: "Chapter B")

    chapter_a.course_id = course_b.id
    chapter_a.save!

    assert_equal "a1", chapter_a.position
  end

  test "preserves explicit position when scope changes" do
    Chapter.narabikae :position, size: 500, scope: %i[course_id]

    course_a = Course.create!(name: "Course")
    course_b = Course.create!(name: "Course")

    chapter_a = course_a.chapters.create!(title: "Chapter A")
    course_b.chapters.create!(title: "Chapter B")

    chapter_a.course_id = course_b.id
    chapter_a.update!(position: "a5")

    assert_equal "a5", chapter_a.position
  end

  test "keeps position when scope and position are unchanged" do
    Chapter.narabikae :position, size: 500, scope: %i[course_id]

    course_a = Course.create!(name: "Course")
    course_b = Course.create!(name: "Course")

    chapter_a = course_a.chapters.create!(title: "Chapter A")
    course_b.chapters.create!(title: "Chapter B")

    chapter_a.update!(title: "Chapter A")

    assert_equal "a0", chapter_a.position
  end

  test "keeps position when scope is unchanged but position is updated" do
    Chapter.narabikae :position, size: 500, scope: %i[course_id]

    course_a = Course.create!(name: "Course")
    course_b = Course.create!(name: "Course")

    chapter_a = course_a.chapters.create!(title: "Chapter A")
    course_b.chapters.create!(title: "Chapter B")

    chapter_a.update!(position: "a5")

    assert_equal "a5", chapter_a.position
  end
end
