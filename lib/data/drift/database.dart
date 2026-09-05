import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

/// The sole local persistence for Goal/Version/Log data (AD-3). Wired as a
/// singleton exclusively through a Riverpod provider (AD-2) — never a
/// global/static accessor.
@DriftDatabase(
  tables: [
    Goals,
    GoalVersions,
    GoalLogs,
    BlackoutDates,
    CheatDays,
    StatusCaches,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'tracker'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Story 3.1 (AD-7): status_cache is purely a read-optimization derived
    // by CacheWriter.rebuildAll() from existing Goal/Version/Log data — an
    // existing v1 database only needs the new table added, nothing backfilled
    // here (a cache miss falls back to evaluate() until CacheWriter next
    // writes that row, AD-8).
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(statusCaches);
      }
    },
  );
}
