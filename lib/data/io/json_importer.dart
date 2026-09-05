import '../../domain/entities/blackout_date.dart';
import '../../domain/entities/cheat_day.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_log.dart';
import '../../domain/entities/goal_version.dart';
import '../../domain/services/blackout_date_repository.dart';
import '../../domain/services/cheat_day_repository.dart';
import '../../domain/services/goal_log_repository.dart';
import '../../domain/services/goal_repository.dart';
import '../../domain/services/goal_service.dart';
import '../../domain/services/goal_version_repository.dart';
import '../../domain/services/reminder_settings_repository.dart';
import '../../domain/services/week_start_settings_repository.dart';
import 'import/conflict_detector.dart';
import 'import/import_conflict.dart';
import 'import/import_outcome.dart';
import 'import/import_validation_result.dart';
import 'import/json_import_validator.dart';
import 'import/parsed_import_file.dart';

/// Story 6.2's top-level import orchestrator (Task 5). Runs the validation
/// pipeline, then conflict detection, then — only once there is nothing left
/// to ask Panda — commits every write. Every write this class issues goes
/// through [GoalService]'s new `importX` methods (AD-6, AC #11); this class
/// itself never calls a repository's insert/update/upsert method directly,
/// the same "no repository shortcut" discipline `JsonExporter` follows for
/// reads.
class JsonImporter {
  JsonImporter({
    required GoalRepository goalRepository,
    required GoalVersionRepository goalVersionRepository,
    required GoalLogRepository goalLogRepository,
    required CheatDayRepository cheatDayRepository,
    required BlackoutDateRepository blackoutDateRepository,
    required GoalService goalService,
    required WeekStartSettingsRepository weekStartSettingsRepository,
    required ReminderSettingsRepository reminderSettingsRepository,
    JsonImportValidator validator = const JsonImportValidator(),
    ConflictDetector conflictDetector = const ConflictDetector(),
  }) : _goalRepository = goalRepository,
       _goalVersionRepository = goalVersionRepository,
       _goalLogRepository = goalLogRepository,
       _cheatDayRepository = cheatDayRepository,
       _blackoutDateRepository = blackoutDateRepository,
       _goalService = goalService,
       _weekStartSettingsRepository = weekStartSettingsRepository,
       _reminderSettingsRepository = reminderSettingsRepository,
       _validator = validator,
       _conflictDetector = conflictDetector;

  final GoalRepository _goalRepository;
  final GoalVersionRepository _goalVersionRepository;
  final GoalLogRepository _goalLogRepository;
  final CheatDayRepository _cheatDayRepository;
  final BlackoutDateRepository _blackoutDateRepository;
  final GoalService _goalService;
  final WeekStartSettingsRepository _weekStartSettingsRepository;
  final ReminderSettingsRepository _reminderSettingsRepository;
  final JsonImportValidator _validator;
  final ConflictDetector _conflictDetector;

  /// Validates [raw], detects conflicts against current local data, and —
  /// if there are none — commits every write and returns
  /// [ImportOutcomeCompleted] directly (AC #10: a no-conflict import is one
  /// single action, not a two-step flow). If there is at least one conflict,
  /// nothing is written yet; the caller must resolve every conflict and call
  /// [completeWithResolutions].
  Future<ImportOutcome> import(String raw) async {
    final localGoals = await _goalRepository.watchAllGoals().first;
    final existingLocalGoalIds = {for (final goal in localGoals) goal.id};

    final validation = _validator.validate(
      raw,
      existingLocalGoalIds: existingLocalGoalIds,
    );
    if (validation is ImportValidationRejected) {
      return ImportOutcomeRejected(validation.reason);
    }
    final valid = validation as ImportValidationValid;

    final detection = await _detectConflicts(valid.file, localGoals);

    if (detection.conflicts.isEmpty) {
      await _commit(file: valid.file, detection: detection);
      return ImportOutcomeCompleted(zeroGoalWarning: valid.zeroGoalWarning);
    }

    return ImportOutcomeNeedsResolution(
      file: valid.file,
      detection: detection,
      zeroGoalWarning: valid.zeroGoalWarning,
    );
  }

  /// Subtask 4.4: called once every conflict in [detection] has an entry in
  /// [resolutions] (keyed by [ImportConflict.resolutionKey]) — partial
  /// resolution commits nothing.
  Future<ImportOutcome> completeWithResolutions({
    required ParsedImportFile file,
    required ConflictDetectionResult detection,
    required Map<String, ConflictChoice> resolutions,
    required bool zeroGoalWarning,
  }) async {
    final unresolved = detection.conflicts.where(
      (c) => !resolutions.containsKey(c.resolutionKey),
    );
    if (unresolved.isNotEmpty) {
      throw StateError(
        'Every conflict must be resolved before an import can complete — '
        'missing: ${unresolved.map((c) => c.resolutionKey).join(', ')}.',
      );
    }

    await _commit(file: file, detection: detection, resolutions: resolutions);
    return ImportOutcomeCompleted(zeroGoalWarning: zeroGoalWarning);
  }

  Future<ConflictDetectionResult> _detectConflicts(
    ParsedImportFile file,
    List<Goal> localGoals,
  ) async {
    final localVersions = <GoalVersion>[];
    final localLogs = <GoalLog>[];
    final localCheatDays = <CheatDay>[];
    final localBlackoutDates = <BlackoutDate>[];
    for (final goal in localGoals) {
      localVersions.addAll(
        await _goalVersionRepository.findAllForGoal(goal.id),
      );
      localLogs.addAll(await _goalLogRepository.findAllForGoal(goal.id));
      localCheatDays.addAll(
        await _cheatDayRepository.findAllForGoal(goal.id),
      );
      localBlackoutDates.addAll(
        await _blackoutDateRepository.findAllForGoal(goal.id),
      );
    }

    return _conflictDetector.detect(
      file: file,
      localGoals: localGoals,
      localVersions: localVersions,
      localLogs: localLogs,
      localCheatDays: localCheatDays,
      localBlackoutDates: localBlackoutDates,
    );
  }

  /// Subtask 5.1/5.2/5.3: writes every non-conflicting entity, then every
  /// conflict resolved as `keepImported` (a `keepMine` resolution is a
  /// no-op — the existing local row is simply left alone), then the
  /// settings the file carries, then [GoalService.finalizeImport]'s
  /// wholesale cache/widget-bridge refresh. Each `importX` call is already
  /// its own Drift transaction (Subtask 5.3) — no single all-encompassing
  /// transaction wraps the whole batch, since validation (already complete
  /// by the time this runs) is what guarantees a rejected file never
  /// reaches here at all.
  Future<void> _commit({
    required ParsedImportFile file,
    required ConflictDetectionResult detection,
    Map<String, ConflictChoice> resolutions = const {},
  }) async {
    for (final goal in detection.newGoals) {
      await _goalService.importGoal(goal);
    }
    for (final version in detection.newGoalVersions) {
      await _goalService.importVersion(version);
    }
    for (final log in detection.newGoalLogs) {
      await _goalService.importLog(log);
    }
    for (final cheatDay in detection.newCheatDays) {
      await _goalService.importCheatDay(cheatDay);
    }
    for (final blackoutDate in detection.newBlackoutDates) {
      await _goalService.importBlackoutDate(blackoutDate);
    }

    for (final conflict in detection.conflicts) {
      if (resolutions[conflict.resolutionKey] != ConflictChoice.keepImported) {
        continue;
      }
      switch (conflict.type) {
        case ImportEntityType.goal:
          await _goalService.importGoal(conflict.imported as Goal);
        case ImportEntityType.goalVersion:
          await _goalService.importVersion(conflict.imported as GoalVersion);
        case ImportEntityType.goalLog:
          await _goalService.importLog(conflict.imported as GoalLog);
        case ImportEntityType.cheatDay:
          await _goalService.importCheatDay(conflict.imported as CheatDay);
        case ImportEntityType.blackoutDate:
          await _goalService.importBlackoutDate(
            conflict.imported as BlackoutDate,
          );
      }
    }

    if (file.weekStart != null) {
      await _weekStartSettingsRepository.setWeekStart(file.weekStart!);
    }
    if (file.reminderTime != null) {
      await _reminderSettingsRepository.setReminderTime(file.reminderTime!);
    }

    await _goalService.finalizeImport();
  }
}
