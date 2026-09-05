import 'rule_values.dart';

/// The parsed, structured form of [GoalVersion.eligibleDaysRule]'s raw
/// string. Story 1.4's plain weekday-set case ([WeekdaySet]) and this
/// story's custom recurrence variants are all cases of this one type,
/// consumed by one eligibility predicate inside `evaluate()` (AD-4) — never
/// a second "custom recurrence evaluator."
///
/// Two opposite anchoring rules, easy to conflate (Story 1.5 Dev Notes):
/// - [EveryNDays]/[EveryNWeeks]/[EveryNMonths] anchor to `goalStartDate`,
///   fixed forever — never re-anchored by other edits (FR-9).
/// - [NthWeekdayOfMonth] is computed fresh per calendar month, with no
///   dependency on `goalStartDate` at all (FR-9 consequence).
sealed class EligibleDaysPattern {
  const EligibleDaysPattern();

  static const _everyNDaysPrefix = 'every_n_days:';
  static const _everyNWeeksPrefix = 'every_n_weeks:';
  static const _everyNMonthsPrefix = 'every_n_months:';
  static const _dayOfMonthPrefix = 'day_of_month:';
  static const _nthWeekdayPrefix = 'nth_weekday:';
  static const _customDatesPrefix = 'custom_dates:';

  /// Parses the raw Drift/entity string. Anything not matching a
  /// recognized prefix is treated as Story 1.4's bare weekday-set CSV
  /// (`"1,2,3"`) — this keeps every rule constructed before this story
  /// (including `EligibleDaysRule.everyDay`/`workdays`/`weekends`) reading
  /// back correctly with no migration.
  factory EligibleDaysPattern.decode(String value) {
    if (value.startsWith(_everyNDaysPrefix)) {
      return EveryNDays(int.parse(value.substring(_everyNDaysPrefix.length)));
    }
    if (value.startsWith(_everyNWeeksPrefix)) {
      final parts = value.substring(_everyNWeeksPrefix.length).split(':');
      return EveryNWeeks(
        int.parse(parts[0]),
        parts[1].split(',').map(int.parse).toSet(),
      );
    }
    if (value.startsWith(_everyNMonthsPrefix)) {
      return EveryNMonths(
        int.parse(value.substring(_everyNMonthsPrefix.length)),
      );
    }
    if (value.startsWith(_dayOfMonthPrefix)) {
      return DayOfMonth(
        value
            .substring(_dayOfMonthPrefix.length)
            .split(',')
            .map(int.parse)
            .toSet(),
      );
    }
    if (value.startsWith(_nthWeekdayPrefix)) {
      final parts = value.substring(_nthWeekdayPrefix.length).split(':');
      return NthWeekdayOfMonth(int.parse(parts[0]), int.parse(parts[1]));
    }
    if (value.startsWith(_customDatesPrefix)) {
      return CustomDates(
        value.substring(_customDatesPrefix.length).split(',').toSet(),
      );
    }
    return WeekdaySet(EligibleDaysRule.toWeekdays(value));
  }

  String encode();

  /// [goalStartDate] is `Goal.startDate` — never `GoalVersion
  /// .versionStartDate` — for the anchored variants (FR-9).
  bool isEligible({required DateTime date, required DateTime goalStartDate});
}

/// Story 1.4's plain weekday-set case.
final class WeekdaySet extends EligibleDaysPattern {
  const WeekdaySet(this.weekdays);

  final Set<int> weekdays;

  @override
  String encode() => EligibleDaysRule.fromWeekdays(weekdays);

  @override
  bool isEligible({required DateTime date, required DateTime goalStartDate}) {
    return weekdays.contains(date.weekday);
  }
}

/// "Every N days," anchored to `goalStartDate` (AC #1).
final class EveryNDays extends EligibleDaysPattern {
  const EveryNDays(this.n);

  final int n;

  @override
  String encode() => '${EligibleDaysPattern._everyNDaysPrefix}$n';

  @override
  bool isEligible({required DateTime date, required DateTime goalStartDate}) {
    final anchor = _dateOnly(goalStartDate);
    final d = _dateOnly(date);
    final diff = d.difference(anchor).inDays;
    return diff >= 0 && diff % n == 0;
  }
}

/// "Every N weeks on specific weekdays," anchored to the Monday-based week
/// containing `goalStartDate` (AC #2).
final class EveryNWeeks extends EligibleDaysPattern {
  const EveryNWeeks(this.n, this.weekdays);

  final int n;
  final Set<int> weekdays;

  @override
  String encode() {
    final sortedWeekdays = weekdays.toList()..sort();
    return '${EligibleDaysPattern._everyNWeeksPrefix}$n:${sortedWeekdays.join(',')}';
  }

  @override
  bool isEligible({required DateTime date, required DateTime goalStartDate}) {
    if (!weekdays.contains(date.weekday)) return false;
    final weeksSince =
        _mondayOfWeek(date).difference(_mondayOfWeek(goalStartDate)).inDays ~/
        7;
    return weeksSince >= 0 && weeksSince % n == 0;
  }
}

/// "Every N months," on the same day-of-month as `goalStartDate` (AC #2).
/// A month that has no such day (e.g. day 31 in April) simply never
/// contains an eligible date that month — no clamped fallback.
final class EveryNMonths extends EligibleDaysPattern {
  const EveryNMonths(this.n);

  final int n;

  @override
  String encode() => '${EligibleDaysPattern._everyNMonthsPrefix}$n';

  @override
  bool isEligible({required DateTime date, required DateTime goalStartDate}) {
    if (date.day != goalStartDate.day) return false;
    final monthsSince =
        (date.year - goalStartDate.year) * 12 +
        (date.month - goalStartDate.month);
    return monthsSince >= 0 && monthsSince % n == 0;
  }
}

/// Specific day(s) of every month (e.g. "the 1st and 15th"). A month
/// shorter than a listed day simply has no date matching it that month —
/// no shift-to-last-day fallback (Story 1.5 Dev Notes open question,
/// resolved this way since neither PRD nor architecture specifies one).
final class DayOfMonth extends EligibleDaysPattern {
  const DayOfMonth(this.daysOfMonth);

  final Set<int> daysOfMonth;

  @override
  String encode() {
    final sorted = daysOfMonth.toList()..sort();
    return '${EligibleDaysPattern._dayOfMonthPrefix}${sorted.join(',')}';
  }

  @override
  bool isEligible({required DateTime date, required DateTime goalStartDate}) {
    return daysOfMonth.contains(date.day);
  }
}

/// "Nth weekday of month" (e.g. 2nd Tuesday) — computed independently per
/// calendar month, deliberately ignoring `goalStartDate` (AC #3).
final class NthWeekdayOfMonth extends EligibleDaysPattern {
  const NthWeekdayOfMonth(this.nth, this.weekday);

  /// 1st, 2nd, 3rd... occurrence of [weekday] within the month.
  final int nth;

  /// ISO weekday (Mon=1..Sun=7), matching `DateTime.weekday`.
  final int weekday;

  @override
  String encode() => '${EligibleDaysPattern._nthWeekdayPrefix}$nth:$weekday';

  @override
  bool isEligible({required DateTime date, required DateTime goalStartDate}) {
    if (date.weekday != weekday) return false;
    final occurrence = ((date.day - 1) ~/ 7) + 1;
    return occurrence == nth;
  }
}

/// An explicit set of specific dates — no calendar-grid computation at all.
final class CustomDates extends EligibleDaysPattern {
  const CustomDates(this.dates);

  /// Naive ISO-8601 date-only strings (`YYYY-MM-DD`).
  final Set<String> dates;

  @override
  String encode() =>
      '${EligibleDaysPattern._customDatesPrefix}${dates.join(',')}';

  @override
  bool isEligible({required DateTime date, required DateTime goalStartDate}) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return dates.contains('$y-$m-$d');
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _mondayOfWeek(DateTime date) {
  final d = _dateOnly(date);
  final diff = d.weekday - DateTime.monday;
  return d.subtract(Duration(days: diff));
}
