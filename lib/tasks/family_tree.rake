# Where does a chart build spend its time? Run against development data:
#
#   bin/rails "family_tree:profile[all]"        # depth 1, 2, 3 or all; adds up[]/down[] via UP=1,2 DOWN=3
#   bin/rails "family_tree:explain[123]"        # EXPLAIN ANALYZE the recursive queries for one person
#
# profile prints wall time per phase (load + merge, layout, cards, edges),
# the number of SQL statements and their total database time, then the
# statements that ran most often. Many repeats of one statement is an N+1;
# wall time far above database time is Ruby.
namespace :family_tree do
  desc "Time a chart build by phase and by SQL statement"
  task :profile, [ :depth ] => :environment do |_, args|
    depth = { "all" => FamilyTree::Chart::ALL }.fetch(args[:depth].to_s) { (args[:depth] || 1).to_i }
    up = ENV.fetch("UP", "").split(",").map(&:to_i)
    down = ENV.fetch("DOWN", "").split(",").map(&:to_i)

    statements = Hash.new { |h, k| h[k] = { count: 0, ms: 0.0 } }
    subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, start, finish, _, payload|
      next if payload[:name] == "SCHEMA" || payload[:cached]
      entry = statements[payload[:sql].squish[0, 90]]
      entry[:count] += 1
      entry[:ms] += (finish - start) * 1000
    end

    chart = FamilyTree::Chart.new(up:, down:, depth:)
    phases = {
      "load + merge" => -> { chart.units },
      "layout" => -> { chart.layout.positions },
      "cards" => -> { chart.cards },
      "edges" => -> { FamilyTree::Edges.new(positions: chart.layout.positions, units: chart.units).segments }
    }
    puts "depth #{args[:depth] || 1}, up #{up.inspect}, down #{down.inspect}"
    phases.each { |label, work| puts format("  %-14s %8.1f ms", label, ActiveSupport::Benchmark.realtime(:float_millisecond, &work)) }

    puts format("  %d people shown; %d statements, %.1f ms in the database",
      chart.shown, statements.values.sum { |s| s[:count] }, statements.values.sum { |s| s[:ms] })
    statements.sort_by { |_, s| -s[:count] }.first(8).each do |sql, s|
      puts format("  %5d× %8.1f ms  %s", s[:count], s[:ms], sql)
    end
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription) if subscription
  end

  desc "EXPLAIN ANALYZE the recursive tree queries for one person"
  task :explain, [ :person_id ] => :environment do |_, args|
    person_id = Integer(args[:person_id])
    connection = ActiveRecord::Base.connection
    {
      "ancestors" => [ Individual::Queries::ANCESTORS_SQL, { person_id:, max_generations: 99 } ],
      "descendants" => [ Individual::Queries::DESCENDANTS_SQL, { person_id:, max_generations: 99 } ],
      "metadata" => [ FamilyTree::Metadata::METADATA_SQL, { loaded_ids: [ person_id ] } ]
    }.each do |label, (sql, binds)|
      puts "== #{label}"
      plan = connection.select_all("EXPLAIN (ANALYZE, BUFFERS) " + ActiveRecord::Base.sanitize_sql_array([ sql, binds ]))
      plan.rows.each { |row| puts "  #{row.first}" }
    end
  end
end
