import '../entities/eligible_days_rule.dart';
import '../entities/goal_version.dart';
import '../entities/rule_values.dart';
import '../evaluator/date_format.dart';

/// Cheap presentation-layer pre-check (Story 2.2 Subtask 3.3): whether
/// [date] falls under a paused Version in this goal's [versions] history.
/// Presentation calls this **before** deciding whether to render a
/// goal-row/status-cell for a specific `(goal, date)` pair on the
/// Day/Week/Month calendar — a paused date is omitted entirely rather than
/// rendered as any of the five `status-cell` colors (AC 2). This is a
/// per-day rendering convenience only: it does not feed into `evaluate()`
/// and does not duplicate its *period*-level eligible-day-pool exclusion
/// (`evaluate()`, Story 1.1/1.3, independently excludes paused dates from a
/// period's pool for rollups/streaks/stats) — it answers a narrower, purely
/// cosmetic question ("should this row render today?") that `evaluate()`
/// was never asked.
bool isPausedOn(List<GoalVersion> versions, String date) {
  GoalVersion? governing;
  final sorted = [...versions]
    ..sort((a, b) => a.versionStartDate.compareTo(b.versionStartDate));
  for (final version in sorted) {
    if (version.versionStartDate.compareTo(date) <= 0) {
      governing = version;
    } else {
      break;
    }
  }
  return governing?.isPaused ?? false;
}

/// Cheap presentation-layer pre-check, mirroring [isPausedOn]: whether a
/// Daily-period goal's own weekday/recurrence rule excludes [date] — the
/// literal "not scheduled for this day" case (Bug 7). Deliberately narrower
/// than `DayStatus.status == empty`: blackout dates and period-type goals
/// (e.g. a Weekly "5x/week" goal on a non-eligible day within its period)
/// both also produce an `empty`/aggregate status through different paths,
/// but neither is "this goal's rule excludes this date" — blackout-empty
/// must stay visible (spec-bug5) and a period-type goal's non-eligible days
/// intentionally still show the period's aggregate (`evaluate()`'s
/// `_evaluatePeriod`), so this predicate only ever answers the Daily case.
bool isIneligibleDailyDayOn(
  List<GoalVersion> versions,
  DateTime date,
  DateTime goalStartDate,
) {
  GoalVersion? governing;
  final sorted = [...versions]
    ..sort((a, b) => a.versionStartDate.compareTo(b.versionStartDate));
  final dateStr = formatDateOnly(date);
  for (final version in sorted) {
    if (version.versionStartDate.compareTo(dateStr) <= 0) {
      governing = version;
    } else {
      break;
    }
  }
  if (governing == null || governing.evaluationPeriod != EvaluationPeriod.daily) {
    return false;
  }
  return !EligibleDaysPattern.decode(
    governing.eligibleDaysRule,
  ).isEligible(date: date, goalStartDate: goalStartDate);
}
