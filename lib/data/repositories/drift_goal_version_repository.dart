import 'package:drift/drift.dart';

import '../../domain/entities/goal_version.dart';
import '../../domain/services/goal_version_repository.dart';
import '../drift/database.dart';

class DriftGoalVersionRepository implements GoalVersionRepository {
  DriftGoalVersionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> insertVersion(GoalVersion version) async {
    await _db
        .into(_db.goalVersions)
        .insert(
          GoalVersionsCompanion.insert(
            id: version.id,
            goalId: version.goalId,
            versionStartDate: version.versionStartDate,
            evaluationPeriod: version.evaluationPeriod,
            eligibleDaysRule: version.eligibleDaysRule,
            targetComparison: version.targetComparison,
            targetValue: version.targetValue,
            trackingType: version.trackingType,
            cheatDayQuota: Value(version.cheatDayQuota),
            isPaused: Value(version.isPaused),
          ),
        );
  }

  @override
  Future<void> upsertVersion(GoalVersion version) async {
    await _db
        .into(_db.goalVersions)
        .insertOnConflictUpdate(
          GoalVersionsCompanion.insert(
            id: version.id,
            goalId: version.goalId,
            versionStartDate: version.versionStartDate,
            evaluationPeriod: version.evaluationPeriod,
            eligibleDaysRule: version.eligibleDaysRule,
            targetComparison: version.targetComparison,
            targetValue: version.targetValue,
            trackingType: version.trackingType,
            cheatDayQuota: Value(version.cheatDayQuota),
            isPaused: Value(version.isPaused),
          ),
        );
  }

  @override
  Future<void> updateVersion(GoalVersion version) async {
    await (_db.update(
      _db.goalVersions,
    )..where((t) => t.id.equals(version.id))).write(
      GoalVersionsCompanion(
        goalId: Value(version.goalId),
        versionStartDate: Value(version.versionStartDate),
        evaluationPeriod: Value(version.evaluationPeriod),
        eligibleDaysRule: Value(version.eligibleDaysRule),
        targetComparison: Value(version.targetComparison),
        targetValue: Value(version.targetValue),
        trackingType: Value(version.trackingType),
        cheatDayQuota: Value(version.cheatDayQuota),
        isPaused: Value(version.isPaused),
      ),
    );
  }

  @override
  Future<GoalVersion?> findByGoalIdAndStartDate(
    String goalId,
    String versionStartDate,
  ) async {
    final row =
        await (_db.select(_db.goalVersions)..where(
              (t) =>
                  t.goalId.equals(goalId) &
                  t.versionStartDate.equals(versionStartDate),
            ))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<GoalVersion?> findGoverningVersion(String goalId, String date) async {
    final query = _db.select(_db.goalVersions)
      ..where(
        (t) =>
            t.goalId.equals(goalId) &
            t.versionStartDate.isSmallerOrEqualValue(date),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.versionStartDate)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<GoalVersion>> findAllForGoal(String goalId) async {
    final rows = await (_db.select(
      _db.goalVersions,
    )..where((t) => t.goalId.equals(goalId))).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<GoalVersion>> watchVersionsForGoal(String goalId) {
    return (_db.select(_db.goalVersions)..where((t) => t.goalId.equals(goalId)))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.goalVersions).go();

  GoalVersion _toDomain(GoalVersionRow row) => GoalVersion(
    id: row.id,
    goalId: row.goalId,
    versionStartDate: row.versionStartDate,
    evaluationPeriod: row.evaluationPeriod,
    eligibleDaysRule: row.eligibleDaysRule,
    targetComparison: row.targetComparison,
    targetValue: row.targetValue,
    trackingType: row.trackingType,
    cheatDayQuota: row.cheatDayQuota,
    isPaused: row.isPaused,
  );
}
