class CreateSampleModels < ActiveRecord::Migration[7.2]
  def change
    create_table :samples do |t|
      t.string :user_id

      t.string :order,
               null: false,
               limit: 100,
               charset: 'ascii',
               collation: 'ascii_bin'

      t.string  :position,
                null: false,
                limit: 500,
                charset: 'ascii',
                collation: 'ascii_bin'
    end

    create_table :tasks do |t|
      t.integer :user_id
      t.string  :name

      t.string  :position,
                null: false,
                limit: 500,
                charset: 'ascii',
                collation: 'ascii_bin'

      t.timestamps
    end
    add_index :tasks, :position, unique: true

    create_table :courses do |t|
      t.string :name

      t.timestamps
    end

    create_table :chapters do |t|
      t.references :course, foreign_key: true, null: true
      t.string :title

      t.string  :position,
                null: false,
                limit: 500,
                charset: 'ascii',
                collation: 'ascii_bin'

      t.timestamps
    end
    add_index :chapters, %i[course_id position], unique: true
  end
end
