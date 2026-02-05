#!/usr/bin/env ruby
# frozen_string_literal: true

# Benchmark: Neighbor-aware positioning vs original retry-based positioning
#
# Usage:
#   TARGET_DB=sqlite bundle exec ruby benchmark/position_benchmark.rb
#   TARGET_DB=postgres bundle exec ruby benchmark/position_benchmark.rb
#
# This compares two approaches for find_position_after/before:
#   OLD: Generate key after target, check uniqueness, retry on collision (up to 10 times)
#   NEW: Query DB for next neighbor, generate midpoint between target and neighbor (no collisions)

ENV["RAILS_ENV"] = "test"
ENV["TARGET_DB"] ||= "sqlite"

require_relative "../test/dummy/config/environment"

# Ensure schema is loaded with proper collation for position column
ActiveRecord::Schema.define do
  create_table :tasks, force: true do |t|
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      t.string :position, collation: "C"
    else
      t.string :position
    end
    t.integer :user_id
    t.timestamps
  end

  add_index :tasks, :position
end
require "benchmark"

# Ensure we have a clean database
ActiveRecord::Base.connection.execute("DELETE FROM tasks")

puts "=" * 70
puts "Narabikae Position Benchmark"
puts "=" * 70
puts "Database: #{ActiveRecord::Base.connection.adapter_name}"
puts "Ruby: #{RUBY_VERSION}"
puts "Rails: #{Rails.version}"
puts ""

# --- Query counter ---
module QueryCounter
  mattr_accessor :count, default: 0

  def self.reset!
    self.count = 0
  end
end

ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
  unless payload[:name]&.match?(/SCHEMA|TRANSACTION/)
    QueryCounter.count += 1
  end
end

# --- Old algorithm (original find_position_after without neighbor lookup) ---
class OldPositionStrategy
  def initialize(record, option)
    @record = record
    @option = option
  end

  def find_position_after(target, challenge: 10)
    target_key = target.is_a?(String) ? target : target&.send(@option.field)
    target_key ||= current_last_position
    key = FractionalIndexer.generate_key(prev_key: target_key)
    return key if valid?(key)

    (challenge || 0).times do |i|
      key = FractionalIndexer.generate_key(prev_key: target_key, next_key: key)
      key += random_fractional
      return key if valid?(key)
    end

    nil
  rescue FractionalIndexer::Error
    nil
  end

  def find_position_before(target, challenge: 10)
    target_key = target.is_a?(String) ? target : target&.send(@option.field)
    target_key ||= current_first_position
    key = FractionalIndexer.generate_key(next_key: target_key)
    return key if valid?(key)

    (challenge || 0).times do |i|
      key = FractionalIndexer.generate_key(prev_key: key, next_key: target_key)
      key += random_fractional
      return key if valid?(key)
    end

    nil
  rescue FractionalIndexer::Error
    nil
  end

  private

  def current_first_position
    model.merge(model_scope).minimum(@option.field)
  end

  def current_last_position
    model.merge(model_scope).maximum(@option.field)
  end

  def model
    @record.class.base_class.unscoped
  end

  def model_scope
    model.where(@record.slice(*@option.scope))
  end

  def random_fractional
    FractionalIndexer.configuration.digits[1..].sample
  end

  def uniq?(key)
    model.where(@option.field => key).merge(model_scope).empty?
  end

  def valid?(key)
    return false if key.blank?
    @option.key_max_size >= key.size && uniq?(key)
  end
end

# --- New algorithm (neighbor-aware, from our PR) ---
class NewPositionStrategy
  def initialize(record, option)
    @record = record
    @option = option
  end

  def find_position_after(target, challenge: 10)
    target_key = target.is_a?(String) ? target : target&.send(@option.field)
    target_key ||= current_last_position
    next_key = find_next_position_key(target_key)
    key = FractionalIndexer.generate_key(prev_key: target_key, next_key: next_key)
    return key if valid?(key)

    (challenge || 0).times do |i|
      key = FractionalIndexer.generate_key(prev_key: target_key, next_key: key)
      key += random_fractional
      return key if valid?(key)
    end

    nil
  rescue FractionalIndexer::Error
    nil
  end

  def find_position_before(target, challenge: 10)
    target_key = target.is_a?(String) ? target : target&.send(@option.field)
    target_key ||= current_first_position
    prev_key = find_prev_position_key(target_key)
    key = FractionalIndexer.generate_key(prev_key: prev_key, next_key: target_key)
    return key if valid?(key)

    (challenge || 0).times do |i|
      key = FractionalIndexer.generate_key(prev_key: key, next_key: target_key)
      key += random_fractional
      return key if valid?(key)
    end

    nil
  rescue FractionalIndexer::Error
    nil
  end

  private

  def current_first_position
    model.merge(model_scope).minimum(@option.field)
  end

  def current_last_position
    model.merge(model_scope).maximum(@option.field)
  end

  def find_next_position_key(key)
    return nil if key.nil?
    model.merge(model_scope)
         .where(model.arel_table[@option.field].gt(key))
         .order(@option.field => :asc)
         .pick(@option.field)
  end

  def find_prev_position_key(key)
    return nil if key.nil?
    model.merge(model_scope)
         .where(model.arel_table[@option.field].lt(key))
         .order(@option.field => :desc)
         .pick(@option.field)
  end

  def model
    @record.class.base_class.unscoped
  end

  def model_scope
    model.where(@record.slice(*@option.scope))
  end

  def random_fractional
    FractionalIndexer.configuration.digits[1..].sample
  end

  def uniq?(key)
    model.where(@option.field => key).merge(model_scope).empty?
  end

  def valid?(key)
    return false if key.blank?
    @option.key_max_size >= key.size && uniq?(key)
  end
end

# --- Benchmark helpers ---
def setup_dense_tasks(count)
  ActiveRecord::Base.connection.execute("DELETE FROM tasks")
  # Create sequential positions: a0, a1, a2, ..., a{count-1}
  keys = FractionalIndexer.generate_keys(count: count)
  keys.each do |key|
    Task.create!(position: key)
  end
  keys
end

def run_benchmark(label, strategy, target, iterations: 100)
  QueryCounter.reset!
  results = []

  time = Benchmark.realtime do
    iterations.times do
      QueryCounter.reset!
      key = strategy.find_position_after(target)
      results << { key: key, queries: QueryCounter.count }
      # Clean up generated key if it was inserted (it wasn't, we just generated)
    end
  end

  avg_queries = results.sum { |r| r[:queries] }.to_f / results.size
  all_valid = results.all? { |r| r[:key].present? }

  {
    label: label,
    total_time_ms: (time * 1000).round(2),
    avg_time_ms: (time * 1000 / iterations).round(4),
    avg_queries: avg_queries.round(2),
    all_valid: all_valid,
    sample_key: results.first[:key]
  }
end

option = Narabikae::Option.new(field: :position, key_max_size: 200)

# --- Scenario 1: Insert after a task with NO collision (end of list) ---
puts "-" * 70
puts "Scenario 1: Insert after LAST task (no collision possible)"
puts "-" * 70

[ 100, 1000, 10_000 ].each do |n|
  keys = setup_dense_tasks(n)
  last_task = Task.find_by(position: keys.last)

  old_strategy = OldPositionStrategy.new(Task.new, option)
  new_strategy = NewPositionStrategy.new(Task.new, option)

  old_result = run_benchmark("OLD (#{n} tasks)", old_strategy, last_task)
  new_result = run_benchmark("NEW (#{n} tasks)", new_strategy, last_task)

  printf "  %-20s | Time: %8.2f ms | Avg queries: %5.2f | Valid: %s\n",
         old_result[:label], old_result[:total_time_ms], old_result[:avg_queries], old_result[:all_valid]
  printf "  %-20s | Time: %8.2f ms | Avg queries: %5.2f | Valid: %s\n",
         new_result[:label], new_result[:total_time_ms], new_result[:avg_queries], new_result[:all_valid]
  puts ""
end

# --- Scenario 2: Insert after a task WITH guaranteed collision ---
puts "-" * 70
puts "Scenario 2: Insert after a MIDDLE task (next position occupied)"
puts "  OLD must retry; NEW finds neighbor and generates midpoint"
puts "-" * 70

[ 100, 1000, 10_000 ].each do |n|
  keys = setup_dense_tasks(n)
  # Pick a task in the middle - the next position is occupied
  mid_index = n / 2
  mid_task = Task.find_by(position: keys[mid_index])

  old_strategy = OldPositionStrategy.new(Task.new, option)
  new_strategy = NewPositionStrategy.new(Task.new, option)

  old_result = run_benchmark("OLD (#{n} tasks)", old_strategy, mid_task)
  new_result = run_benchmark("NEW (#{n} tasks)", new_strategy, mid_task)

  printf "  %-20s | Time: %8.2f ms | Avg queries: %5.2f | Valid: %s\n",
         old_result[:label], old_result[:total_time_ms], old_result[:avg_queries], old_result[:all_valid]
  printf "  %-20s | Time: %8.2f ms | Avg queries: %5.2f | Valid: %s\n",
         new_result[:label], new_result[:total_time_ms], new_result[:avg_queries], new_result[:all_valid]

  speedup = old_result[:total_time_ms] / new_result[:total_time_ms]
  query_reduction = ((old_result[:avg_queries] - new_result[:avg_queries]) / old_result[:avg_queries] * 100).round(1)
  puts "  => Speedup: #{speedup.round(2)}x | Query reduction: #{query_reduction}%"
  puts ""
end

# --- Scenario 3: Repeated insertions at same position (worst case for OLD) ---
puts "-" * 70
puts "Scenario 3: Repeated insertions after same task (accumulating collisions)"
puts "  Each insertion adds a new record between target and next,"
puts "  making future collisions increasingly likely for OLD algorithm"
puts "-" * 70

setup_dense_tasks(10_000)
keys = Task.order(:position).pluck(:position)
mid_task = Task.find_by(position: keys[5000])

[ 10, 100, 1000 ].each do |insertions|
  # Reset to clean state
  setup_dense_tasks(10_000)
  keys = Task.order(:position).pluck(:position)
  mid_task = Task.find_by(position: keys[5000])

  old_queries_total = 0
  new_queries_total = 0

  old_time = Benchmark.realtime do
    insertions.times do
      strategy = OldPositionStrategy.new(Task.new, option)
      QueryCounter.reset!
      key = strategy.find_position_after(mid_task)
      old_queries_total += QueryCounter.count
      Task.create!(position: key) if key # Insert so next iteration has more collisions
    end
  end

  # Reset for new strategy
  setup_dense_tasks(10_000)
  keys = Task.order(:position).pluck(:position)
  mid_task = Task.find_by(position: keys[5000])

  new_time = Benchmark.realtime do
    insertions.times do
      strategy = NewPositionStrategy.new(Task.new, option)
      QueryCounter.reset!
      key = strategy.find_position_after(mid_task)
      new_queries_total += QueryCounter.count
      Task.create!(position: key) if key
    end
  end

  printf "  %d insertions: OLD %6.2f ms (%d queries) | NEW %6.2f ms (%d queries) | Speedup: %.2fx\n",
         insertions, old_time * 1000, old_queries_total, new_time * 1000, new_queries_total,
         (old_time / new_time)
end

# --- Scenario 4: Ordering correctness ---
puts "-" * 70
puts "Scenario 4: Ordering correctness and key quality"
puts "  OLD generates key after target with no upper bound (may exceed next neighbor)"
puts "  NEW generates midpoint between target and next neighbor (always ordered)"
puts "-" * 70

setup_dense_tasks(10_000)
keys = Task.order(:position).pluck(:position)

old_ordering_violations = 0
new_ordering_violations = 0
old_key_lengths = []
new_key_lengths = []

# Test 100 insertions at various positions throughout the list
100.times do |i|
  idx = (i * 100) % 9999  # Pick different positions throughout the list
  target_key = keys[idx]
  next_key = keys[idx + 1] if idx + 1 < keys.size

  old_strategy = OldPositionStrategy.new(Task.new, option)
  new_strategy = NewPositionStrategy.new(Task.new, option)

  old_generated = old_strategy.find_position_after(Task.new(position: target_key))
  new_generated = new_strategy.find_position_after(Task.new(position: target_key))

  if old_generated && next_key
    old_key_lengths << old_generated.size
    old_ordering_violations += 1 if old_generated >= next_key
  end

  if new_generated && next_key
    new_key_lengths << new_generated.size
    new_ordering_violations += 1 if new_generated >= next_key
  end
end

puts ""
printf "  %-20s | Ordering violations: %d/100 | Avg key length: %.1f chars\n",
       "OLD algorithm", old_ordering_violations, old_key_lengths.sum.to_f / old_key_lengths.size
printf "  %-20s | Ordering violations: %d/100 | Avg key length: %.1f chars\n",
       "NEW algorithm", new_ordering_violations, new_key_lengths.sum.to_f / new_key_lengths.size

if old_ordering_violations > 0
  puts ""
  puts "  WARNING: OLD algorithm generated #{old_ordering_violations} keys that break sort order!"
  puts "  These would cause items to appear in wrong position when sorted."
end

puts ""

# --- Scenario 5: Key growth under repeated adjacent insertions ---
puts "-" * 70
puts "Scenario 5: Key length growth under repeated same-position insertions"
puts "  Simulates a user repeatedly adding tasks after the same task"
puts "-" * 70

[ 10, 100, 1000 ].each do |insertions|
  setup_dense_tasks(10_000)
  target = Task.find_by(position: Task.order(:position).pluck(:position)[5000])

  old_keys = []
  new_keys = []

  # OLD: repeated insertions (each time inserting after same target)
  insertions.times do
    strategy = OldPositionStrategy.new(Task.new, option)
    key = strategy.find_position_after(target)
    old_keys << key if key
    Task.create!(position: key) if key
  end

  # Reset
  setup_dense_tasks(10_000)
  target = Task.find_by(position: Task.order(:position).pluck(:position)[5000])

  # NEW: repeated insertions
  insertions.times do
    strategy = NewPositionStrategy.new(Task.new, option)
    key = strategy.find_position_after(target)
    new_keys << key if key
    Task.create!(position: key) if key
  end

  old_avg_len = old_keys.any? ? (old_keys.sum(&:size).to_f / old_keys.size).round(1) : 0
  new_avg_len = new_keys.any? ? (new_keys.sum(&:size).to_f / new_keys.size).round(1) : 0
  old_max_len = old_keys.map(&:size).max || 0
  new_max_len = new_keys.map(&:size).max || 0
  old_ordered = old_keys == old_keys.sort
  new_ordered = new_keys == new_keys.sort

  printf "  %d insertions: OLD avg=%4.1f max=%3d ordered=%s | NEW avg=%4.1f max=%3d ordered=%s\n",
         insertions, old_avg_len, old_max_len, old_ordered,
         new_avg_len, new_max_len, new_ordered
end

# --- Scenario 6: Drag-to-reposition correctness in dense lists ---
puts "-" * 70
puts "Scenario 6: Drag-to-reposition correctness (realistic outliner scenario)"
puts "  After repeated insertions create dense clusters, does 'position after X'"
puts "  actually land IMMEDIATELY after X, or somewhere further in the list?"
puts "-" * 70

[ 10, 100, 1000 ].each do |prior_insertions|
  # Step 1: Create a base list
  setup_dense_tasks(100)
  keys = Task.order(:position).pluck(:position)
  target = Task.find_by(position: keys[50])

  # Step 2: Simulate prior activity - many insertions after the same target
  # (like a user repeatedly adding tasks after task #50)
  prior_insertions.times do
    # Use NEW strategy for setup since it always produces valid keys
    strategy = NewPositionStrategy.new(Task.new, option)
    key = strategy.find_position_after(target)
    Task.create!(position: key) if key
  end

  # Now we have a dense cluster after target. Get the actual immediate neighbor.
  actual_next = Task.where("position > ?", target.position)
                    .order(:position).first

  # Step 3: A user drags a task to "position after target" - test both algorithms
  old_strategy = OldPositionStrategy.new(Task.new, option)
  new_strategy = NewPositionStrategy.new(Task.new, option)

  old_key = old_strategy.find_position_after(target)
  new_key = new_strategy.find_position_after(target)

  old_immediate = old_key && actual_next && old_key < actual_next.position
  new_immediate = new_key && actual_next && new_key < actual_next.position

  # Count how many records the old key jumps over
  old_skipped = 0
  new_skipped = 0
  if old_key
    old_skipped = Task.where("position > ? AND position < ?", target.position, old_key).count
  end
  if new_key
    new_skipped = Task.where("position > ? AND position < ?", target.position, new_key).count
  end

  printf "  After %4d prior insertions:\n", prior_insertions
  printf "    OLD: immediately_after=%-5s  skipped=%d records  key=%s\n",
         old_immediate.to_s, old_skipped, old_key&.truncate(20)
  printf "    NEW: immediately_after=%-5s  skipped=%d records  key=%s\n",
         new_immediate.to_s, new_skipped, new_key&.truncate(20)

  if old_skipped > 0
    puts "    ^ OLD positioned task #{old_skipped} places away from intended position!"
  end
  puts ""
end

# Repeat test many times to show consistency
puts "  Consistency test: 50 drag-to-reposition attempts in dense list"
setup_dense_tasks(100)
keys = Task.order(:position).pluck(:position)
target = Task.find_by(position: keys[50])

# Create dense cluster
100.times do
  strategy = NewPositionStrategy.new(Task.new, option)
  key = strategy.find_position_after(target)
  Task.create!(position: key) if key
end

old_mispositions = 0
new_mispositions = 0

50.times do
  actual_next = Task.where("position > ?", target.position).order(:position).first

  old_strategy = OldPositionStrategy.new(Task.new, option)
  new_strategy = NewPositionStrategy.new(Task.new, option)

  old_key = old_strategy.find_position_after(target)
  new_key = new_strategy.find_position_after(target)

  if old_key && actual_next && old_key >= actual_next.position
    old_mispositions += 1
  end
  if new_key && actual_next && new_key >= actual_next.position
    new_mispositions += 1
  end

  # Insert both so the cluster gets denser
  Task.create!(position: old_key) if old_key
  Task.create!(position: new_key) if new_key
end

printf "  Results: OLD mispositioned %d/50 (%.0f%%) | NEW mispositioned %d/50 (%.0f%%)\n",
       old_mispositions, old_mispositions * 2.0, new_mispositions, new_mispositions * 2.0

if old_mispositions > 0
  puts ""
  puts "  CONCLUSION: OLD algorithm places tasks in WRONG position #{old_mispositions}/50 times"
  puts "  in dense lists. Users would see their dragged task appear in unexpected"
  puts "  locations rather than immediately after the target."
end

puts ""
puts "=" * 70
puts "Summary"
puts "=" * 70
puts ""
puts "The NEW neighbor-aware algorithm:"
puts "  - Replaces probabilistic retry+random with deterministic midpoint generation"
puts "  - Queries DB for actual next/prev neighbor, generates key between them"
puts "  - Consistent 2 queries per operation (neighbor lookup + uniqueness check)"
puts "  - OLD algorithm: 1 query best case, grows with collisions (retries + random)"
puts "  - Generated keys are guaranteed to maintain sort order relative to neighbors"
puts "  - Shorter keys for single insertions (proper midpoint vs unbounded suffix)"
puts "  - With indexed position column, neighbor lookup is O(log n)"
puts ""

# Cleanup
ActiveRecord::Base.connection.execute("DELETE FROM tasks")
