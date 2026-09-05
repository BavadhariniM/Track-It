import 'package:drift/drift.dart';

import '../../domain/entities/goal.dart';
import '../../domain/services/goal_repository.dart';
import '../drift/database.dart';

class DriftGoalRepository implements GoalRepository {
  DriftGoalRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> insertGoal(Goal goal) async {
    await _db
        .into(_db.goals)
        .insert(
          GoalsCompanion.insert(
            id: goal.id,
            name: goal.name,
            description: Value(goal.description),
            category: Value(goal.category),
            archived: Value(goal.archived),
            startDate: goal.startDate,
            endDate: Value(goal.endDate),
          ),
        );
  }

  @override
  Future<void> upsertGoal(Goal goal) async {
    await _db
        .into(_db.goals)
        .insertOnConflictUpdate(
          GoalsCompanion.insert(
            id: goal.id,
            name: goal.name,
            description: Value(goal.description),
            category: Value(goal.category),
            archived: Value(goal.archived),
            startDate: goal.startDate,
            endDate: Value(goal.endDate),
          ),
        );
  }

  @override
  Future<Goal?> findById(String goalId) async {
    final row = await (_db.select(
      _db.goals,
    )..where((t) => t.id.equals(goalId))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> updateGoal(Goal goal) async {
    await (_db.update(_db.goals)..where((t) => t.id.equals(goal.id))).write(
      GoalsCompanion(
        name: Value(goal.name),
        description: Value(goal.description),
        category: Value(goal.category),
        archived: Value(goal.archived),
        startDate: Value(goal.startDate),
        endDate: Value(goal.endDate),
      ),
    );
  }

  @override
  Stream<List<Goal>> watchAllGoals() {
    return _db
        .select(_db.goals)
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.goals).go();

  Goal _toDomain(GoalRow row) => Goal(
    id: row.id,
    name: row.name,
    description: row.description,
    category: row.category,
    archived: row.archived,
    startDate: row.startDate,
    endDate: row.endDate,
  );
}
