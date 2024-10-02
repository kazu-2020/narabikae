class CreateSampleModels < ActiveRecord::Migration[7.2]
  def change
    def char_config(**options)
      case ActiveRecord::Base.connection.adapter_name
      when 'Mysql2'
        {
          charset: 'ascii',
          collation: 'ascii_bin'
        }.merge(options)
      when 'PostgreSQL'
        {
          collation: 'C'
        }
      when 'SQLite'
        {
          collation: 'binary'
        }.merge(options)
      else
        options
      end
    end

    create_table :samples do |t|
      t.string :user_id

      t.string :order, **char_config(null: false, limit: 100)
      t.string :position, **char_config(null: false, limit: 500)
    end

      create_table :tasks do |t|
        t.integer :user_id
        t.string  :name

        t.string  :position, **char_config(null: false, limit: 500)

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

        t.string :position, **char_config(null: false, limit: 500)

        t.timestamps
      end
      add_index :chapters, %i[course_id position], unique: true
  end
end
