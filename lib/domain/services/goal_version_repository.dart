import '../entities/goal_version.dart';

/// Domain-defined, Drift-agnostic interface. Implemented by
/// `DriftGoalVersionRepository` in `data/repositories/` (AD-1).
abstract interface class GoalVersionRepository {
  Future<void> insertVersion(GoalVersion version);

  /// Inserts [version], or updates the existing row sharing its `id` in
  /// place — Story 6.2's JSON import upsert, which must preserve the file's
  /// original `id` rather than minting a fresh one the way [insertVersion]'s
  /// callers (`GoalService._writeVersionSegment`) do.
  Future<void> upsertVersion(GoalVersion version);

  /// Updates the row sharing [version]'s `id` in place — backs Story 2.1's
  /// "same-day edit amends the still-log-free Version" branch of the AD-6
  /// collision algorithm (`GoalService._writeVersionSegment`). Never
  /// changes which row `id` a `versionStartDate` maps to; only mutates
  /// rule columns on the existing row.
  Future<void> updateVersion(GoalVersion version);

  /// The `GoalVersion` for [goalId] whose `versionStartDate` exactly equals
  /// [versionStartDate], or `null` if none exists yet — the AD-6 collision
  /// check's existence read (Story 2.1 Subtask 2.1).
  Future<GoalVersion?> findByGoalIdAndStartDate(
    String goalId,
    String versionStartDate,
  );

  /// The latest `GoalVersion` for [goalId] whose `versionStartDate` is on or
  /// before [date], or `null` if [date] precedes every Version for this
  /// goal — mirrors the evaluator's own governing-Version selection
  /// (`evaluate.dart`'s `_findGoverningVersion`) but on the write side:
  /// `GoalService.pauseGoal`/`resumeGoal` (Story 2.2) use it to copy the
  /// currently-active rule fields forward onto the new/amended paused or
  /// resumed segment.
  Future<GoalVersion?> findGoverningVersion(String goalId, String date);

  /// Every `GoalVersion` for [goalId], unordered — `GoalService.markDnf`'s
  /// (Story 2.5) one-shot `evaluate()` input, the same shape Day/Week/Month
  /// View already stream via [watchVersionsForGoal] (AD-4: no second
  /// evaluate()-input shape).
  Future<List<GoalVersion>> findAllForGoal(String goalId);

  Stream<List<GoalVersion>> watchVersionsForGoal(String goalId);

  /// Deletes every `GOAL_VERSION` row — Story 6.3's Reset/Erase-All (FR-36).
  Future<void> deleteAll();
}
