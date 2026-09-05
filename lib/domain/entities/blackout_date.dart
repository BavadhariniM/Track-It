/// A direct `evaluate()` input (AD-4): FR-10 requires Blackout Dates to
/// exempt a date without changing the eligible-day count. Minimal entity
/// only — full exemption *behavior* is Story 1.6; this story only needs
/// the type to exist so `evaluate()`'s full AD-4 signature can be
/// finalized (it always receives an empty list until Story 1.6 lands).
class BlackoutDate {
  const BlackoutDate({
    required this.id,
    required this.goalId,
    required this.date,
    this.reason,
  });

  final String id;
  final String goalId;

  /// Naive ISO-8601 date-only string (`YYYY-MM-DD`).
  final String date;

  final String? reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlackoutDate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          goalId == other.goalId &&
          date == other.date &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(id, goalId, date, reason);
}
