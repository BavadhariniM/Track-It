import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/data/io/import/conflict_detector.dart';
import 'package:tracker/data/io/import/import_conflict.dart';
import 'package:tracker/data/io/import/parsed_import_file.dart';
import 'package:tracker/domain/entities/blackout_date.dart';
import 'package:tracker/domain/entities/cheat_day.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';

GoalVersion _version({
  String id = 'version-1',
  String goalId = 'goal-1',
  String versionStartDate = '2026-01-01',
  String targetValue = '1',
}) => GoalVersion(
  id: id,
  goalId: goalId,
  versionStartDate: versionStartDate,
  evaluationPeriod: EvaluationPeriod.daily,
  eligibleDaysRule: EligibleDaysRule.everyDay,
  targetComparison: TargetComparison.atLeast,
  targetValue: targetValue,
  trackingType: TrackingType.boolean,
);

void main() {
  const detector = ConflictDetector();

  ParsedImportFile emptyFile() => const ParsedImportFile(
    goals: [],
    goalVersions: [],
    goalLogs: [],
    cheatDays: [],
    blackoutDates: [],
    weekStart: null,
    reminderTime: null,
  );

  group('Story 6.2 — ConflictDetector', () {
    test('Subtask 3.1: an id absent locally is a new entity, not a conflict', () {
      final fileGoal = const Goal(
        id: 'goal-1',
        name: 'Read',
        archived: false,
        startDate: '2026-01-01',
      );

      final result = detector.detect(
        file: ParsedImportFile(
          goals: [fileGoal],
          goalVersions: const [],
          goalLogs: const [],
          cheatDays: const [],
          blackoutDates: const [],
          weekStart: null,
          reminderTime: null,
        ),
        localGoals: const [],
        localVersions: const [],
        localLogs: const [],
        localCheatDays: const [],
        localBlackoutDates: const [],
      );

      expect(result.newGoals, [fileGoal]);
      expect(result.conflicts, isEmpty);
    });

    test(
      'Subtask 3.1: an id matching local data with identical content is a '
      'silent no-op — appears in neither list',
      () {
        final goal = const Goal(
          id: 'goal-1',
          name: 'Read',
          archived: false,
          startDate: '2026-01-01',
        );

        final result = detector.detect(
          file: ParsedImportFile(
            goals: [goal],
            goalVersions: const [],
            goalLogs: const [],
            cheatDays: const [],
            blackoutDates: const [],
            weekStart: null,
            reminderTime: null,
          ),
          localGoals: [goal],
          localVersions: const [],
          localLogs: const [],
          localCheatDays: const [],
          localBlackoutDates: const [],
        );

        expect(result.newGoals, isEmpty);
        expect(result.conflicts, isEmpty);
      },
    );

    test(
      'Subtask 3.1/3.2: an id matching local data with different content is '
      'a conflict, routed to resolution rather than auto-rejected or '
      'auto-merged',
      () {
        final mine = const Goal(
          id: 'goal-1',
          name: 'Read',
          archived: false,
          startDate: '2026-01-01',
        );
        final imported = const Goal(
          id: 'goal-1',
          name: 'Read Every Night',
          archived: false,
          startDate: '2026-01-01',
        );

        final result = detector.detect(
          file: ParsedImportFile(
            goals: [imported],
            goalVersions: const [],
            goalLogs: const [],
            cheatDays: const [],
            blackoutDates: const [],
            weekStart: null,
            reminderTime: null,
          ),
          localGoals: [mine],
          localVersions: const [],
          localLogs: const [],
          localCheatDays: const [],
          localBlackoutDates: const [],
        );

        expect(result.newGoals, isEmpty);
        expect(result.conflicts, hasLength(1));
        final conflict = result.conflicts.single;
        expect(conflict.type, ImportEntityType.goal);
        expect(conflict.id, 'goal-1');
        expect(conflict.mine, mine);
        expect(conflict.imported, imported);
        expect(conflict.label, contains('Read Every Night'));
      },
    );

    test('detects conflicts across every entity type, each with a specific label', () {
      final localGoal = const Goal(
        id: 'goal-1',
        name: 'Read',
        archived: false,
        startDate: '2026-01-01',
      );
      final localVersion = _version(targetValue: '1');
      final importedVersion = _version(targetValue: '2');
      final localLog = const GoalLog(
        id: 'log-1',
        goalId: 'goal-1',
        date: '2026-01-02',
        timestamp: '2026-01-02T08:00:00',
        value: 1,
        completed: true,
      );
      final importedLog = const GoalLog(
        id: 'log-1',
        goalId: 'goal-1',
        date: '2026-01-02',
        timestamp: '2026-01-02T09:00:00',
        value: 2,
        completed: true,
      );
      final localCheatDay = const CheatDay(
        id: 'cheat-1',
        goalId: 'goal-1',
        date: '2026-01-03',
      );
      final importedCheatDay = const CheatDay(
        id: 'cheat-1',
        goalId: 'goal-1',
        date: '2026-01-03',
        note: 'sick',
      );
      final localBlackout = const BlackoutDate(
        id: 'blackout-1',
        goalId: 'goal-1',
        date: '2026-01-04',
      );
      final importedBlackout = const BlackoutDate(
        id: 'blackout-1',
        goalId: 'goal-1',
        date: '2026-01-04',
        reason: 'travel',
      );

      final result = detector.detect(
        file: ParsedImportFile(
          goals: [localGoal],
          goalVersions: [importedVersion],
          goalLogs: [importedLog],
          cheatDays: [importedCheatDay],
          blackoutDates: [importedBlackout],
          weekStart: null,
          reminderTime: null,
        ),
        localGoals: [localGoal],
        localVersions: [localVersion],
        localLogs: [localLog],
        localCheatDays: [localCheatDay],
        localBlackoutDates: [localBlackout],
      );

      expect(result.conflicts, hasLength(4));
      final types = result.conflicts.map((c) => c.type).toSet();
      expect(types, {
        ImportEntityType.goalVersion,
        ImportEntityType.goalLog,
        ImportEntityType.cheatDay,
        ImportEntityType.blackoutDate,
      });
      for (final conflict in result.conflicts) {
        expect(conflict.label, contains('Read'));
      }
    });

    test('an empty file against existing local data produces nothing', () {
      final result = detector.detect(
        file: emptyFile(),
        localGoals: [
          const Goal(
            id: 'goal-1',
            name: 'Read',
            archived: false,
            startDate: '2026-01-01',
          ),
        ],
        localVersions: const [],
        localLogs: const [],
        localCheatDays: const [],
        localBlackoutDates: const [],
      );

      expect(result.newGoals, isEmpty);
      expect(result.conflicts, isEmpty);
    });
  });
}
