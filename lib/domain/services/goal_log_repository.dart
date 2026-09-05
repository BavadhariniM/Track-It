import '../entities/goal_log.dart';

/// Domain-defined, Drift-agnostic interface. Implemented by
/// `DriftGoalLogRepository` in `data/repositories/` (AD-1).
abstract interface class GoalLogRepository {
  Future<void> insertLog(GoalLog log);

  /// Inserts [log], or updates the existing row sharing its `id` in place.
  /// Backs Counter logging's "single running total, no per-increment
  /// timestamp" write strategy (Story 1.2, FR-14): `GoalService.logCounter`
  /// reuses the existing day's row id when one exists via [getLogForDate].
  Future<void> upsertLog(GoalLog log);

  /// The single log row for [goalId] on [date], or `null` if nothing has
  /// been logged that day yet.
  Future<GoalLog?> getLogForDate(String goalId, String date);

  /// Whether any `GoalLog` exists for [goalId] with `date >= date` — the
  /// AD-6 collision algorithm's "does a log already exist against this
  /// Version" check (Story 2.1 Subtask 2.2). A date-range query, not a
  /// foreign-key lookup, since `GOAL_LOG` carries no stored Version FK;
  /// which Version governs a log is resolved at evaluation time by
  /// matching `date` against Version windows.
  Future<bool> existsOnOrAfter(String goalId, String date);

  /// Every `GoalLog` for [goalId], unordered — `GoalService.markDnf`'s
  /// (Story 2.5) one-shot `evaluate()` input.
  Future<List<GoalLog>> findAllForGoal(String goalId);

  Stream<List<GoalLog>> watchLogsForGoal(String goalId);

  /// Deletes every `GOAL_LOG` row — Story 6.3's Reset/Erase-All (FR-36).
  Future<void> deleteAll();

  /// Deletes the single `GOAL_LOG` row with this `id` — Bug 4's "undo a
  /// mistaken Boolean mark-done" write path (`GoalService.undoBooleanLog`).
  /// Retracts the row outright rather than appending an explicit
  /// not-done record, so the day falls back to whatever state preceded it
  /// instead of the evaluator's certain-Fail semantics for an explicit
  /// `completed: false` log.
  Future<void> deleteLog(String id);
}
