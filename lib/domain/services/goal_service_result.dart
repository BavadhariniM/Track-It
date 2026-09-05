/// A richer, structured-failure-reason `Result`/`Either` type, additive to
/// (not a replacement for) `result.dart`'s plain `Result<T>` — see
/// `goal_service.dart`'s doc comment for the coexistence decision. Every
/// Epic 1 use case (`createGoal`/`logBoolean`/`logCounter`/
/// `markBlackoutDate`) keeps returning `Result<T>` unchanged (already
/// shipped and tested); `GoalServiceResult<T>` is reserved for use cases —
/// starting with `editGoalVersion` — whose failures need to be *matched* on
/// a specific, named reason (UX-DR19) rather than only carrying a display
/// string. Never thrown; always returned (Data conventions).
sealed class GoalServiceResult<T> {
  const GoalServiceResult();

  const factory GoalServiceResult.success(T value) = GoalServiceSuccess<T>;

  const factory GoalServiceResult.failure(GoalServiceFailure reason) =
      GoalServiceFailureResult<T>;
}

final class GoalServiceSuccess<T> extends GoalServiceResult<T> {
  const GoalServiceSuccess(this.value);

  final T value;
}

final class GoalServiceFailureResult<T> extends GoalServiceResult<T> {
  const GoalServiceFailureResult(this.reason);

  final GoalServiceFailure reason;
}

/// Named, structured failure reasons a `GoalServiceResult` can carry.
/// `message` is the exact UX-DR19-compliant copy a screen shows verbatim —
/// specific, no exclamation points, names the exact problem — so
/// presentation never has to re-derive copy from the reason itself.
enum GoalServiceFailure {
  /// AC 4 / AD-6: a same-day edit was attempted against a `GoalVersion` that
  /// already has at least one `GoalLog` on or after its `versionStartDate`.
  /// Panda must choose a later effective date instead.
  versionLocked(
    "This goal already has entries logged under today's version — choose "
    'a later effective date.',
  ),

  /// Story 2.4 AC 4: a Cheat Day was attempted against a goal/period that
  /// has already used its full `cheatDayQuota` for the Evaluation Period
  /// containing the target date.
  cheatDayQuotaExhausted('Cheat Day quota used up for this period.'),

  /// Story 2.5 AC 2/3: a DNF mark was attempted against a date that isn't
  /// currently Pending for this goal — either it was never eligible, or its
  /// Evaluation Period has already resolved to a certain outcome. A DNF
  /// mark on a day that can never show it would be meaningless.
  notEligibleOrAlreadyResolved(
    'This day is not eligible, or its period has already been decided — it '
    'cannot be marked DNF.',
  );

  const GoalServiceFailure(this.message);

  final String message;
}
