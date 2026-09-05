import 'package:drift/drift.dart';

import '../../domain/entities/day_status.dart';
import '../../domain/services/status_cache_repository.dart';
import '../drift/database.dart';

class DriftStatusCacheRepository implements StatusCacheRepository {
  DriftStatusCacheRepository(this._db);

  final AppDatabase _db;

  @override
  Future<DayStatus?> getStatus(String goalId, String date) async {
    final row =
        await (_db.select(_db.statusCaches)..where(
              (t) => t.goalId.equals(goalId) & t.date.equals(date),
            ))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> upsertStatus(DayStatus status) async {
    await _db
        .into(_db.statusCaches)
        .insertOnConflictUpdate(
          StatusCachesCompanion.insert(
            goalId: status.goalId,
            date: status.date,
            status: status.status.name,
            currentValue: Value(status.currentValue),
            targetValue: Value(status.targetValue),
          ),
        );
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.statusCaches).go();

  DayStatus _toDomain(StatusCacheRow row) => DayStatus(
    goalId: row.goalId,
    date: row.date,
    status: DayStatusValue.values.byName(row.status),
    currentValue: row.currentValue,
    targetValue: row.targetValue,
  );
}
