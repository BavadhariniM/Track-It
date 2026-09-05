import '../date_validation.dart';

/// Subtask 2.6 (AC #7): confirms every date field is a valid naive
/// ISO-8601 date-only string (`YYYY-MM-DD`) and internally consistent (a
/// GoalVersion's `versionStartDate` not before its own Goal's `startDate`,
/// checked only when that Goal is present in this same file — a Goal that
/// only exists in local data is out of scope for this check). Names the
/// specific invalid date field on failure (UX-DR19).
class DateValidityCheck {
  const DateValidityCheck();

  String? check(Map<String, dynamic> json) {
    final goalStartDatesById = <String, String>{};
    for (final goal in (json['goals'] as List? ?? const [])) {
      if (goal is! Map) continue;
      final id = goal['id'];
      final startDate = goal['startDate'];
      if (startDate is! String || !isValidDateOnly(startDate)) {
        return 'Goal "$id" has an invalid startDate: "$startDate".';
      }
      final endDate = goal['endDate'];
      if (endDate != null &&
          (endDate is! String || !isValidDateOnly(endDate))) {
        return 'Goal "$id" has an invalid endDate: "$endDate".';
      }
      if (id is String) goalStartDatesById[id] = startDate;
    }

    for (final version in (json['goalVersions'] as List? ?? const [])) {
      if (version is! Map) continue;
      final versionStartDate = version['versionStartDate'];
      if (versionStartDate is! String ||
          !isValidDateOnly(versionStartDate)) {
        return 'GoalVersion "${version['id']}" has an invalid '
            'versionStartDate: "$versionStartDate".';
      }
      final goalStartDate = goalStartDatesById[version['goalId']];
      if (goalStartDate != null &&
          versionStartDate.compareTo(goalStartDate) < 0) {
        return 'GoalVersion "${version['id']}" starts before its Goal\'s '
            'startDate.';
      }
    }

    for (final entry in const {
      'goalLogs': 'GoalLog',
      'cheatDays': 'CheatDay',
      'blackoutDates': 'BlackoutDate',
    }.entries) {
      for (final item in (json[entry.key] as List? ?? const [])) {
        if (item is! Map) continue;
        final date = item['date'];
        if (date is! String || !isValidDateOnly(date)) {
          return '${entry.value} "${item['id']}" has an invalid date: '
              '"$date".';
        }
      }
    }
    return null;
  }
}
