/// String values for [GoalVersion]'s rule fields. These fields are typed as
/// plain strings (not enums) per the architecture ER diagram, since later
/// stories widen what each field can encode (custom recurrence, arbitrary
/// eligible-day selections, range comparisons) without a schema change.
/// Only the values needed through Story 1.1 are declared here.
library;

/// Values for [GoalVersion.evaluationPeriod].
abstract final class EvaluationPeriod {
  static const daily = 'daily';
  static const weekly = 'weekly';

  /// Two-week blocks anchored to the Goal's start date (Story 1.3 Dev
  /// Notes — no other anchor point is specified anywhere in the PRD).
  static const biweekly = 'biweekly';
  static const monthly = 'monthly';
  static const quarterly = 'quarterly';
  static const yearly = 'yearly';

  /// Story 1.5 (Custom Recurrence Patterns) fully populates this case;
  /// Story 1.3 only reserves the name so `evaluate()`'s shape doesn't need
  /// to change when Story 1.5 lands.
  static const custom = 'custom';

  static const _rollingWindowPrefix = 'rolling_window:';

  /// A trailing-N-day rolling window with no fixed calendar boundary — it
  /// is always "the trailing N days ending on the evaluation date."
  static String rollingWindow(int days) => '$_rollingWindowPrefix$days';

  static bool isRollingWindow(String evaluationPeriod) =>
      evaluationPeriod.startsWith(_rollingWindowPrefix);

  static int rollingWindowDays(String evaluationPeriod) =>
      int.parse(evaluationPeriod.substring(_rollingWindowPrefix.length));
}

/// [GoalVersion.eligibleDaysRule] is stored as a comma-separated list of
/// ISO weekday numbers (Mon=1..Sun=7, matching `DateTime.weekday`) — the
/// **one** underlying mechanism for every preset (FR-8 consequence):
/// "Workdays"/"Weekends"/"Every day" are just precomputed weekday sets
/// built the same way an arbitrary picker builds one, never a separate
/// stored rule-type enum.
abstract final class EligibleDaysRule {
  static const everyDay = '1,2,3,4,5,6,7';
  static const workdays = '1,2,3,4,5';
  static const weekends = '6,7';

  static String fromWeekdays(Set<int> weekdays) {
    final sorted = weekdays.toList()..sort();
    return sorted.join(',');
  }

  static Set<int> toWeekdays(String eligibleDaysRule) {
    if (eligibleDaysRule.isEmpty) return {};
    return eligibleDaysRule.split(',').map(int.parse).toSet();
  }

  /// `isoWeekday` matches `DateTime.weekday` (Mon=1..Sun=7).
  static bool isEligible(String eligibleDaysRule, int isoWeekday) {
    return toWeekdays(eligibleDaysRule).contains(isoWeekday);
  }
}

/// Values for [GoalVersion.targetComparison]. Complete per FR-11: At Least,
/// At Most, Exactly — deliberately no `Range(min, max)` variant combining a
/// floor and ceiling on one Goal (product decision). All three are valid
/// for both `boolean` and `counter` Tracking Types (FR-11); the comparison
/// predicate (`evaluate.dart`'s `_meetsTarget`) is one shared function that
/// doesn't know or care which Tracking Type or period type produced the
/// number it's comparing (FR-12 axis independence).
abstract final class TargetComparison {
  static const exactly = 'exactly';
  static const atLeast = 'at_least';
  static const atMost = 'at_most';
}

/// Values for [GoalVersion.trackingType].
abstract final class TrackingType {
  static const boolean = 'boolean';

  /// Sums logged `GoalLog.value`s within the period (Stories 1.2/1.3).
  static const counter = 'counter';

  /// Counts *how many eligible days* had a Counter entry logged as done
  /// (`GoalLog.completed`), rather than summing values — a real, distinct
  /// mode the PRD's worked-example table draws (e.g. "Gym 3x/week": a
  /// Weekly goal counting done-days, not summing reps). Shares its
  /// aggregation with `boolean`'s day-counting, not `counter`'s summing.
  static const counterDoneCount = 'counter_done_count';
}
