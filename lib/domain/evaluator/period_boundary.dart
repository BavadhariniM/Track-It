import '../entities/rule_values.dart';

/// Which weekday a Weekly period starts on (FR-24). A simple user setting
/// per AD-3 — `evaluate()` must stay pure, so callers resolve this from
/// `shared_preferences` (or default to [monday] per FR-24) themselves and
/// pass it in as plain data; the evaluator never reads it via I/O.
enum WeekStart { monday, sunday }

/// A concrete `[start, end]` calendar window (inclusive both ends) for the
/// period type governing a date — before any Version-boundary intersection
/// (AD-5), which is the caller's (`evaluate()`'s) job, not this module's.
/// Kept a private-ish helper of the evaluator (Story 1.3 Dev Notes): it has
/// no public evaluation logic of its own, only boundary-shape math.
class PeriodBoundary {
  const PeriodBoundary(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

/// Returns the period boundary containing [date] for [evaluationPeriod].
/// [goalStartDate] anchors Biweekly's two-week blocks (Story 1.3 Dev
/// Notes) — the same anchoring convention Story 1.5's custom recurrence
/// will reuse. NFR-3: pure calendar-date math, no timezone/DST handling.
PeriodBoundary periodBoundaryFor({
  required String evaluationPeriod,
  required DateTime date,
  required DateTime goalStartDate,
  WeekStart weekStart = WeekStart.monday,
}) {
  final d = _dateOnly(date);

  if (evaluationPeriod == EvaluationPeriod.daily) {
    return PeriodBoundary(d, d);
  }
  if (evaluationPeriod == EvaluationPeriod.weekly) {
    return _weeklyBoundary(d, weekStart);
  }
  if (evaluationPeriod == EvaluationPeriod.biweekly) {
    return _anchoredBoundary(d, _dateOnly(goalStartDate), lengthDays: 14);
  }
  if (evaluationPeriod == EvaluationPeriod.monthly) {
    return _monthlyBoundary(d);
  }
  if (evaluationPeriod == EvaluationPeriod.quarterly) {
    return _quarterlyBoundary(d);
  }
  if (evaluationPeriod == EvaluationPeriod.yearly) {
    return PeriodBoundary(DateTime(d.year, 1, 1), DateTime(d.year, 12, 31));
  }
  if (EvaluationPeriod.isRollingWindow(evaluationPeriod)) {
    final windowDays = EvaluationPeriod.rollingWindowDays(evaluationPeriod);
    return PeriodBoundary(d.subtract(Duration(days: windowDays - 1)), d);
  }
  // `custom` (Story 1.5 populates this) and any unrecognized value: a
  // single-day pass-through rather than throwing, per Subtask 2.1.
  return PeriodBoundary(d, d);
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

PeriodBoundary _weeklyBoundary(DateTime d, WeekStart weekStart) {
  final startWeekday = weekStart == WeekStart.monday
      ? DateTime.monday
      : DateTime.sunday;
  final diff = _floorMod(d.weekday - startWeekday, 7);
  final start = d.subtract(Duration(days: diff));
  return PeriodBoundary(start, start.add(const Duration(days: 6)));
}

PeriodBoundary _anchoredBoundary(
  DateTime d,
  DateTime anchor, {
  required int lengthDays,
}) {
  final daysSinceAnchor = d.difference(anchor).inDays;
  final blockIndex = _floorDiv(daysSinceAnchor, lengthDays);
  final start = anchor.add(Duration(days: blockIndex * lengthDays));
  return PeriodBoundary(start, start.add(Duration(days: lengthDays - 1)));
}

PeriodBoundary _monthlyBoundary(DateTime d) {
  final start = DateTime(d.year, d.month, 1);
  final end = DateTime(
    d.year,
    d.month + 1,
    1,
  ).subtract(const Duration(days: 1));
  return PeriodBoundary(start, end);
}

PeriodBoundary _quarterlyBoundary(DateTime d) {
  final quarterStartMonth = ((d.month - 1) ~/ 3) * 3 + 1;
  final start = DateTime(d.year, quarterStartMonth, 1);
  final end = DateTime(
    d.year,
    quarterStartMonth + 3,
    1,
  ).subtract(const Duration(days: 1));
  return PeriodBoundary(start, end);
}

/// Non-negative modulo (Dart's `%` is already Euclidean for this, but named
/// explicitly since correctness here matters for Sunday-start weeks).
int _floorMod(int a, int b) => a % b;

/// Floor division — `~/` truncates toward zero, which is wrong for a
/// negative [a] (a date before the Biweekly anchor); this is exact because
/// `a % b` (Dart's Euclidean modulo, non-negative for positive [b]) is
/// always the correct remainder to subtract first.
int _floorDiv(int a, int b) => (a - a % b) ~/ b;
