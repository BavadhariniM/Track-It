import '../../../domain/entities/blackout_date.dart';
import '../../../domain/entities/cheat_day.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/entities/goal_log.dart';
import '../../../domain/entities/goal_version.dart';
import '../../../domain/entities/time_of_day_value.dart';
import '../../../domain/evaluator/period_boundary.dart';

/// The typed, in-memory form of a validated import file — Story 6.1's export
/// schema deserialized field-for-field back into the same domain entities
/// [json_exporter.dart] serializes from (Subtask 1.1: the import deserializer
/// expects exactly the shape the exporter produces). Only ever constructed
/// after every rejection check in the validation pipeline has already
/// passed — see `json_import_validator.dart`.
class ParsedImportFile {
  const ParsedImportFile({
    required this.goals,
    required this.goalVersions,
    required this.goalLogs,
    required this.cheatDays,
    required this.blackoutDates,
    required this.weekStart,
    required this.reminderTime,
  });

  final List<Goal> goals;
  final List<GoalVersion> goalVersions;
  final List<GoalLog> goalLogs;
  final List<CheatDay> cheatDays;
  final List<BlackoutDate> blackoutDates;
  final WeekStart? weekStart;
  final TimeOfDayValue? reminderTime;

  factory ParsedImportFile.fromJson(Map<String, dynamic> json) {
    final settings = (json['settings'] as Map?) ?? const {};
    return ParsedImportFile(
      goals: [
        for (final g in (json['goals'] as List)) _goalFromJson(g as Map),
      ],
      goalVersions: [
        for (final v in (json['goalVersions'] as List))
          _versionFromJson(v as Map),
      ],
      goalLogs: [
        for (final l in (json['goalLogs'] as List)) _logFromJson(l as Map),
      ],
      cheatDays: [
        for (final c in (json['cheatDays'] as List))
          _cheatDayFromJson(c as Map),
      ],
      blackoutDates: [
        for (final b in (json['blackoutDates'] as List))
          _blackoutDateFromJson(b as Map),
      ],
      weekStart: _weekStartFromJson(settings['weekStartDay']),
      reminderTime: _reminderTimeFromJson(settings['reminderTime']),
    );
  }

  static Goal _goalFromJson(Map json) => Goal(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    category: json['category'] as String?,
    archived: json['archived'] as bool? ?? false,
    startDate: json['startDate'] as String,
    endDate: json['endDate'] as String?,
  );

  static GoalVersion _versionFromJson(Map json) => GoalVersion(
    id: json['id'] as String,
    goalId: json['goalId'] as String,
    versionStartDate: json['versionStartDate'] as String,
    evaluationPeriod: json['evaluationPeriod'] as String,
    eligibleDaysRule: json['eligibleDaysRule'] as String,
    targetComparison: json['targetComparison'] as String,
    targetValue: json['targetValue'] as String,
    trackingType: json['trackingType'] as String,
    cheatDayQuota: (json['cheatDayQuota'] as num?)?.toInt() ?? 0,
    isPaused: json['isPaused'] as bool? ?? false,
  );

  static GoalLog _logFromJson(Map json) => GoalLog(
    id: json['id'] as String,
    goalId: json['goalId'] as String,
    date: json['date'] as String,
    timestamp: json['timestamp'] as String,
    value: (json['value'] as num).toDouble(),
    completed: json['completed'] as bool,
    dnfMarked: json['dnfMarked'] as bool? ?? false,
    note: json['note'] as String?,
  );

  static CheatDay _cheatDayFromJson(Map json) => CheatDay(
    id: json['id'] as String,
    goalId: json['goalId'] as String,
    date: json['date'] as String,
    note: json['note'] as String?,
  );

  static BlackoutDate _blackoutDateFromJson(Map json) => BlackoutDate(
    id: json['id'] as String,
    goalId: json['goalId'] as String,
    date: json['date'] as String,
    reason: json['reason'] as String?,
  );

  static WeekStart? _weekStartFromJson(Object? value) {
    if (value is! String) return null;
    for (final weekStart in WeekStart.values) {
      if (weekStart.name == value) return weekStart;
    }
    return null;
  }

  static TimeOfDayValue? _reminderTimeFromJson(Object? value) {
    if (value is! String) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDayValue(hour: hour, minute: minute);
  }
}
