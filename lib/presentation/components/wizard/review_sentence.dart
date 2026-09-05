import 'package:flutter/foundation.dart';

import '../../../domain/entities/eligible_days_rule.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/entities/goal_version.dart';
import '../../../domain/entities/rule_values.dart';
import '../../providers/goal_wizard_provider.dart';

/// Builds a throwaway [GoalWizardState] from a [goal]/[version] pair purely
/// to reuse [buildReviewSentence]'s plain-language composition (UX-DR15) for
/// a Version's rules — the same phrasing the wizard itself shows on Review.
/// Reused by Goal Detail's current-Version summary (Story 2.1) and by the
/// Version Timeline's tapped-segment detail for an arbitrary past Version
/// (Story 3.2 Subtask 4.2), rather than a second sentence-builder.
GoalWizardState wizardStateForVersion(Goal goal, GoalVersion version) {
  final isRolling = EvaluationPeriod.isRollingWindow(version.evaluationPeriod);
  return GoalWizardState(
    startDate: DateTime.parse(version.versionStartDate),
    endDate: goal.endDate == null ? null : DateTime.parse(goal.endDate!),
    trackingType: version.trackingType,
    evaluationPeriodKind: isRolling
        ? WizardEvaluationPeriodKind.rollingWindow
        : version.evaluationPeriod,
    rollingWindowDays: isRolling
        ? EvaluationPeriod.rollingWindowDays(version.evaluationPeriod)
        : 7,
    eligibleDaysPattern: EligibleDaysPattern.decode(version.eligibleDaysRule),
    targetComparison: version.targetComparison,
    targetValueText: version.targetValue,
    cheatDayQuota: version.cheatDayQuota,
  );
}

/// Subtask 8.1: composes the wizard's collected answers into one
/// plain-language sentence for the Review step (UX-DR15's own example:
/// "Done at least 3 times a week, workdays only, starting Aug 18"). A pure
/// presentation-layer string-composition function, isolated so it's easy
/// to extend as new schedule/target combinations are added — not a domain
/// concern.
String buildReviewSentence(GoalWizardState state) {
  final parts = <String>[
    _comparisonPhrase(state),
    ?_eligibleDaysPhrase(state.eligibleDaysPattern),
    _datesPhrase(state.startDate, state.endDate),
  ];
  return '${parts.join(', ')}.';
}

String _comparisonPhrase(GoalWizardState state) {
  final value = state.effectiveTargetValueText;
  final comparison = state.effectiveTargetComparison;

  if (state.isFixedBooleanDaily) {
    return 'Done each eligible day';
  }

  final isDaily =
      state.evaluationPeriodKind == WizardEvaluationPeriodKind.daily;

  if (isDaily) {
    // A Counter goal on a Daily period: the value is a per-day amount, not
    // a count of days.
    return switch (comparison) {
      TargetComparison.atLeast => 'At least $value per day',
      TargetComparison.atMost => 'At most $value per day',
      TargetComparison.exactly => 'Exactly $value per day',
      _ => 'At least $value per day',
    };
  }

  final periodLabel = _periodLabel(state);
  return switch (comparison) {
    TargetComparison.atLeast => 'Done at least $value times $periodLabel',
    TargetComparison.atMost => 'Done at most $value times $periodLabel',
    TargetComparison.exactly => 'Done exactly $value times $periodLabel',
    _ => 'Done at least $value times $periodLabel',
  };
}

String _periodLabel(GoalWizardState state) {
  return switch (state.evaluationPeriodKind) {
    WizardEvaluationPeriodKind.weekly => 'a week',
    WizardEvaluationPeriodKind.biweekly => 'every two weeks',
    WizardEvaluationPeriodKind.monthly => 'a month',
    WizardEvaluationPeriodKind.quarterly => 'a quarter',
    WizardEvaluationPeriodKind.yearly => 'a year',
    WizardEvaluationPeriodKind.rollingWindow =>
      'in any ${state.rollingWindowDays} days',
    _ => 'a week',
  };
}

String? _eligibleDaysPhrase(EligibleDaysPattern pattern) {
  return switch (pattern) {
    WeekdaySet(weekdays: final weekdays) => _weekdaySetPhrase(weekdays),
    EveryNDays(n: final n) => 'every $n days',
    EveryNWeeks(n: final n, weekdays: final weekdays) =>
      'every $n weeks on ${_weekdayNames(weekdays)}',
    EveryNMonths(n: final n) => 'every $n months',
    DayOfMonth(daysOfMonth: final days) =>
      'on day ${_sortedJoin(days)} of the month',
    NthWeekdayOfMonth(nth: final nth, weekday: final weekday) =>
      'on the ${_ordinal(nth)} ${_weekdayName(weekday)} of the month',
    CustomDates(dates: final dates) =>
      'on ${dates.length} specific ${dates.length == 1 ? 'date' : 'dates'}',
  };
}

String? _weekdaySetPhrase(Set<int> weekdays) {
  if (setEquals(weekdays, {1, 2, 3, 4, 5, 6, 7})) return null;
  if (setEquals(weekdays, {1, 2, 3, 4, 5})) return 'workdays only';
  if (setEquals(weekdays, {6, 7})) return 'weekends only';
  if (weekdays.isEmpty) return null;
  return 'on ${_weekdayNames(weekdays)}';
}

String _weekdayNames(Set<int> weekdays) {
  const names = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };
  final sorted = weekdays.toList()..sort();
  return sorted.map((d) => names[d] ?? '?').join('/');
}

String _weekdayName(int weekday) {
  const names = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };
  return names[weekday] ?? 'day';
}

String _sortedJoin(Set<int> days) {
  final sorted = days.toList()..sort();
  return sorted.join(', ');
}

String _ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatMonthDay(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.day}';

String _datesPhrase(DateTime startDate, DateTime? endDate) {
  final start = 'starting ${_formatMonthDay(startDate)}';
  if (endDate == null) return start;
  return '$start, ending ${_formatMonthDay(endDate)}';
}
