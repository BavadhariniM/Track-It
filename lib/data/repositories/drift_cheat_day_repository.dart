import 'package:drift/drift.dart';

import '../../domain/entities/cheat_day.dart';
import '../../domain/services/cheat_day_repository.dart';
import '../drift/database.dart';

class DriftCheatDayRepository implements CheatDayRepository {
  DriftCheatDayRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> insertCheatDay(CheatDay cheatDay) async {
    await _db
        .into(_db.cheatDays)
        .insert(
          CheatDaysCompanion.insert(
            id: cheatDay.id,
            goalId: cheatDay.goalId,
            date: cheatDay.date,
            note: Value(cheatDay.note),
          ),
        );
  }

  @override
  Future<void> upsertCheatDay(CheatDay cheatDay) async {
    await _db
        .into(_db.cheatDays)
        .insertOnConflictUpdate(
          CheatDaysCompanion.insert(
            id: cheatDay.id,
            goalId: cheatDay.goalId,
            date: cheatDay.date,
            note: Value(cheatDay.note),
          ),
        );
  }

  @override
  Future<List<CheatDay>> findByGoalIdInRange(
    String goalId,
    String startDate,
    String endDate,
  ) async {
    final rows =
        await (_db.select(_db.cheatDays)..where(
              (t) =>
                  t.goalId.equals(goalId) &
                  t.date.isBiggerOrEqualValue(startDate) &
                  t.date.isSmallerOrEqualValue(endDate),
            ))
            .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<CheatDay>> findAllForGoal(String goalId) async {
    final rows = await (_db.select(
      _db.cheatDays,
    )..where((t) => t.goalId.equals(goalId))).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<CheatDay>> watchCheatDaysForGoal(String goalId) {
    return (_db.select(_db.cheatDays)..where((t) => t.goalId.equals(goalId)))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.cheatDays).go();

  CheatDay _toDomain(CheatDayRow row) =>
      CheatDay(id: row.id, goalId: row.goalId, date: row.date, note: row.note);
}
