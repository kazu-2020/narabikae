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

def narabikae_table_options
  return {} unless ActiveRecord::Base.connection.adapter_name == "Mysql2"

  { charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci" }
end

def narabikae_column_options(limit:, null:)
  options = { limit: limit, null: null }

  case ActiveRecord::Base.connection.adapter_name
  when "Mysql2"
    options[:collation] = "ascii_bin"
  when "PostgreSQL"
    options[:collation] = "C"
  when "SQLite"
    options[:collation] = "binary"
  end

  options
end

ActiveRecord::Schema.define(version: 2024_09_28_051832) do
  create_table "chapters", **narabikae_table_options, force: :cascade do |t|
    t.bigint "course_id"
    t.string "title"
    t.string "position", **narabikae_column_options(limit: 500, null: false)
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "position"], name: "index_chapters_on_course_id_and_position", unique: true
    t.index ["course_id"], name: "index_chapters_on_course_id"
  end

  create_table "composite_tasks", primary_key: ["account_id", "task_id"], **narabikae_table_options, force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "task_id", null: false
    t.string "name"
    t.string "position", **narabikae_column_options(limit: 500, null: false)
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "position"], name: "index_composite_tasks_on_account_id_and_position", unique: true
  end

  create_table "courses", **narabikae_table_options, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "samples", **narabikae_table_options, force: :cascade do |t|
    t.string "user_id"
    t.string "order", **narabikae_column_options(limit: 100, null: false)
    t.string "position", **narabikae_column_options(limit: 500, null: false)
  end

  create_table "tasks", **narabikae_table_options, force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.string "position", **narabikae_column_options(limit: 500, null: false)
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_tasks_on_position", unique: true
  end

  add_foreign_key "chapters", "courses"
end
