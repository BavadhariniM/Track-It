/// The five-state status vocabulary rendered by the `status-cell`/badge
/// component (UX-DR6). Only `success` is exercised by Story 1.1's Daily
/// Boolean case; the rest are exercised by later stories (1.4, 1.8) but the
/// enum is complete from day one so `status_cell.dart` never needs rework.
enum DayStatusValue { success, fail, cheat, empty, pending }

/// The result of evaluating one [Goal] for one calendar date. Returned by
/// the pure `evaluate()` function (AD-4). Kept extensible with optional
/// progress-context fields since Story 1.2 onward (Counter goals) render a
/// progress bar / fraction against this same shape rather than a new one.
class DayStatus {
  const DayStatus({
    required this.goalId,
    required this.date,
    required this.status,
    this.currentValue,
    this.targetValue,
  });

  /// FK to [Goal.id].
  final String goalId;

  /// Naive ISO-8601 date-only string (`YYYY-MM-DD`).
  final String date;

  final DayStatusValue status;

  /// Progress context for count-based (Counter) goals; unused by this
  /// story's Boolean case.
  final double? currentValue;

  final double? targetValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayStatus &&
          runtimeType == other.runtimeType &&
          goalId == other.goalId &&
          date == other.date &&
          status == other.status &&
          currentValue == other.currentValue &&
          targetValue == other.targetValue;

  @override
  int get hashCode =>
      Object.hash(goalId, date, status, currentValue, targetValue);

  @override
  String toString() =>
      'DayStatus(goalId: $goalId, date: $date, status: $status, '
      'currentValue: $currentValue, targetValue: $targetValue)';
}
