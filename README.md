# Narabikae

[![test](https://github.com/kazu-2020/narabikae/actions/workflows/ci.yaml/badge.svg?branch=main&event=push)](https://github.com/kazu-2020/narabikae/actions/workflows/ci.yaml)

Narabikae(Japanese: 並び替え) means "reorder". Like [acts_as_list](https://github.com/brendon/acts_as_list), this gem provides automatic order management and reordering functionality for your records.

One of the key advantages of this gem is its use of the [fractional indexing algorithm](https://www.figma.com/blog/realtime-editing-of-ordered-sequences/#fractional-indexing), which greatly enhances the efficiency of reordering operations. With Narabikae, regardless of the amount of data, "only a single record" is updated during the reordering process 🎉.

## Installation

In your Gemfile

```ruby
gem "narabikae"
```

## Getting started

### Adding a column to manage order

To manage the order of records, you'll need to create a column in your database. A key feature of this gem is that it generates the order as a string!

```rb
# example

create_table :tasks do |t|
  t.string :name

  # for MySQL
  t.string :position, null: false, limit: 200, charset: 'ascii', collation: 'ascii_bin'

  # for PostgreSQL
  t.string :position, null: false, limit: 200, collation: 'C'

  # for SQLite3
  t.string :position, null: false, collation: 'binary'
end
add_index :tasks, :position, unique: true

```

#### Key points to consider when creating the column:

- Set the collation to distinguish between uppercase and lowercase letters.

  For example, if using MySQL 8.0’s default collation (utf8mb4_0900_ai_ci), which does not distinguish between uppercase and lowercase, the sort results may not behave as expected.

- It is recommended to apply both NOT NULL and UNIQUE constraints.

  This ensures data integrity and efficient ordering.

- Explicitly set a character limit for the column.

  Since this column will typically be indexed, it is important to set an appropriate length. This gem uses a base-62 numbering system to represent the order. In the example above, with a length limit of 200 characters, you can represent up to "62^200 unique order values", providing a huge range for ordered sequences.

### Adding configuration to your model

You only need to add one line as shown below!

```rb
class Task < ApplicationRecord
  narabikae :position, size: 200

  # arg1: optional
  # .     Specify the field you want to use for ordering.
  #       The default is :position.
  #
  # size: required
  #       Used for validation of the internally generated order value.
  #       This value should be equivalent to
  #       the limit set in the DB column.
end
```

Once this is done, the position will be automatically set each time a Task model instance is saved!

```rb
Task.create([
          { name: 'task-1' },
          { name: 'task-2' },
          { name: 'task-3' }
     ])
Task.order(:position).pluck(:name, :position)
# => [["task-1", "a0"], ["task-2", "a1"], ["task-3", "a2"]]

```

> [!NOTE]
> The position is set using the before_create callback. Therefore, do not define validations such as presence on the attributes managed by this gem!

## Usage Details

### Reorder

To insert an element after any specified item, use the `move_to_<field>_after` method.

```ruby
target = Task.create(name: 'target') # pos: 'a0'
tasks  = Task.create([
            { name: 'task-1' },      # pos: 'a1'
            { name: 'task-2' }       # pos: 'a2'
          ])

target.move_to_position_after(tasks.last)
# => true
target.position
# => 'a3'

# If no argument is passed, it will be inserted at the end of the list
tasks.first.move_to_position_after
# => true

Task.order(:position).pluck(:name, :position)
# => [["task-2", "a2"], ["target", "a3"], ["task-1", "a4"]]
```

To insert an element before any specified item, use the `move_to_<field>_before` method.

```ruby
tasks  = Task.create([
            { name: 'task-1' },      # pos: 'a0'
            { name: 'task-2' }       # pos: 'a1'
          ])
target = Task.create(name: 'target') # pos: 'a2'

target.move_to_position_before(tasks.first)
target.position
# => 'Zz'

# If no argument is passed, it will be inserted at the start of the list
tasks.last.move_to_position_before
# => true

Task.order(:position).pluck(:name, :position)
# => [["task-2", "Zy"], ["target", "Zz"], ["task-1", "a0"]]
```

The method you will likely use most often is `move_to_<field>_between`, which moves an element between two others!

```ruby
tasks  = Task.create([
            { name: 'task-1' },      # pos: 'a0'
            { name: 'task-2' }       # pos: 'a1'
          ])
target = Task.create(name: 'target') # pos: 'a2'

target.move_to_position_between(tasks.first, tasks.last)
# => true

target.position
# => 'a0V'

# If the first argument is nil, it behaves the same as `move_to_<field>_before`
# ex: target.move_to_position_between(nil, tasks.last)

# If the second argument is nil, it behaves the same as `move_to_<field>_after`
# ex: target.move_to_position_between(tasks.first, nil)
```

### Scope

You can use this when you want to manage independent positions within specific scopes, such as foreign keys.

```ruby
# example
class Course < ApplicationRecord
  has_many :chapters, dependent: :destroy
end

class Chapter < ApplicationRecord
  belongs_to :course

  narabikae :position, size: 100, scope: %i[course_id]
end

course = Course.create
other_course = Course.create

course.chapters.create
other_course.chapters.create

Chapter.pluck(:course_id, :position)
# => [[1, "a0"], [2, "a0"]]
```

When the attribute declared in the scope is changed during an update, and there is no change in the value of the position field, the position will be automatically recalculated, and the record will move to the end of the list.

```ruby
course = Course.create
other_course = Course.create

course.chapters.create
chapter = course.chapters.create # pos: 'a1'

chapter.course = other_course
chapter.save

chapter.position
# => 'a0'
```

### Retry generating position

Imagine the drag-and-drop functionality found in GitHub Projects or Zenhub, where items can be reordered. If two users try to insert different tickets between the same two tickets at the same time, their positions may overlap. In this case, the system will internally retry generating a unique position (up to 10 times by default).

If you want to increase the number of retries, you can use the "challenge" option to control the retry attempts, as shown below:

```ruby
ticket.move_to_position_between(t1, t2, challenge: 15)
```

> [!NOTE]
> Currently, if two users write to the database at exactly the same time, the system may not detect the duplicate positions, and the process will continue without error. This issue will be revisited if there is demand for a more robust solution in the future.

## Questions, Feedback

Feel free to message me on Github (kazu-2020)

## Contributing

Please wait a moment... 🙏

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
