import 'package:drift/drift.dart';

import '../../domain/entities/blackout_date.dart';
import '../../domain/services/blackout_date_repository.dart';
import '../drift/database.dart';

class DriftBlackoutDateRepository implements BlackoutDateRepository {
  DriftBlackoutDateRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> insertBlackoutDate(BlackoutDate blackoutDate) async {
    await _db
        .into(_db.blackoutDates)
        .insert(
          BlackoutDatesCompanion.insert(
            id: blackoutDate.id,
            goalId: blackoutDate.goalId,
            date: blackoutDate.date,
            reason: Value(blackoutDate.reason),
          ),
        );
  }

  @override
  Future<void> upsertBlackoutDate(BlackoutDate blackoutDate) async {
    await _db
        .into(_db.blackoutDates)
        .insertOnConflictUpdate(
          BlackoutDatesCompanion.insert(
            id: blackoutDate.id,
            goalId: blackoutDate.goalId,
            date: blackoutDate.date,
            reason: Value(blackoutDate.reason),
          ),
        );
  }

  @override
  Future<List<BlackoutDate>> findAllForGoal(String goalId) async {
    final rows = await (_db.select(
      _db.blackoutDates,
    )..where((t) => t.goalId.equals(goalId))).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<BlackoutDate>> watchBlackoutDatesForGoal(String goalId) {
    return (_db.select(_db.blackoutDates)
          ..where((t) => t.goalId.equals(goalId)))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.blackoutDates).go();

  BlackoutDate _toDomain(BlackoutDateRow row) => BlackoutDate(
    id: row.id,
    goalId: row.goalId,
    date: row.date,
    reason: row.reason,
  );
}
