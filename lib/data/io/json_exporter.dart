import 'dart:convert';

import '../../domain/entities/blackout_date.dart';
import '../../domain/entities/cheat_day.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_log.dart';
import '../../domain/entities/goal_version.dart';
import '../../domain/evaluator/period_boundary.dart';
import '../../domain/services/blackout_date_repository.dart';
import '../../domain/services/cheat_day_repository.dart';
import '../../domain/services/goal_filter.dart';
import '../../domain/services/goal_log_repository.dart';
import '../../domain/services/goal_repository.dart';
import '../../domain/services/goal_version_repository.dart';
import '../../domain/services/reminder_settings_repository.dart';
import '../../domain/services/week_start_settings_repository.dart';

/// Story 6.1's export schema version (FR-33). Story 6.2's import validator
/// checks this exact field for presence and exact-match support — keep the
/// field name (`schemaVersion`), its location (nested under `meta`), and
/// this value's format stable; Story 6.2 was written against this contract
/// (Dev Notes: "load-bearing for Story 6.2").
const exportSchemaVersion = '1.0';

/// Serializes the app's full portable state to a single JSON document
/// (FR-33/AC #1). Depends only on domain-defined, read-only repository
/// interfaces — never `GoalService` or any write-capable API (AC #3), so
/// export is provably a read-only operation — and performs no I/O beyond
/// those reads, so it is inherently offline (AC #4, NFR-1/NFR-2).
///
/// Exports every field the domain entities actually carry, including
/// `Goal.description`/`Goal.endDate` (Story 1.9) and
/// `GoalVersion.isPaused` (Story 2.2) — real persisted state that postdates
/// ARCHITECTURE-SPINE.md's original `erDiagram` field lists, but which a
/// "full app state" backup (AC #1: "containing all of it") must not
/// silently drop.
class JsonExporter {
  JsonExporter({
    required GoalRepository goalRepository,
    required GoalVersionRepository goalVersionRepository,
    required GoalLogRepository goalLogRepository,
    required CheatDayRepository cheatDayRepository,
    required BlackoutDateRepository blackoutDateRepository,
    required ReminderSettingsRepository reminderSettingsRepository,
    required WeekStartSettingsRepository weekStartSettingsRepository,
  }) : _goalRepository = goalRepository,
       _goalVersionRepository = goalVersionRepository,
       _goalLogRepository = goalLogRepository,
       _cheatDayRepository = cheatDayRepository,
       _blackoutDateRepository = blackoutDateRepository,
       _reminderSettingsRepository = reminderSettingsRepository,
       _weekStartSettingsRepository = weekStartSettingsRepository;

  final GoalRepository _goalRepository;
  final GoalVersionRepository _goalVersionRepository;
  final GoalLogRepository _goalLogRepository;
  final CheatDayRepository _cheatDayRepository;
  final BlackoutDateRepository _blackoutDateRepository;
  final ReminderSettingsRepository _reminderSettingsRepository;
  final WeekStartSettingsRepository _weekStartSettingsRepository;

  /// Assembles the export model from repository reads and serializes it to
  /// a pretty-printed JSON string.
  Future<String> exportToJson() async {
    final model = await buildExportModel();
    return const JsonEncoder.withIndent('  ').convert(model);
  }

  /// Assembles the export model as a plain, `jsonEncode`-able `Map` —
  /// exposed separately from [exportToJson] so tests can assert on the
  /// structured shape directly rather than re-parsing a JSON string.
  Future<Map<String, dynamic>> buildExportModel() async {
    final goals = await _goalRepository.watchAllGoals().first;

    final goalVersions = <Map<String, dynamic>>[];
    final goalLogs = <Map<String, dynamic>>[];
    final cheatDays = <Map<String, dynamic>>[];
    final blackoutDates = <Map<String, dynamic>>[];

    for (final goal in goals) {
      goalVersions.addAll(
        (await _goalVersionRepository.findAllForGoal(
          goal.id,
        )).map(_versionToJson),
      );
      goalLogs.addAll(
        (await _goalLogRepository.findAllForGoal(goal.id)).map(_logToJson),
      );
      cheatDays.addAll(
        (await _cheatDayRepository.findAllForGoal(
          goal.id,
        )).map(_cheatDayToJson),
      );
      blackoutDates.addAll(
        (await _blackoutDateRepository.findAllForGoal(
          goal.id,
        )).map(_blackoutDateToJson),
      );
    }

    final reminderTime = await _reminderSettingsRepository.getReminderTime();
    // Unset persists as `null`; the live default (Monday, per FR-24) applies
    // until Panda changes it, so an unset setting exports as that same
    // default rather than an ambiguous `null`.
    final weekStart =
        await _weekStartSettingsRepository.getWeekStart() ?? WeekStart.monday;

    return {
      'meta': {
        'schemaVersion': exportSchemaVersion,
        'exportedAt': DateTime.now().toIso8601String(),
      },
      'goals': goals.map(_goalToJson).toList(),
      'goalVersions': goalVersions,
      'goalLogs': goalLogs,
      'cheatDays': cheatDays,
      'blackoutDates': blackoutDates,
      // No separate Category table/id exists in this codebase (categories
      // are free-text on `Goal.category`) — the category name doubles as
      // its own `id` since nothing else is available to key on.
      'categories': distinctCategories(
        goals,
      ).map((category) => {'id': category, 'name': category}).toList(),
      'settings': {
        'weekStartDay': weekStart.name,
        'reminderTime': reminderTime?.toString(),
      },
    };
  }

  Map<String, dynamic> _goalToJson(Goal goal) => {
    'id': goal.id,
    'name': goal.name,
    'description': goal.description,
    'category': goal.category,
    'archived': goal.archived,
    'startDate': goal.startDate,
    'endDate': goal.endDate,
  };

  Map<String, dynamic> _versionToJson(GoalVersion version) => {
    'id': version.id,
    'goalId': version.goalId,
    'versionStartDate': version.versionStartDate,
    'evaluationPeriod': version.evaluationPeriod,
    'eligibleDaysRule': version.eligibleDaysRule,
    'targetComparison': version.targetComparison,
    'targetValue': version.targetValue,
    'trackingType': version.trackingType,
    'cheatDayQuota': version.cheatDayQuota,
    'isPaused': version.isPaused,
  };

  Map<String, dynamic> _logToJson(GoalLog log) => {
    'id': log.id,
    'goalId': log.goalId,
    'date': log.date,
    'timestamp': log.timestamp,
    'value': log.value,
    'completed': log.completed,
    'dnfMarked': log.dnfMarked,
    'note': log.note,
  };

  Map<String, dynamic> _cheatDayToJson(CheatDay cheatDay) => {
    'id': cheatDay.id,
    'goalId': cheatDay.goalId,
    'date': cheatDay.date,
    'note': cheatDay.note,
  };

  Map<String, dynamic> _blackoutDateToJson(BlackoutDate blackoutDate) => {
    'id': blackoutDate.id,
    'goalId': blackoutDate.goalId,
    'date': blackoutDate.date,
    'reason': blackoutDate.reason,
  };
}
