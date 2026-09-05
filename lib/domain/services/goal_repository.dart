import '../entities/goal.dart';

/// Domain-defined, Drift-agnostic interface. Implemented by
/// `DriftGoalRepository` in `data/repositories/` (AD-1).
abstract interface class GoalRepository {
  Future<void> insertGoal(Goal goal);

  /// Inserts [goal], or updates the existing row sharing its `id` in place —
  /// Story 6.2's JSON import upsert, which must preserve the file's original
  /// `id` rather than minting a fresh one the way [insertGoal]'s callers
  /// (`GoalService.createGoal`) do.
  Future<void> upsertGoal(Goal goal);

  /// The `Goal` with `id == goalId`, or `null` if none exists —
  /// `archiveGoal`'s (Story 2.3) read-before-write, so every field except
  /// `archived` is preserved on the update.
  Future<Goal?> findById(String goalId);

  /// Updates the row sharing [goal]'s `id` in place — backs `archiveGoal`'s
  /// single-column flip (Story 2.3). Goal creation (`insertGoal`) is the
  /// only other `GOAL` write; nothing else mutates an existing row.
  Future<void> updateGoal(Goal goal);

  Stream<List<Goal>> watchAllGoals();

  /// Deletes every `GOAL` row — Story 6.3's Reset/Erase-All (FR-36), always
  /// called last inside `GoalService.resetAll()`'s transaction since
  /// `GoalVersions`/`GoalLogs`/`BlackoutDates`/`CheatDays` all reference
  /// `Goals` by id.
  Future<void> deleteAll();
}
