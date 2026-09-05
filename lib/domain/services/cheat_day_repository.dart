import '../entities/cheat_day.dart';

/// Domain-defined, Drift-agnostic interface. Implemented by
/// `DriftCheatDayRepository` in `data/repositories/` (AD-1).
abstract interface class CheatDayRepository {
  Future<void> insertCheatDay(CheatDay cheatDay);

  /// Inserts [cheatDay], or updates the existing row sharing its `id` in
  /// place — Story 6.2's JSON import upsert, which must preserve the file's
  /// original `id` rather than minting a fresh one the way
  /// [insertCheatDay]'s callers (`GoalService.markCheatDay`) do.
  Future<void> upsertCheatDay(CheatDay cheatDay);

  /// Every `CheatDay` for [goalId] with `date` inside `[startDate, endDate]`
  /// (both inclusive) — `GoalService.markCheatDay`'s quota-usage count for
  /// the Evaluation Period window containing the date being marked.
  Future<List<CheatDay>> findByGoalIdInRange(
    String goalId,
    String startDate,
    String endDate,
  );

  /// Every `CheatDay` for [goalId], unordered — `GoalService.markDnf`'s
  /// (Story 2.5) one-shot `evaluate()` input.
  Future<List<CheatDay>> findAllForGoal(String goalId);

  Stream<List<CheatDay>> watchCheatDaysForGoal(String goalId);

  /// Deletes every `CHEAT_DAY` row — Story 6.3's Reset/Erase-All (FR-36).
  Future<void> deleteAll();
}
