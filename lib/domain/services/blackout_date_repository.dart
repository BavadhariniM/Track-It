import '../entities/blackout_date.dart';

/// Domain-defined, Drift-agnostic interface. Implemented by
/// `DriftBlackoutDateRepository` in `data/repositories/` (AD-1).
abstract interface class BlackoutDateRepository {
  Future<void> insertBlackoutDate(BlackoutDate blackoutDate);

  /// Inserts [blackoutDate], or updates the existing row sharing its `id` in
  /// place — Story 6.2's JSON import upsert, which must preserve the file's
  /// original `id` rather than minting a fresh one the way
  /// [insertBlackoutDate]'s callers (`GoalService.markBlackoutDate`) do.
  Future<void> upsertBlackoutDate(BlackoutDate blackoutDate);

  /// Every `BlackoutDate` for [goalId], unordered — `GoalService.markDnf`'s
  /// (Story 2.5) one-shot `evaluate()` input.
  Future<List<BlackoutDate>> findAllForGoal(String goalId);

  Stream<List<BlackoutDate>> watchBlackoutDatesForGoal(String goalId);

  /// Deletes every `BLACKOUT_DATE` row — Story 6.3's Reset/Erase-All (FR-36).
  Future<void> deleteAll();
}
