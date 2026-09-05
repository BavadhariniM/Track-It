/// A direct `evaluate()` input (AD-4): FR-4 names Cheat Days as a
/// status-computation input. Minimal entity only — full quota *usage* is
/// Epic 2 Story 2.4; this story only needs the type to exist so
/// `evaluate()`'s full AD-4 signature can be finalized (it always receives
/// an empty list until Story 2.4 lands).
class CheatDay {
  const CheatDay({
    required this.id,
    required this.goalId,
    required this.date,
    this.note,
  });

  final String id;
  final String goalId;

  /// Naive ISO-8601 date-only string (`YYYY-MM-DD`).
  final String date;

  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheatDay &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          goalId == other.goalId &&
          date == other.date &&
          note == other.note;

  @override
  int get hashCode => Object.hash(id, goalId, date, note);
}
