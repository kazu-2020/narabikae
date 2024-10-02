# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_09_28_051832) do
  create_table "chapters", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "course_id"
    t.string "title"
    t.string "position", limit: 500, null: false, collation: "ascii_bin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "position"], name: "index_chapters_on_course_id_and_position", unique: true
    t.index ["course_id"], name: "index_chapters_on_course_id"
  end

  create_table "courses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "samples", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "user_id"
    t.string "order", limit: 100, null: false, collation: "ascii_bin"
    t.string "position", limit: 500, null: false, collation: "ascii_bin"
  end

  create_table "tasks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.string "position", limit: 500, null: false, collation: "ascii_bin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_tasks_on_position", unique: true
  end

  add_foreign_key "chapters", "courses"
end
