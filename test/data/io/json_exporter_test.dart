import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/data/io/json_exporter.dart';
import 'package:tracker/domain/entities/blackout_date.dart';
import 'package:tracker/domain/entities/cheat_day.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/entities/time_of_day_value.dart';
import 'package:tracker/domain/evaluator/period_boundary.dart';
import 'package:tracker/domain/services/blackout_date_repository.dart';
import 'package:tracker/domain/services/cheat_day_repository.dart';
import 'package:tracker/domain/services/goal_log_repository.dart';
import 'package:tracker/domain/services/goal_repository.dart';
import 'package:tracker/domain/services/goal_version_repository.dart';
import 'package:tracker/domain/services/reminder_settings_repository.dart';
import 'package:tracker/domain/services/week_start_settings_repository.dart';

import '../../domain/services/fakes.dart';

/// Fake standing in for `SharedPrefsReminderSettingsRepository` — export
/// only ever calls [getReminderTime], never [setReminderTime].
class _FakeReminderSettingsRepository implements ReminderSettingsRepository {
  _FakeReminderSettingsRepository([this.stored]);

  final TimeOfDayValue? stored;

  @override
  Future<TimeOfDayValue?> getReminderTime() async => stored;

  @override
  Future<void> setReminderTime(TimeOfDayValue time) {
    throw StateError('export must never write settings');
  }

  @override
  Future<void> clear() {
    throw StateError('export must never write settings');
  }
}

/// Fake standing in for `SharedPrefsWeekStartSettingsRepository` — export
/// only ever calls [getWeekStart], never [setWeekStart].
class _FakeWeekStartSettingsRepository implements WeekStartSettingsRepository {
  _FakeWeekStartSettingsRepository([this.stored]);

  final WeekStart? stored;

  @override
  Future<WeekStart?> getWeekStart() async => stored;

  @override
  Future<void> setWeekStart(WeekStart value) {
    throw StateError('export must never write settings');
  }

  @override
  Future<void> clear() {
    throw StateError('export must never write settings');
  }
}

/// Subtask 4.3: wraps each real read behavior in an in-memory repository but
/// records whether any write/mutating method was ever invoked — the
/// fake/mock repository Dev Notes calls for ("fails the test if any
/// mutating method is called"), without aborting the export mid-flight the
/// way an immediate `throw` would.
class _WriteTrackingGoalRepository implements GoalRepository {
  _WriteTrackingGoalRepository(this._delegate);
  final GoalRepository _delegate;
  bool writeCalled = false;

  @override
  Future<void> insertGoal(Goal goal) async {
    writeCalled = true;
    await _delegate.insertGoal(goal);
  }

  @override
  Future<void> upsertGoal(Goal goal) async {
    writeCalled = true;
    await _delegate.upsertGoal(goal);
  }

  @override
  Future<Goal?> findById(String goalId) => _delegate.findById(goalId);

  @override
  Future<void> updateGoal(Goal goal) async {
    writeCalled = true;
    await _delegate.updateGoal(goal);
  }

  @override
  Stream<List<Goal>> watchAllGoals() => _delegate.watchAllGoals();

  @override
  Future<void> deleteAll() async {
    writeCalled = true;
    await _delegate.deleteAll();
  }
}

class _WriteTrackingGoalVersionRepository implements GoalVersionRepository {
  _WriteTrackingGoalVersionRepository(this._delegate);
  final GoalVersionRepository _delegate;
  bool writeCalled = false;

  @override
  Future<void> insertVersion(GoalVersion version) async {
    writeCalled = true;
    await _delegate.insertVersion(version);
  }

  @override
  Future<void> upsertVersion(GoalVersion version) async {
    writeCalled = true;
    await _delegate.upsertVersion(version);
  }

  @override
  Future<void> updateVersion(GoalVersion version) async {
    writeCalled = true;
    await _delegate.updateVersion(version);
  }

  @override
  Future<GoalVersion?> findByGoalIdAndStartDate(
    String goalId,
    String versionStartDate,
  ) => _delegate.findByGoalIdAndStartDate(goalId, versionStartDate);

  @override
  Future<GoalVersion?> findGoverningVersion(String goalId, String date) =>
      _delegate.findGoverningVersion(goalId, date);

  @override
  Future<List<GoalVersion>> findAllForGoal(String goalId) =>
      _delegate.findAllForGoal(goalId);

  @override
  Stream<List<GoalVersion>> watchVersionsForGoal(String goalId) =>
      _delegate.watchVersionsForGoal(goalId);

  @override
  Future<void> deleteAll() async {
    writeCalled = true;
    await _delegate.deleteAll();
  }
}

class _WriteTrackingGoalLogRepository implements GoalLogRepository {
  _WriteTrackingGoalLogRepository(this._delegate);
  final GoalLogRepository _delegate;
  bool writeCalled = false;

  @override
  Future<void> insertLog(GoalLog log) async {
    writeCalled = true;
    await _delegate.insertLog(log);
  }

  @override
  Future<void> upsertLog(GoalLog log) async {
    writeCalled = true;
    await _delegate.upsertLog(log);
  }

  @override
  Future<GoalLog?> getLogForDate(String goalId, String date) =>
      _delegate.getLogForDate(goalId, date);

  @override
  Future<bool> existsOnOrAfter(String goalId, String date) =>
      _delegate.existsOnOrAfter(goalId, date);

  @override
  Future<List<GoalLog>> findAllForGoal(String goalId) =>
      _delegate.findAllForGoal(goalId);

  @override
  Stream<List<GoalLog>> watchLogsForGoal(String goalId) =>
      _delegate.watchLogsForGoal(goalId);

  @override
  Future<void> deleteAll() async {
    writeCalled = true;
    await _delegate.deleteAll();
  }

  @override
  Future<void> deleteLog(String id) async {
    writeCalled = true;
    await _delegate.deleteLog(id);
  }
}

class _WriteTrackingCheatDayRepository implements CheatDayRepository {
  _WriteTrackingCheatDayRepository(this._delegate);
  final CheatDayRepository _delegate;
  bool writeCalled = false;

  @override
  Future<void> insertCheatDay(CheatDay cheatDay) async {
    writeCalled = true;
    await _delegate.insertCheatDay(cheatDay);
  }

  @override
  Future<void> upsertCheatDay(CheatDay cheatDay) async {
    writeCalled = true;
    await _delegate.upsertCheatDay(cheatDay);
  }

  @override
  Future<List<CheatDay>> findByGoalIdInRange(
    String goalId,
    String startDate,
    String endDate,
  ) => _delegate.findByGoalIdInRange(goalId, startDate, endDate);

  @override
  Future<List<CheatDay>> findAllForGoal(String goalId) =>
      _delegate.findAllForGoal(goalId);

  @override
  Stream<List<CheatDay>> watchCheatDaysForGoal(String goalId) =>
      _delegate.watchCheatDaysForGoal(goalId);

  @override
  Future<void> deleteAll() async {
    writeCalled = true;
    await _delegate.deleteAll();
  }
}

class _WriteTrackingBlackoutDateRepository implements BlackoutDateRepository {
  _WriteTrackingBlackoutDateRepository(this._delegate);
  final BlackoutDateRepository _delegate;
  bool writeCalled = false;

  @override
  Future<void> insertBlackoutDate(BlackoutDate blackoutDate) async {
    writeCalled = true;
    await _delegate.insertBlackoutDate(blackoutDate);
  }

  @override
  Future<void> upsertBlackoutDate(BlackoutDate blackoutDate) async {
    writeCalled = true;
    await _delegate.upsertBlackoutDate(blackoutDate);
  }

  @override
  Future<List<BlackoutDate>> findAllForGoal(String goalId) =>
      _delegate.findAllForGoal(goalId);

  @override
  Stream<List<BlackoutDate>> watchBlackoutDatesForGoal(String goalId) =>
      _delegate.watchBlackoutDatesForGoal(goalId);

  @override
  Future<void> deleteAll() async {
    writeCalled = true;
    await _delegate.deleteAll();
  }
}

void main() {
  group('Story 6.1 — JsonExporter', () {
    test(
      'Subtask 4.1: a full data set exports with every field present and '
      'correctly typed',
      () async {
        final store = InMemoryStore();
        final goal = Goal(
          id: 'goal-1',
          name: 'Read',
          description: 'Read every night',
          category: 'Wellness',
          archived: false,
          startDate: '2026-01-01',
          endDate: '2026-12-31',
        );
        final otherGoal = Goal(
          id: 'goal-2',
          name: 'Run',
          category: 'Fitness',
          archived: true,
          startDate: '2026-02-01',
        );
        store.goals.addAll([goal, otherGoal]);

        final version = GoalVersion(
          id: 'version-1',
          goalId: goal.id,
          versionStartDate: '2026-01-01',
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.atLeast,
          targetValue: '1',
          trackingType: TrackingType.boolean,
          cheatDayQuota: 2,
          isPaused: true,
        );
        store.versions.add(version);

        final log = GoalLog(
          id: 'log-1',
          goalId: goal.id,
          date: '2026-01-02',
          timestamp: '2026-01-02T08:00:00',
          value: 1,
          completed: true,
          dnfMarked: true,
          note: 'felt great',
        );
        store.logs.add(log);

        final cheatDay = CheatDay(
          id: 'cheat-1',
          goalId: goal.id,
          date: '2026-01-03',
          note: 'sick day',
        );
        store.cheatDays.add(cheatDay);

        final blackoutDate = BlackoutDate(
          id: 'blackout-1',
          goalId: goal.id,
          date: '2026-01-04',
          reason: 'travel',
        );
        store.blackoutDates.add(blackoutDate);

        final exporter = JsonExporter(
          goalRepository: InMemoryGoalRepository(store),
          goalVersionRepository: InMemoryGoalVersionRepository(store),
          goalLogRepository: InMemoryGoalLogRepository(store),
          cheatDayRepository: InMemoryCheatDayRepository(store),
          blackoutDateRepository: InMemoryBlackoutDateRepository(store),
          reminderSettingsRepository: _FakeReminderSettingsRepository(
            const TimeOfDayValue(hour: 7, minute: 30),
          ),
          weekStartSettingsRepository: _FakeWeekStartSettingsRepository(
            WeekStart.sunday,
          ),
        );

        final model = await exporter.buildExportModel();

        expect(model['meta'], {
          'schemaVersion': '1.0',
          'exportedAt': isA<String>(),
        });
        final exportedAt = (model['meta'] as Map)['exportedAt'] as String;
        // Naive per NFR-3: no 'Z' suffix and no explicit UTC offset.
        expect(exportedAt, isNot(endsWith('Z')));
        expect(DateTime.parse(exportedAt), isA<DateTime>());

        expect(model['goals'], unorderedEquals([
          {
            'id': 'goal-1',
            'name': 'Read',
            'description': 'Read every night',
            'category': 'Wellness',
            'archived': false,
            'startDate': '2026-01-01',
            'endDate': '2026-12-31',
          },
          {
            'id': 'goal-2',
            'name': 'Run',
            'description': null,
            'category': 'Fitness',
            'archived': true,
            'startDate': '2026-02-01',
            'endDate': null,
          },
        ]));

        expect(model['goalVersions'], [
          {
            'id': 'version-1',
            'goalId': 'goal-1',
            'versionStartDate': '2026-01-01',
            'evaluationPeriod': EvaluationPeriod.daily,
            'eligibleDaysRule': EligibleDaysRule.everyDay,
            'targetComparison': TargetComparison.atLeast,
            'targetValue': '1',
            'trackingType': TrackingType.boolean,
            'cheatDayQuota': 2,
            'isPaused': true,
          },
        ]);

        expect(model['goalLogs'], [
          {
            'id': 'log-1',
            'goalId': 'goal-1',
            'date': '2026-01-02',
            'timestamp': '2026-01-02T08:00:00',
            'value': 1.0,
            'completed': true,
            'dnfMarked': true,
            'note': 'felt great',
          },
        ]);

        expect(model['cheatDays'], [
          {
            'id': 'cheat-1',
            'goalId': 'goal-1',
            'date': '2026-01-03',
            'note': 'sick day',
          },
        ]);

        expect(model['blackoutDates'], [
          {
            'id': 'blackout-1',
            'goalId': 'goal-1',
            'date': '2026-01-04',
            'reason': 'travel',
          },
        ]);

        expect(model['categories'], unorderedEquals([
          {'id': 'Fitness', 'name': 'Fitness'},
          {'id': 'Wellness', 'name': 'Wellness'},
        ]));

        expect(model['settings'], {
          'weekStartDay': 'sunday',
          'reminderTime': '07:30',
        });

        // exportToJson() must produce the same shape, round-trippable via
        // jsonDecode — this is what actually gets written to the file.
        // `exportedAt` is excluded from the comparison since it calls
        // `buildExportModel()` a second time, at a later wall-clock instant.
        final json = await exporter.exportToJson();
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        expect((decoded['meta'] as Map)['schemaVersion'], '1.0');
        expect((decoded['meta'] as Map)['exportedAt'], isA<String>());
        expect(decoded..remove('meta'), model..remove('meta'));
      },
    );

    test(
      'Subtask 4.2: zero Goals exports a structurally valid file with '
      'goals: [] and empty related arrays, not an error or omitted keys',
      () async {
        final store = InMemoryStore();

        final exporter = JsonExporter(
          goalRepository: InMemoryGoalRepository(store),
          goalVersionRepository: InMemoryGoalVersionRepository(store),
          goalLogRepository: InMemoryGoalLogRepository(store),
          cheatDayRepository: InMemoryCheatDayRepository(store),
          blackoutDateRepository: InMemoryBlackoutDateRepository(store),
          reminderSettingsRepository: _FakeReminderSettingsRepository(),
          weekStartSettingsRepository: _FakeWeekStartSettingsRepository(),
        );

        final model = await exporter.buildExportModel();

        expect(model['goals'], isEmpty);
        expect(model['goalVersions'], isEmpty);
        expect(model['goalLogs'], isEmpty);
        expect(model['cheatDays'], isEmpty);
        expect(model['blackoutDates'], isEmpty);
        expect(model['categories'], isEmpty);
        expect(model.containsKey('goals'), isTrue);
        expect(model.containsKey('goalVersions'), isTrue);
        expect(model.containsKey('goalLogs'), isTrue);
        expect(model.containsKey('cheatDays'), isTrue);
        expect(model.containsKey('blackoutDates'), isTrue);
        expect(model.containsKey('categories'), isTrue);
        // Unset week-start persists as the same Monday default the live
        // setting starts at (FR-24) — not surfaced as an ambiguous null.
        expect(model['settings'], {
          'weekStartDay': 'monday',
          'reminderTime': null,
        });

        final json = await exporter.exportToJson();
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        expect((decoded['meta'] as Map)['schemaVersion'], '1.0');
        expect((decoded['meta'] as Map)['exportedAt'], isA<String>());
        expect(decoded..remove('meta'), model..remove('meta'));
      },
    );

    test(
      'Subtask 4.3: export never invokes any repository write/insert/update '
      '/delete method',
      () async {
        final store = InMemoryStore();
        final goal = Goal(
          id: 'goal-1',
          name: 'Read',
          category: 'Wellness',
          archived: false,
          startDate: '2026-01-01',
        );
        store.goals.add(goal);
        store.versions.add(
          GoalVersion(
            id: 'version-1',
            goalId: goal.id,
            versionStartDate: '2026-01-01',
            evaluationPeriod: EvaluationPeriod.daily,
            eligibleDaysRule: EligibleDaysRule.everyDay,
            targetComparison: TargetComparison.atLeast,
            targetValue: '1',
            trackingType: TrackingType.boolean,
          ),
        );
        store.logs.add(
          GoalLog(
            id: 'log-1',
            goalId: goal.id,
            date: '2026-01-02',
            timestamp: '2026-01-02T08:00:00',
            value: 1,
            completed: true,
          ),
        );
        store.cheatDays.add(
          CheatDay(id: 'cheat-1', goalId: goal.id, date: '2026-01-03'),
        );
        store.blackoutDates.add(
          BlackoutDate(id: 'blackout-1', goalId: goal.id, date: '2026-01-04'),
        );

        final goalRepo = _WriteTrackingGoalRepository(
          InMemoryGoalRepository(store),
        );
        final versionRepo = _WriteTrackingGoalVersionRepository(
          InMemoryGoalVersionRepository(store),
        );
        final logRepo = _WriteTrackingGoalLogRepository(
          InMemoryGoalLogRepository(store),
        );
        final cheatDayRepo = _WriteTrackingCheatDayRepository(
          InMemoryCheatDayRepository(store),
        );
        final blackoutDateRepo = _WriteTrackingBlackoutDateRepository(
          InMemoryBlackoutDateRepository(store),
        );

        final exporter = JsonExporter(
          goalRepository: goalRepo,
          goalVersionRepository: versionRepo,
          goalLogRepository: logRepo,
          cheatDayRepository: cheatDayRepo,
          blackoutDateRepository: blackoutDateRepo,
          // These reject any write call outright (Subtask 4.3's
          // fail-the-test-on-mutation fake) — export must never reach it.
          reminderSettingsRepository: _FakeReminderSettingsRepository(),
          weekStartSettingsRepository: _FakeWeekStartSettingsRepository(),
        );

        final model = await exporter.buildExportModel();

        expect(model['goals'], hasLength(1));
        expect(goalRepo.writeCalled, isFalse);
        expect(versionRepo.writeCalled, isFalse);
        expect(logRepo.writeCalled, isFalse);
        expect(cheatDayRepo.writeCalled, isFalse);
        expect(blackoutDateRepo.writeCalled, isFalse);
      },
    );

    test(
      'Subtask 4.4: the exporter module has no import of any networking '
      'package, consistent with NFR-1/NFR-2',
      () {
        final source = File('lib/data/io/json_exporter.dart').readAsStringSync();
        final importLines = const LineSplitter()
            .convert(source)
            .where((line) => line.trim().startsWith('import '))
            .toList();

        const forbiddenSubstrings = [
          'dart:io',
          'dart:html',
          'package:http',
          'package:dio',
          'package:web_socket_channel',
          'package:cronet',
        ];

        for (final line in importLines) {
          for (final forbidden in forbiddenSubstrings) {
            expect(
              line.contains(forbidden),
              isFalse,
              reason: 'json_exporter.dart must not import $forbidden: $line',
            );
          }
        }
      },
    );
  });
}
