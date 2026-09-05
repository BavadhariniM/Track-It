import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/data/io/import/import_conflict.dart';
import 'package:tracker/data/io/import/import_outcome.dart';
import 'package:tracker/data/io/json_importer.dart';
import 'package:tracker/domain/entities/blackout_date.dart';
import 'package:tracker/domain/entities/cheat_day.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/time_of_day_value.dart';
import 'package:tracker/domain/evaluator/period_boundary.dart';
import 'package:tracker/domain/services/blackout_date_repository.dart';
import 'package:tracker/domain/services/cheat_day_repository.dart';
import 'package:tracker/domain/services/goal_log_repository.dart';
import 'package:tracker/domain/services/goal_repository.dart';
import 'package:tracker/domain/services/goal_service.dart';
import 'package:tracker/domain/services/goal_version_repository.dart';
import 'package:tracker/domain/services/reminder_settings_repository.dart';
import 'package:tracker/domain/services/week_start_settings_repository.dart';

import '../../domain/services/fakes.dart';

class _FakeReminderSettingsRepository implements ReminderSettingsRepository {
  TimeOfDayValue? stored;
  final List<TimeOfDayValue> setCalls = [];

  @override
  Future<TimeOfDayValue?> getReminderTime() async => stored;

  @override
  Future<void> setReminderTime(TimeOfDayValue time) async {
    stored = time;
    setCalls.add(time);
  }

  @override
  Future<void> clear() async => stored = null;
}

class _FakeWeekStartSettingsRepository implements WeekStartSettingsRepository {
  WeekStart? stored;
  final List<WeekStart> setCalls = [];

  @override
  Future<WeekStart?> getWeekStart() async => stored;

  @override
  Future<void> setWeekStart(WeekStart value) async {
    stored = value;
    setCalls.add(value);
  }

  @override
  Future<void> clear() async => stored = null;
}

/// Subtask 7.14's fail-the-test-on-mutation fake, applied to the read-only
/// local-data repositories `JsonImporter` itself holds (distinct from the
/// separate repository instances `GoalService` writes through internally) —
/// proves `JsonImporter` never calls an insert/update/upsert method on them.
class _WriteTrackingGoalRepository implements GoalRepository {
  _WriteTrackingGoalRepository(this._delegate);
  final GoalRepository _delegate;
  bool writeCalled = false;

  @override
  Future<void> insertGoal(Goal goal) {
    writeCalled = true;
    return _delegate.insertGoal(goal);
  }

  @override
  Future<void> upsertGoal(Goal goal) {
    writeCalled = true;
    return _delegate.upsertGoal(goal);
  }

  @override
  Future<Goal?> findById(String goalId) => _delegate.findById(goalId);

  @override
  Future<void> updateGoal(Goal goal) {
    writeCalled = true;
    return _delegate.updateGoal(goal);
  }

  @override
  Stream<List<Goal>> watchAllGoals() => _delegate.watchAllGoals();

  @override
  Future<void> deleteAll() {
    writeCalled = true;
    return _delegate.deleteAll();
  }
}

class _WriteTrackingGoalVersionRepository implements GoalVersionRepository {
  _WriteTrackingGoalVersionRepository(this._delegate);
  final GoalVersionRepository _delegate;
  bool writeCalled = false;

  @override
  Future<void> insertVersion(GoalVersion version) {
    writeCalled = true;
    return _delegate.insertVersion(version);
  }

  @override
  Future<void> upsertVersion(GoalVersion version) {
    writeCalled = true;
    return _delegate.upsertVersion(version);
  }

  @override
  Future<void> updateVersion(GoalVersion version) {
    writeCalled = true;
    return _delegate.updateVersion(version);
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
  Future<void> deleteAll() {
    writeCalled = true;
    return _delegate.deleteAll();
  }
}

class _WriteTrackingGoalLogRepository implements GoalLogRepository {
  _WriteTrackingGoalLogRepository(this._delegate);
  final GoalLogRepository _delegate;
  bool writeCalled = false;

  @override
  Future<void> insertLog(GoalLog log) {
    writeCalled = true;
    return _delegate.insertLog(log);
  }

  @override
  Future<void> upsertLog(GoalLog log) {
    writeCalled = true;
    return _delegate.upsertLog(log);
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
  Future<void> deleteAll() {
    writeCalled = true;
    return _delegate.deleteAll();
  }

  @override
  Future<void> deleteLog(String id) {
    writeCalled = true;
    return _delegate.deleteLog(id);
  }
}

class _WriteTrackingCheatDayRepository implements CheatDayRepository {
  _WriteTrackingCheatDayRepository(this._delegate);
  final CheatDayRepository _delegate;
  bool writeCalled = false;

  @override
  Future<void> insertCheatDay(CheatDay cheatDay) {
    writeCalled = true;
    return _delegate.insertCheatDay(cheatDay);
  }

  @override
  Future<void> upsertCheatDay(CheatDay cheatDay) {
    writeCalled = true;
    return _delegate.upsertCheatDay(cheatDay);
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
  Future<void> deleteAll() {
    writeCalled = true;
    return _delegate.deleteAll();
  }
}

class _WriteTrackingBlackoutDateRepository implements BlackoutDateRepository {
  _WriteTrackingBlackoutDateRepository(this._delegate);
  final BlackoutDateRepository _delegate;
  bool writeCalled = false;

  @override
  Future<void> insertBlackoutDate(BlackoutDate blackoutDate) {
    writeCalled = true;
    return _delegate.insertBlackoutDate(blackoutDate);
  }

  @override
  Future<void> upsertBlackoutDate(BlackoutDate blackoutDate) {
    writeCalled = true;
    return _delegate.upsertBlackoutDate(blackoutDate);
  }

  @override
  Future<List<BlackoutDate>> findAllForGoal(String goalId) =>
      _delegate.findAllForGoal(goalId);

  @override
  Stream<List<BlackoutDate>> watchBlackoutDatesForGoal(String goalId) =>
      _delegate.watchBlackoutDatesForGoal(goalId);

  @override
  Future<void> deleteAll() {
    writeCalled = true;
    return _delegate.deleteAll();
  }
}

Map<String, dynamic> _validFile({String goalId = 'goal-1'}) => {
  'meta': {'schemaVersion': '1.0', 'exportedAt': '2026-01-01T00:00:00'},
  'goals': [
    {
      'id': goalId,
      'name': 'Read',
      'description': null,
      'category': null,
      'archived': false,
      'startDate': '2026-01-01',
      'endDate': null,
    },
  ],
  'goalVersions': [
    {
      'id': 'version-1',
      'goalId': goalId,
      'versionStartDate': '2026-01-01',
      'evaluationPeriod': 'daily',
      'eligibleDaysRule': '1,2,3,4,5,6,7',
      'targetComparison': 'at_least',
      'targetValue': '1',
      'trackingType': 'boolean',
      'cheatDayQuota': 0,
      'isPaused': false,
    },
  ],
  'goalLogs': [
    {
      'id': 'log-1',
      'goalId': goalId,
      'date': '2026-01-02',
      'timestamp': '2026-01-02T08:00:00',
      'value': 1.0,
      'completed': true,
      'dnfMarked': false,
      'note': null,
    },
  ],
  'cheatDays': [
    {'id': 'cheat-1', 'goalId': goalId, 'date': '2026-01-03', 'note': null},
  ],
  'blackoutDates': [
    {
      'id': 'blackout-1',
      'goalId': goalId,
      'date': '2026-01-04',
      'reason': null,
    },
  ],
  'categories': [],
  'settings': {'weekStartDay': 'sunday', 'reminderTime': '07:30'},
};

void main() {
  late InMemoryStore store;
  late GoalService goalService;
  late _WriteTrackingGoalRepository readGoalRepo;
  late _WriteTrackingGoalVersionRepository readVersionRepo;
  late _WriteTrackingGoalLogRepository readLogRepo;
  late _WriteTrackingCheatDayRepository readCheatDayRepo;
  late _WriteTrackingBlackoutDateRepository readBlackoutRepo;
  late _FakeReminderSettingsRepository reminderSettingsRepo;
  late _FakeWeekStartSettingsRepository weekStartSettingsRepo;
  late JsonImporter importer;

  setUp(() {
    store = InMemoryStore();
    goalService = GoalService(
      goalRepository: InMemoryGoalRepository(store),
      goalVersionRepository: InMemoryGoalVersionRepository(store),
      goalLogRepository: InMemoryGoalLogRepository(store),
      blackoutDateRepository: InMemoryBlackoutDateRepository(store),
      cheatDayRepository: InMemoryCheatDayRepository(store),
      transactionRunner: SnapshotTransactionRunner(store),
      cacheWriter: InMemoryCacheWriter(store),
      widgetBridgeWriter: InMemoryWidgetBridgeWriter(),
    );
    readGoalRepo = _WriteTrackingGoalRepository(InMemoryGoalRepository(store));
    readVersionRepo = _WriteTrackingGoalVersionRepository(
      InMemoryGoalVersionRepository(store),
    );
    readLogRepo = _WriteTrackingGoalLogRepository(
      InMemoryGoalLogRepository(store),
    );
    readCheatDayRepo = _WriteTrackingCheatDayRepository(
      InMemoryCheatDayRepository(store),
    );
    readBlackoutRepo = _WriteTrackingBlackoutDateRepository(
      InMemoryBlackoutDateRepository(store),
    );
    reminderSettingsRepo = _FakeReminderSettingsRepository();
    weekStartSettingsRepo = _FakeWeekStartSettingsRepository();
    importer = JsonImporter(
      goalRepository: readGoalRepo,
      goalVersionRepository: readVersionRepo,
      goalLogRepository: readLogRepo,
      cheatDayRepository: readCheatDayRepo,
      blackoutDateRepository: readBlackoutRepo,
      goalService: goalService,
      weekStartSettingsRepository: weekStartSettingsRepo,
      reminderSettingsRepository: reminderSettingsRepo,
    );
  });

  group('Story 6.2 — JsonImporter', () {
    test(
      'Subtask 7.1: a well-formed file with no overlaps merges into '
      'existing (empty) local data, every write traceable to GoalService',
      () async {
        final outcome = await importer.import(jsonEncode(_validFile()));

        expect(outcome, isA<ImportOutcomeCompleted>());
        expect((outcome as ImportOutcomeCompleted).zeroGoalWarning, isFalse);
        expect(store.goals, hasLength(1));
        expect(store.goals.single.id, 'goal-1');
        expect(store.versions, hasLength(1));
        expect(store.logs, hasLength(1));
        expect(store.cheatDays, hasLength(1));
        expect(store.blackoutDates, hasLength(1));
        expect(weekStartSettingsRepo.setCalls, [WeekStart.sunday]);
        expect(reminderSettingsRepo.setCalls, [
          const TimeOfDayValue(hour: 7, minute: 30),
        ]);
      },
    );

    test(
      'Subtask 7.15: a rejected import (malformed JSON) writes nothing',
      () async {
        final outcome = await importer.import('{not valid json');

        expect(outcome, isA<ImportOutcomeRejected>());
        expect(store.goals, isEmpty);
        expect(store.versions, isEmpty);
        expect(store.logs, isEmpty);
        expect(store.cheatDays, isEmpty);
        expect(store.blackoutDates, isEmpty);
        expect(weekStartSettingsRepo.setCalls, isEmpty);
        expect(reminderSettingsRepo.setCalls, isEmpty);
      },
    );

    test(
      'zero-goal file: accepted with the warning flag set, nothing '
      'rejected',
      () async {
        final file = _validFile();
        file['goals'] = <dynamic>[];
        file['goalVersions'] = <dynamic>[];
        file['goalLogs'] = <dynamic>[];
        file['cheatDays'] = <dynamic>[];
        file['blackoutDates'] = <dynamic>[];

        final outcome = await importer.import(jsonEncode(file));

        expect(outcome, isA<ImportOutcomeCompleted>());
        expect((outcome as ImportOutcomeCompleted).zeroGoalWarning, isTrue);
      },
    );

    test(
      'Subtask 7.12: a same-id goal with different content routes to '
      'resolution, one conflict, no writes yet',
      () async {
        await goalService.importGoal(
          const Goal(
            id: 'goal-1',
            name: 'Original Name',
            archived: false,
            startDate: '2026-01-01',
          ),
        );

        final outcome = await importer.import(jsonEncode(_validFile()));

        expect(outcome, isA<ImportOutcomeNeedsResolution>());
        final needsResolution = outcome as ImportOutcomeNeedsResolution;
        expect(needsResolution.detection.conflicts, hasLength(1));
        expect(
          needsResolution.detection.conflicts.single.type,
          ImportEntityType.goal,
        );
        // Nothing else from the file was written yet — Subtask 4.4.
        expect(store.versions, isEmpty);
        expect(store.goals.single.name, 'Original Name');
      },
    );

    test(
      'completeWithResolutions(keepImported) writes the imported version '
      'and finishes the rest of the batch',
      () async {
        await goalService.importGoal(
          const Goal(
            id: 'goal-1',
            name: 'Original Name',
            archived: false,
            startDate: '2026-01-01',
          ),
        );
        final needsResolution =
            await importer.import(jsonEncode(_validFile()))
                as ImportOutcomeNeedsResolution;
        final conflict = needsResolution.detection.conflicts.single;

        final outcome = await importer.completeWithResolutions(
          file: needsResolution.file,
          detection: needsResolution.detection,
          resolutions: {conflict.resolutionKey: ConflictChoice.keepImported},
          zeroGoalWarning: needsResolution.zeroGoalWarning,
        );

        expect(outcome, isA<ImportOutcomeCompleted>());
        expect(store.goals.single.name, 'Read');
        expect(store.versions, hasLength(1));
        expect(store.logs, hasLength(1));
      },
    );

    test(
      'completeWithResolutions(keepMine) leaves the local row untouched',
      () async {
        await goalService.importGoal(
          const Goal(
            id: 'goal-1',
            name: 'Original Name',
            archived: false,
            startDate: '2026-01-01',
          ),
        );
        final needsResolution =
            await importer.import(jsonEncode(_validFile()))
                as ImportOutcomeNeedsResolution;
        final conflict = needsResolution.detection.conflicts.single;

        await importer.completeWithResolutions(
          file: needsResolution.file,
          detection: needsResolution.detection,
          resolutions: {conflict.resolutionKey: ConflictChoice.keepMine},
          zeroGoalWarning: needsResolution.zeroGoalWarning,
        );

        expect(store.goals.single.name, 'Original Name');
        // The rest of the file (non-conflicting entities) still merges in.
        expect(store.versions, hasLength(1));
      },
    );

    test(
      'completeWithResolutions throws if a conflict is left unresolved '
      '(Subtask 4.4: partial resolution commits nothing)',
      () async {
        await goalService.importGoal(
          const Goal(
            id: 'goal-1',
            name: 'Original Name',
            archived: false,
            startDate: '2026-01-01',
          ),
        );
        final needsResolution =
            await importer.import(jsonEncode(_validFile()))
                as ImportOutcomeNeedsResolution;

        await expectLater(
          () => importer.completeWithResolutions(
            file: needsResolution.file,
            detection: needsResolution.detection,
            resolutions: const {},
            zeroGoalWarning: needsResolution.zeroGoalWarning,
          ),
          throwsStateError,
        );
        expect(store.versions, isEmpty);
      },
    );

    test(
      'Subtask 7.14: JsonImporter never calls insert/update/upsert on its '
      'own local-data repositories — every write is traceable to '
      'GoalService',
      () async {
        await importer.import(jsonEncode(_validFile()));

        expect(readGoalRepo.writeCalled, isFalse);
        expect(readVersionRepo.writeCalled, isFalse);
        expect(readLogRepo.writeCalled, isFalse);
        expect(readCheatDayRepo.writeCalled, isFalse);
        expect(readBlackoutRepo.writeCalled, isFalse);
      },
    );
  });
}
