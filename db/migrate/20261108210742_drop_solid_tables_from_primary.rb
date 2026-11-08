# The Solid stack moved to its own SQLite databases (see config/database.yml
# and db/{cache,queue,cable}_schema.rb). These copies in the primary database
# only ever held ephemeral data.
class DropSolidTablesFromPrimary < ActiveRecord::Migration[8.1]
  TABLES = %i[
    solid_cable_messages
    solid_cache_entries
    solid_queue_blocked_executions
    solid_queue_claimed_executions
    solid_queue_failed_executions
    solid_queue_ready_executions
    solid_queue_recurring_executions
    solid_queue_scheduled_executions
    solid_queue_semaphores
    solid_queue_pauses
    solid_queue_processes
    solid_queue_recurring_tasks
    solid_queue_jobs
  ].freeze

  def up
    TABLES.each { |table| drop_table table, if_exists: true, force: :cascade }
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "re-run the solid_*:install generators instead"
  end
end
