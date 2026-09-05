import 'package:drift/drift.dart';

import '../../domain/entities/goal_log.dart';
import '../../domain/services/goal_log_repository.dart';
import '../drift/database.dart';

class DriftGoalLogRepository implements GoalLogRepository {
  DriftGoalLogRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> insertLog(GoalLog log) async {
    await _db
        .into(_db.goalLogs)
        .insert(
          GoalLogsCompanion.insert(
            id: log.id,
            goalId: log.goalId,
            date: log.date,
            timestamp: log.timestamp,
            value: log.value,
            completed: log.completed,
            dnfMarked: Value(log.dnfMarked),
            note: Value(log.note),
          ),
        );
  }

  @override
  Future<void> upsertLog(GoalLog log) async {
    await _db
        .into(_db.goalLogs)
        .insertOnConflictUpdate(
          GoalLogsCompanion.insert(
            id: log.id,
            goalId: log.goalId,
            date: log.date,
            timestamp: log.timestamp,
            value: log.value,
            completed: log.completed,
            dnfMarked: Value(log.dnfMarked),
            note: Value(log.note),
          ),
        );
  }

  @override
  Future<GoalLog?> getLogForDate(String goalId, String date) async {
    final row =
        await (_db.select(_db.goalLogs)
              ..where((t) => t.goalId.equals(goalId) & t.date.equals(date)))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<bool> existsOnOrAfter(String goalId, String date) async {
    final row =
        await (_db.select(_db.goalLogs)
              ..where(
                (t) =>
                    t.goalId.equals(goalId) & t.date.isBiggerOrEqualValue(date),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  @override
  Future<List<GoalLog>> findAllForGoal(String goalId) async {
    final rows = await (_db.select(
      _db.goalLogs,
    )..where((t) => t.goalId.equals(goalId))).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<GoalLog>> watchLogsForGoal(String goalId) {
    return (_db.select(_db.goalLogs)..where((t) => t.goalId.equals(goalId)))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.goalLogs).go();

  @override
  Future<void> deleteLog(String id) =>
      (_db.delete(_db.goalLogs)..where((t) => t.id.equals(id))).go();

  GoalLog _toDomain(GoalLogRow row) => GoalLog(
    id: row.id,
    goalId: row.goalId,
    date: row.date,
    timestamp: row.timestamp,
    value: row.value,
    completed: row.completed,
    dnfMarked: row.dnfMarked,
    note: row.note,
  );
}
