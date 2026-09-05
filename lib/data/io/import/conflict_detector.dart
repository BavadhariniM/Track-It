import '../../../domain/entities/blackout_date.dart';
import '../../../domain/entities/cheat_day.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/entities/goal_log.dart';
import '../../../domain/entities/goal_version.dart';
import 'import_conflict.dart';
import 'parsed_import_file.dart';

/// The result of comparing every entity in a [ParsedImportFile] against this
/// device's existing data by id (Task 3 / Subtask 3.1). Three disjoint
/// outcomes per id: absent locally → goes in the `newX` list (written
/// directly, no conflict); present locally with identical content → a
/// silent no-op merge, appears in neither list; present locally with
/// *different* content → an [ImportConflict], routed to resolution.
class ConflictDetectionResult {
  const ConflictDetectionResult({
    required this.conflicts,
    required this.newGoals,
    required this.newGoalVersions,
    required this.newGoalLogs,
    required this.newCheatDays,
    required this.newBlackoutDates,
  });

  final List<ImportConflict> conflicts;
  final List<Goal> newGoals;
  final List<GoalVersion> newGoalVersions;
  final List<GoalLog> newGoalLogs;
  final List<CheatDay> newCheatDays;
  final List<BlackoutDate> newBlackoutDates;
}

/// Subtask 3.1/3.2: for every entity id present in the import file that also
/// exists in local data, compares content — identical content is a silent
/// no-op merge, differing content is a conflict routed to resolution. This
/// is deliberately distinct from `IntraFileDuplicateIdCheck` (Subtask 2.4):
/// a duplicate id *within the file itself* is always a hard rejection
/// (structural corruption); an id shared by the file and local data is a
/// legitimate merge scenario — re-importing a prior backup, or syncing a
/// second device (NFR-4) — never auto-rejected and never auto-merged.
class ConflictDetector {
  const ConflictDetector();

  ConflictDetectionResult detect({
    required ParsedImportFile file,
    required List<Goal> localGoals,
    required List<GoalVersion> localVersions,
    required List<GoalLog> localLogs,
    required List<CheatDay> localCheatDays,
    required List<BlackoutDate> localBlackoutDates,
  }) {
    final goalNamesById = <String, String>{
      for (final g in localGoals) g.id: g.name,
      for (final g in file.goals) g.id: g.name,
    };

    final conflicts = <ImportConflict>[];

    final newGoals = _diff<Goal>(
      fileEntities: file.goals,
      localById: {for (final g in localGoals) g.id: g},
      idOf: (g) => g.id,
      type: ImportEntityType.goal,
      labelOf: (g) => 'Goal "${g.name}"',
      conflicts: conflicts,
    );

    final newGoalVersions = _diff<GoalVersion>(
      fileEntities: file.goalVersions,
      localById: {for (final v in localVersions) v.id: v},
      idOf: (v) => v.id,
      type: ImportEntityType.goalVersion,
      labelOf: (v) =>
          'a rule change to "${goalNamesById[v.goalId] ?? v.goalId}" '
          'effective ${v.versionStartDate}',
      conflicts: conflicts,
    );

    final newGoalLogs = _diff<GoalLog>(
      fileEntities: file.goalLogs,
      localById: {for (final l in localLogs) l.id: l},
      idOf: (l) => l.id,
      type: ImportEntityType.goalLog,
      labelOf: (l) =>
          'a log entry for "${goalNamesById[l.goalId] ?? l.goalId}" on '
          '${l.date}',
      conflicts: conflicts,
    );

    final newCheatDays = _diff<CheatDay>(
      fileEntities: file.cheatDays,
      localById: {for (final c in localCheatDays) c.id: c},
      idOf: (c) => c.id,
      type: ImportEntityType.cheatDay,
      labelOf: (c) =>
          'a Cheat Day for "${goalNamesById[c.goalId] ?? c.goalId}" on '
          '${c.date}',
      conflicts: conflicts,
    );

    final newBlackoutDates = _diff<BlackoutDate>(
      fileEntities: file.blackoutDates,
      localById: {for (final b in localBlackoutDates) b.id: b},
      idOf: (b) => b.id,
      type: ImportEntityType.blackoutDate,
      labelOf: (b) =>
          'a Blackout Date for "${goalNamesById[b.goalId] ?? b.goalId}" on '
          '${b.date}',
      conflicts: conflicts,
    );

    return ConflictDetectionResult(
      conflicts: conflicts,
      newGoals: newGoals,
      newGoalVersions: newGoalVersions,
      newGoalLogs: newGoalLogs,
      newCheatDays: newCheatDays,
      newBlackoutDates: newBlackoutDates,
    );
  }

  List<T> _diff<T>({
    required List<T> fileEntities,
    required Map<String, T> localById,
    required String Function(T) idOf,
    required ImportEntityType type,
    required String Function(T) labelOf,
    required List<ImportConflict> conflicts,
  }) {
    final fresh = <T>[];
    for (final entity in fileEntities) {
      final id = idOf(entity);
      final local = localById[id];
      if (local == null) {
        fresh.add(entity);
      } else if (local != entity) {
        conflicts.add(
          ImportConflict(
            type: type,
            id: id,
            mine: local as Object,
            imported: entity as Object,
            label: labelOf(entity),
          ),
        );
      }
      // else: identical content — a silent no-op merge, written nowhere.
    }
    return fresh;
  }
}
