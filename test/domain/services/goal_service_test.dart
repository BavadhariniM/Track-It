import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/blackout_date.dart';
import 'package:tracker/domain/entities/cheat_day.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/goal_version_draft.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/entities/time_of_day_value.dart';
import 'package:tracker/domain/evaluator/evaluate.dart';
import 'package:tracker/domain/evaluator/period_boundary.dart';
import 'package:tracker/domain/services/goal_service.dart';
import 'package:tracker/domain/services/goal_service_result.dart';
import 'package:tracker/domain/services/reminder_settings_repository.dart';
import 'package:tracker/domain/services/result.dart';
import 'package:tracker/domain/services/week_start_settings_repository.dart';

import 'fakes.dart';

/// Story 6.3's `_FakeReminderSettingsRepository`/
/// `_FakeWeekStartSettingsRepository` — the same shape
/// `settings_screen_test.dart` already uses for these interfaces, duplicated
/// here rather than shared, matching this codebase's existing per-test-file
/// fake convention (e.g. `json_exporter_test.dart` and
/// `json_importer_test.dart` each define their own copies too).
class _FakeReminderSettingsRepository implements ReminderSettingsRepository {
  TimeOfDayValue? stored;

  @override
  Future<TimeOfDayValue?> getReminderTime() async => stored;

  @override
  Future<void> setReminderTime(TimeOfDayValue time) async => stored = time;

  @override
  Future<void> clear() async => stored = null;
}

class _FakeWeekStartSettingsRepository implements WeekStartSettingsRepository {
  WeekStart? stored;

  @override
  Future<WeekStart?> getWeekStart() async => stored;

  @override
  Future<void> setWeekStart(WeekStart value) async => stored = value;

  @override
  Future<void> clear() async => stored = null;
}

void main() {
  late InMemoryStore store;
  late InMemoryGoalRepository goalRepository;
  late InMemoryGoalVersionRepository goalVersionRepository;
  late InMemoryGoalLogRepository goalLogRepository;
  late InMemoryBlackoutDateRepository blackoutDateRepository;
  late InMemoryCheatDayRepository cheatDayRepository;
  late SnapshotTransactionRunner transactionRunner;
  late GoalService goalService;

  setUp(() {
    store = InMemoryStore();
    goalRepository = InMemoryGoalRepository(store);
    goalVersionRepository = InMemoryGoalVersionRepository(store);
    goalLogRepository = InMemoryGoalLogRepository(store);
    blackoutDateRepository = InMemoryBlackoutDateRepository(store);
    cheatDayRepository = InMemoryCheatDayRepository(store);
    transactionRunner = SnapshotTransactionRunner(store);
    goalService = GoalService(
      goalRepository: goalRepository,
      goalVersionRepository: goalVersionRepository,
      goalLogRepository: goalLogRepository,
      blackoutDateRepository: blackoutDateRepository,
      cheatDayRepository: cheatDayRepository,
      transactionRunner: transactionRunner,
      cacheWriter: InMemoryCacheWriter(store),
      widgetBridgeWriter: InMemoryWidgetBridgeWriter(),
    );
  });

  group('createGoal', () {
    test(
      'persists exactly one Goal and one GoalVersion with matching ids',
      () async {
        final result = await goalService.createGoal(
          name: 'Read',
          startDate: '2026-08-01',
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.exactly,
          targetValue: '1',
          trackingType: TrackingType.boolean,
        );

        expect(result, isA<Success<dynamic>>());
        final goal = (result as Success).value;

        expect(store.goals, hasLength(1));
        expect(store.versions, hasLength(1));
        expect(store.versions.single.goalId, goal.id);
        expect(store.versions.single.versionStartDate, '2026-08-01');
        expect(goal.id, isNotEmpty);
        // UUIDv4 string, e.g. 8 hex chars, then three 4-char groups, then 12.
        expect(
          goal.id,
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
      },
    );

    test('rejects an empty name and persists nothing', () async {
      final result = await goalService.createGoal(
        name: '   ',
        startDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );

      expect(result, isA<Failure<dynamic>>());
      expect(store.goals, isEmpty);
      expect(store.versions, isEmpty);
    });

    test('a kill mid-transaction leaves zero partial rows (single-transaction guarantee)', () async {
      goalVersionRepository.shouldFailOnInsert = true;

      await expectLater(
        goalService.createGoal(
          name: 'Read',
          startDate: '2026-08-01',
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.exactly,
          targetValue: '1',
          trackingType: TrackingType.boolean,
        ),
        throwsA(isA<StateError>()),
      );

      // The Goal insert happened before the simulated crash, but the
      // transaction must have rolled it back along with everything else.
      expect(store.goals, isEmpty);
      expect(store.versions, isEmpty);
    });
  });

  group('logBoolean', () {
    test('persists a completed GoalLog for the given goal and date', () async {
      final createResult = await goalService.createGoal(
        name: 'Read',
        startDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );
      final goal = (createResult as Success).value;

      final logResult = await goalService.logBoolean(
        goalId: goal.id,
        date: '2026-08-15',
        completed: true,
      );

      expect(logResult, isA<Success<dynamic>>());
      expect(store.logs, hasLength(1));
      expect(store.logs.single.goalId, goal.id);
      expect(store.logs.single.date, '2026-08-15');
      expect(store.logs.single.completed, isTrue);
      expect(store.logs.single.value, 1);
    });
  });

  group('undoBooleanLog', () {
    test(
      'retracts the log by id rather than appending a not-done record '
      '(Bug 4)',
      () async {
        final createResult = await goalService.createGoal(
          name: 'Read',
          startDate: '2026-08-01',
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.exactly,
          targetValue: '1',
          trackingType: TrackingType.boolean,
        );
        final goal = (createResult as Success).value;

        final logResult = await goalService.logBoolean(
          goalId: goal.id,
          date: '2026-08-15',
          completed: true,
        );
        final log = (logResult as Success).value;
        expect(store.logs, hasLength(1));

        final undoResult = await goalService.undoBooleanLog(
          goalId: goal.id,
          logId: log.id,
          date: '2026-08-15',
        );

        expect(undoResult, isA<Success<dynamic>>());
        expect(store.logs, isEmpty);
      },
    );
  });

  group('logCounter', () {
    test('a +1 delta upserts a single running-total row', () async {
      final createResult = await goalService.createGoal(
        name: 'Water',
        startDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.atLeast,
        targetValue: '8',
        trackingType: TrackingType.counter,
      );
      final goal = (createResult as Success).value;

      await goalService.logCounter(
        goalId: goal.id,
        date: '2026-08-15',
        delta: 1,
      );
      await goalService.logCounter(
        goalId: goal.id,
        date: '2026-08-15',
        delta: 1,
      );

      // Two +1 taps must upsert one row with total 2, never two rows
      // (FR-14: no per-increment timestamp).
      expect(store.logs, hasLength(1));
      expect(store.logs.single.value, 2);
    });

    test('a negative correction floors the total at 0, never below', () async {
      final createResult = await goalService.createGoal(
        name: 'Water',
        startDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.atLeast,
        targetValue: '8',
        trackingType: TrackingType.counter,
      );
      final goal = (createResult as Success).value;

      await goalService.logCounter(
        goalId: goal.id,
        date: '2026-08-15',
        delta: 2,
      );
      final result = await goalService.logCounter(
        goalId: goal.id,
        date: '2026-08-15',
        delta: -5,
      );

      expect((result as Success).value.value, 0);
      expect(store.logs.single.value, 0);
    });

    test('decimal deltas round-trip without precision loss', () async {
      final createResult = await goalService.createGoal(
        name: 'Water',
        startDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.atLeast,
        targetValue: '8',
        trackingType: TrackingType.counter,
      );
      final goal = (createResult as Success).value;

      await goalService.logCounter(
        goalId: goal.id,
        date: '2026-08-15',
        delta: 7.5,
      );

      expect(store.logs.single.value, 7.5);
    });

    test('a kill mid-transaction during the upsert leaves the prior total '
        'intact, not a partial write (Story 1.11 Subtask 5.3)', () async {
      final createResult = await goalService.createGoal(
        name: 'Water',
        startDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.atLeast,
        targetValue: '8',
        trackingType: TrackingType.counter,
      );
      final goal = (createResult as Success).value;

      await goalService.logCounter(
        goalId: goal.id,
        date: '2026-08-15',
        delta: 2,
      );
      expect(store.logs.single.value, 2);

      goalLogRepository.shouldFailOnUpsert = true;
      await expectLater(
        goalService.logCounter(goalId: goal.id, date: '2026-08-15', delta: 3),
        throwsA(isA<StateError>()),
      );

      // The read-modify-upsert never committed; the previously-saved
      // total of 2 survives untouched (FR-19/NFR-7).
      expect(store.logs, hasLength(1));
      expect(store.logs.single.value, 2);
    });
  });

  group('markBlackoutDate', () {
    test(
      'persists a BlackoutDate with an optional reason inside a transaction',
      () async {
        final createResult = await goalService.createGoal(
          name: 'Read',
          startDate: '2026-08-01',
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.exactly,
          targetValue: '1',
          trackingType: TrackingType.boolean,
        );
        final goal = (createResult as Success).value;

        final result = await goalService.markBlackoutDate(
          goalId: goal.id,
          date: '2026-08-15',
          reason: 'Public holiday',
        );

        expect(result, isA<Success<dynamic>>());
        expect(store.blackoutDates, hasLength(1));
        expect(store.blackoutDates.single.goalId, goal.id);
        expect(store.blackoutDates.single.date, '2026-08-15');
        expect(store.blackoutDates.single.reason, 'Public holiday');
      },
    );

    test('a kill mid-transaction leaves zero partial rows (Story 1.11 Subtask 5.3)', () async {
      final createResult = await goalService.createGoal(
        name: 'Read',
        startDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );
      final goal = (createResult as Success).value;

      blackoutDateRepository.shouldFailOnInsert = true;
      await expectLater(
        goalService.markBlackoutDate(goalId: goal.id, date: '2026-08-15'),
        throwsA(isA<StateError>()),
      );

      expect(store.blackoutDates, isEmpty);
    });
  });

  group('transaction scoping is per-operation, not batched (Subtask 5.4)', () {
    test(
      'two sequential, unrelated goal creations are independent '
      'transactions — a failure in the second does not roll back the first',
      () async {
        final firstResult = await goalService.createGoal(
          name: 'Read',
          startDate: '2026-08-01',
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.exactly,
          targetValue: '1',
          trackingType: TrackingType.boolean,
        );
        final firstGoal = (firstResult as Success).value;
        expect(store.goals, hasLength(1));
        expect(store.versions, hasLength(1));

        // A kill during the *second*, unrelated goal's creation must never
        // roll back the first goal — over-eager transaction scoping (e.g.
        // one shared transaction spanning both calls) would incorrectly
        // lose already-committed data on an unrelated write's failure.
        goalVersionRepository.shouldFailOnInsert = true;
        await expectLater(
          goalService.createGoal(
            name: 'Water',
            startDate: '2026-08-01',
            evaluationPeriod: EvaluationPeriod.daily,
            eligibleDaysRule: EligibleDaysRule.everyDay,
            targetComparison: TargetComparison.atLeast,
            targetValue: '8',
            trackingType: TrackingType.counter,
          ),
          throwsA(isA<StateError>()),
        );

        expect(store.goals, hasLength(1));
        expect(store.goals.single.id, firstGoal.id);
        expect(store.goals.single.name, 'Read');
        expect(store.versions, hasLength(1));
        expect(store.versions.single.goalId, firstGoal.id);
      },
    );
  });

  group('editGoalVersion (Story 2.1)', () {
    const draft = GoalVersionDraft(
      evaluationPeriod: EvaluationPeriod.weekly,
      eligibleDaysRule: EligibleDaysRule.workdays,
      targetComparison: TargetComparison.atLeast,
      targetValue: '3',
      trackingType: TrackingType.boolean,
      cheatDayQuota: 1,
    );

    Future<String> createTestGoal() async {
      final result = await goalService.createGoal(
        name: 'Read',
        startDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );
      return (result as Success).value.id;
    }

    test(
      'AC 1: editing effective a fresh date creates a new dated GoalVersion, '
      'not a mutation of the existing one',
      () async {
        final goalId = await createTestGoal();

        final result = await goalService.editGoalVersion(
          goalId: goalId,
          effectiveDate: '2026-08-20',
          newRules: draft,
        );

        expect(result, isA<GoalServiceSuccess<dynamic>>());
        expect(store.versions, hasLength(2));
        final originalVersion = store.versions.firstWhere(
          (v) => v.versionStartDate == '2026-08-01',
        );
        final newVersion = store.versions.firstWhere(
          (v) => v.versionStartDate == '2026-08-20',
        );
        // The original Version is untouched — its own row still exists
        // with its original rules.
        expect(originalVersion.evaluationPeriod, EvaluationPeriod.daily);
        expect(originalVersion.targetComparison, TargetComparison.exactly);
        // The new Version carries the edited rules.
        expect(newVersion.evaluationPeriod, EvaluationPeriod.weekly);
        expect(newVersion.eligibleDaysRule, EligibleDaysRule.workdays);
        expect(newVersion.targetComparison, TargetComparison.atLeast);
        expect(newVersion.targetValue, '3');
        expect(newVersion.trackingType, TrackingType.boolean);
        expect(newVersion.cheatDayQuota, 1);
        expect(newVersion.id, isNot(originalVersion.id));
      },
    );

    test('AC 3 (5.1): a same-day double edit before any log amends the '
        'still-log-free Version in place — row count unchanged, same id, new '
        'field values', () async {
      final goalId = await createTestGoal();

      final firstEdit = await goalService.editGoalVersion(
        goalId: goalId,
        effectiveDate: '2026-08-20',
        newRules: draft,
      );
      expect(firstEdit, isA<GoalServiceSuccess<dynamic>>());
      expect(store.versions, hasLength(2));
      final firstEditedId = store.versions
          .firstWhere((v) => v.versionStartDate == '2026-08-20')
          .id;

      const secondDraft = GoalVersionDraft(
        evaluationPeriod: EvaluationPeriod.monthly,
        eligibleDaysRule: EligibleDaysRule.weekends,
        targetComparison: TargetComparison.atMost,
        targetValue: '5',
        trackingType: TrackingType.counter,
        cheatDayQuota: 0,
      );

      final secondEdit = await goalService.editGoalVersion(
        goalId: goalId,
        effectiveDate: '2026-08-20',
        newRules: secondDraft,
      );

      expect(secondEdit, isA<GoalServiceSuccess<dynamic>>());
      // Row count unchanged — still exactly 2 Versions total (original +
      // the one same-day segment), never a 3rd row for the same date.
      expect(store.versions, hasLength(2));
      final amended = store.versions.firstWhere(
        (v) => v.versionStartDate == '2026-08-20',
      );
      expect(amended.id, firstEditedId);
      expect(amended.evaluationPeriod, EvaluationPeriod.monthly);
      expect(amended.eligibleDaysRule, EligibleDaysRule.weekends);
      expect(amended.targetComparison, TargetComparison.atMost);
      expect(amended.targetValue, '5');
      expect(amended.trackingType, TrackingType.counter);
      expect(amended.cheatDayQuota, 0);
    });

    test('AC 4 (5.2): an edit attempted same-day after a GoalLog exists '
        'against that Version returns Failure(versionLocked) and writes '
        'nothing', () async {
      final goalId = await createTestGoal();

      final firstEdit = await goalService.editGoalVersion(
        goalId: goalId,
        effectiveDate: '2026-08-20',
        newRules: draft,
      );
      expect(firstEdit, isA<GoalServiceSuccess<dynamic>>());
      expect(store.versions, hasLength(2));

      await goalService.logBoolean(
        goalId: goalId,
        date: '2026-08-21',
        completed: true,
      );
      final snapshotBeforeSecondEdit = store.versions.map((v) => v).toList();

      final secondEdit = await goalService.editGoalVersion(
        goalId: goalId,
        effectiveDate: '2026-08-20',
        newRules: const GoalVersionDraft(
          evaluationPeriod: EvaluationPeriod.monthly,
          eligibleDaysRule: EligibleDaysRule.weekends,
          targetComparison: TargetComparison.atMost,
          targetValue: '5',
          trackingType: TrackingType.counter,
        ),
      );

      expect(secondEdit, isA<GoalServiceFailureResult<dynamic>>());
      expect(
        (secondEdit as GoalServiceFailureResult).reason,
        GoalServiceFailure.versionLocked,
      );
      // Nothing was written: same rows, same values as before the
      // rejected edit.
      expect(store.versions, hasLength(2));
      expect(store.versions, equals(snapshotBeforeSecondEdit));
    });

    test('AC 4: a log logged exactly on the effective date itself also locks '
        'the Version (date >= effectiveDate, not strictly after)', () async {
      final goalId = await createTestGoal();

      await goalService.editGoalVersion(
        goalId: goalId,
        effectiveDate: '2026-08-20',
        newRules: draft,
      );
      await goalService.logBoolean(
        goalId: goalId,
        date: '2026-08-20',
        completed: true,
      );

      final result = await goalService.editGoalVersion(
        goalId: goalId,
        effectiveDate: '2026-08-20',
        newRules: draft,
      );

      expect(result, isA<GoalServiceFailureResult<dynamic>>());
      expect(
        (result as GoalServiceFailureResult).reason,
        GoalServiceFailure.versionLocked,
      );
    });

    test('5.3: an edit at a later effective date succeeds even when the '
        'current Version has logs against it', () async {
      final goalId = await createTestGoal();

      // Log against the original (2026-08-01) Version.
      await goalService.logBoolean(
        goalId: goalId,
        date: '2026-08-05',
        completed: true,
      );

      final result = await goalService.editGoalVersion(
        goalId: goalId,
        effectiveDate: '2026-09-01',
        newRules: draft,
      );

      expect(result, isA<GoalServiceSuccess<dynamic>>());
      expect(store.versions, hasLength(2));
      final newVersion = store.versions.firstWhere(
        (v) => v.versionStartDate == '2026-09-01',
      );
      expect(newVersion.evaluationPeriod, EvaluationPeriod.weekly);
      expect(newVersion.targetComparison, TargetComparison.atLeast);
    });

    test('a kill mid-write leaves zero partial rows (Transaction atomicity, '
        'AC 5)', () async {
      final goalId = await createTestGoal();

      goalVersionRepository.shouldFailOnInsert = true;
      await expectLater(
        goalService.editGoalVersion(
          goalId: goalId,
          effectiveDate: '2026-08-20',
          newRules: draft,
        ),
        throwsA(isA<StateError>()),
      );

      expect(store.versions, hasLength(1));
      expect(store.versions.single.versionStartDate, '2026-08-01');
    });

    test('editing rules never itself flips isPaused: a same-day amend '
        'preserves the existing row pause state', () async {
      final goalId = await createTestGoal();
      await goalService.editGoalVersion(
        goalId: goalId,
        effectiveDate: '2026-08-20',
        newRules: draft,
      );
      // Directly flip the persisted row's isPaused to simulate a prior
      // Story 2.2 pause, then re-edit rules on the same date.
      final index = store.versions.indexWhere(
        (v) => v.versionStartDate == '2026-08-20',
      );
      store.versions[index] = store.versions[index].copyWith(isPaused: true);

      await goalService.editGoalVersion(
        goalId: goalId,
        effectiveDate: '2026-08-20',
        newRules: draft,
      );

      expect(
        store.versions
            .firstWhere((v) => v.versionStartDate == '2026-08-20')
            .isPaused,
        isTrue,
      );
    });
  });

  group('pauseGoal / resumeGoal (Story 2.2)', () {
    Future<String> createTestGoal() async {
      final result = await goalService.createGoal(
        name: 'Read',
        startDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.weekly,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.atLeast,
        targetValue: '3',
        trackingType: TrackingType.boolean,
        cheatDayQuota: 1,
      );
      return (result as Success).value.id;
    }

    test('AC 1: pausing effective a fresh date creates a new dated GoalVersion '
        'with isPaused true, carrying every other rule field forward '
        'unchanged from the governing Version', () async {
      final goalId = await createTestGoal();

      final result = await goalService.pauseGoal(
        goalId: goalId,
        effectiveDate: '2026-08-20',
      );

      expect(result, isA<GoalServiceSuccess<dynamic>>());
      expect(store.versions, hasLength(2));
      final paused = store.versions.firstWhere(
        (v) => v.versionStartDate == '2026-08-20',
      );
      expect(paused.isPaused, isTrue);
      expect(paused.evaluationPeriod, EvaluationPeriod.weekly);
      expect(paused.eligibleDaysRule, EligibleDaysRule.everyDay);
      expect(paused.targetComparison, TargetComparison.atLeast);
      expect(paused.targetValue, '3');
      expect(paused.trackingType, TrackingType.boolean);
      expect(paused.cheatDayQuota, 1);
      // The original Version is untouched.
      final original = store.versions.firstWhere(
        (v) => v.versionStartDate == '2026-08-01',
      );
      expect(original.isPaused, isFalse);
    });

    test(
      'AC 3: resuming effective a fresh date creates a new dated GoalVersion '
      "with isPaused false, carrying the paused Version's rules forward",
      () async {
        final goalId = await createTestGoal();
        await goalService.pauseGoal(
          goalId: goalId,
          effectiveDate: '2026-08-10',
        );

        final result = await goalService.resumeGoal(
          goalId: goalId,
          effectiveDate: '2026-08-20',
        );

        expect(result, isA<GoalServiceSuccess<dynamic>>());
        expect(store.versions, hasLength(3));
        final resumed = store.versions.firstWhere(
          (v) => v.versionStartDate == '2026-08-20',
        );
        expect(resumed.isPaused, isFalse);
        expect(resumed.evaluationPeriod, EvaluationPeriod.weekly);
        expect(resumed.targetValue, '3');
        // The paused segment in between stays paused.
        final paused = store.versions.firstWhere(
          (v) => v.versionStartDate == '2026-08-10',
        );
        expect(paused.isPaused, isTrue);
      },
    );

    test('AC 4: pause/resume reuse the AD-6 collision algorithm — a same-day '
        'pause then resume before any log amends the still-log-free Version '
        'in place, never inserting a second row for the same date', () async {
      final goalId = await createTestGoal();

      final firstPause = await goalService.pauseGoal(
        goalId: goalId,
        effectiveDate: '2026-08-20',
      );
      expect(firstPause, isA<GoalServiceSuccess<dynamic>>());
      expect(store.versions, hasLength(2));
      final pausedId = store.versions
          .firstWhere((v) => v.versionStartDate == '2026-08-20')
          .id;

      final sameDayResume = await goalService.resumeGoal(
        goalId: goalId,
        effectiveDate: '2026-08-20',
      );

      expect(sameDayResume, isA<GoalServiceSuccess<dynamic>>());
      // Row count unchanged — the same-day pause and resume amend one
      // segment in place, never producing a second row for 2026-08-20.
      expect(store.versions, hasLength(2));
      final amended = store.versions.firstWhere(
        (v) => v.versionStartDate == '2026-08-20',
      );
      expect(amended.id, pausedId);
      expect(amended.isPaused, isFalse);
    });

    test('pause is rejected with versionLocked once a GoalLog exists against '
        'that same-day Version, writing nothing (AC 4 / AD-6)', () async {
      final goalId = await createTestGoal();
      await goalService.pauseGoal(goalId: goalId, effectiveDate: '2026-08-20');
      await goalService.logBoolean(
        goalId: goalId,
        date: '2026-08-20',
        completed: true,
      );
      final snapshotBeforeResume = List.of(store.versions);

      final result = await goalService.resumeGoal(
        goalId: goalId,
        effectiveDate: '2026-08-20',
      );

      expect(result, isA<GoalServiceFailureResult<dynamic>>());
      expect(
        (result as GoalServiceFailureResult).reason,
        GoalServiceFailure.versionLocked,
      );
      expect(store.versions, equals(snapshotBeforeResume));
    });

    test('AC 5: a kill mid-write leaves zero partial rows (Transaction '
        'atomicity)', () async {
      final goalId = await createTestGoal();

      goalVersionRepository.shouldFailOnInsert = true;
      await expectLater(
        goalService.pauseGoal(goalId: goalId, effectiveDate: '2026-08-20'),
        throwsA(isA<StateError>()),
      );

      expect(store.versions, hasLength(1));
      expect(store.versions.single.versionStartDate, '2026-08-01');
    });
  });

  group('archiveGoal (Story 2.3)', () {
    Future<String> createTestGoal() async {
      final result = await goalService.createGoal(
        name: 'Read',
        startDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );
      return (result as Success).value.id;
    }

    test('AC 1: archives a goal by flipping Goal.archived to true', () async {
      final goalId = await createTestGoal();

      final result = await goalService.archiveGoal(goalId: goalId);

      expect(result, isA<GoalServiceSuccess<dynamic>>());
      expect((result as GoalServiceSuccess).value.archived, isTrue);
      expect(store.goals.single.archived, isTrue);
    });

    test(
      'AC 4: archiving never writes/touches GoalVersion or GoalLog rows',
      () async {
        final goalId = await createTestGoal();
        await goalService.logBoolean(
          goalId: goalId,
          date: '2026-08-05',
          completed: true,
        );
        final versionsBefore = List.of(store.versions);
        final logsBefore = List.of(store.logs);

        await goalService.archiveGoal(goalId: goalId);

        expect(store.versions, equals(versionsBefore));
        expect(store.logs, equals(logsBefore));
      },
    );

    test('Task 1.3: archiving an already-archived goal succeeds as a no-op, '
        'not a failure', () async {
      final goalId = await createTestGoal();
      await goalService.archiveGoal(goalId: goalId);

      final secondResult = await goalService.archiveGoal(goalId: goalId);

      expect(secondResult, isA<GoalServiceSuccess<dynamic>>());
      expect(store.goals, hasLength(1));
      expect(store.goals.single.archived, isTrue);
    });

    test('a kill mid-write leaves the goal unarchived, not a partial write '
        '(Transaction atomicity)', () async {
      final goalId = await createTestGoal();

      goalRepository.shouldFailOnUpdate = true;
      await expectLater(
        goalService.archiveGoal(goalId: goalId),
        throwsA(isA<StateError>()),
      );

      expect(store.goals.single.archived, isFalse);
    });
  });

  group('markCheatDay (Story 2.4)', () {
    Future<String> createWeeklyGoal({required int cheatDayQuota}) async {
      final result = await goalService.createGoal(
        name: 'Read',
        startDate: '2026-08-03', // a Monday
        evaluationPeriod: EvaluationPeriod.weekly,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.atLeast,
        targetValue: '3',
        trackingType: TrackingType.boolean,
        cheatDayQuota: cheatDayQuota,
      );
      return (result as Success).value.id;
    }

    test(
      'AC 1/2: marking up to exactly the quota succeeds and persists each row',
      () async {
        final goalId = await createWeeklyGoal(cheatDayQuota: 2);

        final first = await goalService.markCheatDay(
          goalId: goalId,
          date: '2026-08-04',
        );
        final second = await goalService.markCheatDay(
          goalId: goalId,
          date: '2026-08-05',
          note: 'Trip',
        );

        expect(first, isA<GoalServiceSuccess<dynamic>>());
        expect(second, isA<GoalServiceSuccess<dynamic>>());
        expect(store.cheatDays, hasLength(2));
        expect(store.cheatDays.last.note, 'Trip');
      },
    );

    test('AC 4: one more than the quota is rejected as cheatDayQuotaExhausted '
        'and writes nothing', () async {
      final goalId = await createWeeklyGoal(cheatDayQuota: 1);
      await goalService.markCheatDay(goalId: goalId, date: '2026-08-04');

      final result = await goalService.markCheatDay(
        goalId: goalId,
        date: '2026-08-05',
      );

      expect(result, isA<GoalServiceFailureResult<dynamic>>());
      expect(
        (result as GoalServiceFailureResult).reason,
        GoalServiceFailure.cheatDayQuotaExhausted,
      );
      expect(store.cheatDays, hasLength(1));
    });

    test(
      'AC 2: the quota resets to a fresh count in the next Evaluation Period '
      '— a Cheat Day used in week 1 does not count against week 2',
      () async {
        final goalId = await createWeeklyGoal(cheatDayQuota: 1);
        await goalService.markCheatDay(goalId: goalId, date: '2026-08-04');
        // Week 1 (Mon 2026-08-03 – Sun 2026-08-09) quota is now exhausted.
        final stillWeekOne = await goalService.markCheatDay(
          goalId: goalId,
          date: '2026-08-06',
        );
        expect(
          (stillWeekOne as GoalServiceFailureResult).reason,
          GoalServiceFailure.cheatDayQuotaExhausted,
        );

        // Week 2 (Mon 2026-08-10 – Sun 2026-08-16) is a fresh quota.
        final weekTwo = await goalService.markCheatDay(
          goalId: goalId,
          date: '2026-08-10',
        );

        expect(weekTwo, isA<GoalServiceSuccess<dynamic>>());
        expect(store.cheatDays, hasLength(2));
      },
    );

    test('a Cheat Day marked against a past date is checked against that '
        "date's Version quota, not the goal's current Version (Story 2.1 "
        'per-date resolution principle)', () async {
      final createResult = await goalService.createGoal(
        name: 'Read',
        startDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
        cheatDayQuota: 0,
      );
      final goal = (createResult as Success).value;

      // A later Version raises the quota to 1, effective 2026-08-10 —
      // the earlier days remain governed by the original quota: 0 Version.
      await goalService.editGoalVersion(
        goalId: goal.id,
        effectiveDate: '2026-08-10',
        newRules: const GoalVersionDraft(
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.exactly,
          targetValue: '1',
          trackingType: TrackingType.boolean,
          cheatDayQuota: 1,
        ),
      );

      final pastDateResult = await goalService.markCheatDay(
        goalId: goal.id,
        date: '2026-08-05',
      );
      final laterDateResult = await goalService.markCheatDay(
        goalId: goal.id,
        date: '2026-08-11',
      );

      expect(
        (pastDateResult as GoalServiceFailureResult).reason,
        GoalServiceFailure.cheatDayQuotaExhausted,
      );
      expect(laterDateResult, isA<GoalServiceSuccess<dynamic>>());
      expect(store.cheatDays, hasLength(1));
      expect(store.cheatDays.single.date, '2026-08-11');
    });

    test(
      'a kill mid-transaction leaves zero partial rows (Transaction atomicity)',
      () async {
        final goalId = await createWeeklyGoal(cheatDayQuota: 1);

        cheatDayRepository.shouldFailOnInsert = true;
        await expectLater(
          goalService.markCheatDay(goalId: goalId, date: '2026-08-04'),
          throwsA(isA<StateError>()),
        );

        expect(store.cheatDays, isEmpty);
      },
    );
  });

  group('markDnf (Story 2.5)', () {
    Future<String> createDailyGoal() async {
      final result = await goalService.createGoal(
        name: 'Read',
        startDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );
      return (result as Success).value.id;
    }

    test(
      'AC 1: marking a currently-Pending eligible day succeeds, inserting a '
      'placeholder log with the flag set',
      () async {
        final goalId = await createDailyGoal();

        final result = await goalService.markDnf(
          goalId: goalId,
          date: '2026-08-15',
          today: DateTime(2026, 8, 15),
        );

        expect(result, isA<GoalServiceSuccess<dynamic>>());
        expect(store.logs, hasLength(1));
        expect(store.logs.single.goalId, goalId);
        expect(store.logs.single.date, '2026-08-15');
        expect(store.logs.single.dnfMarked, isTrue);
        expect(store.logs.single.completed, isFalse);
        expect(store.logs.single.value, 0);
      },
    );

    test(
      'Task 2.3: DNF on a day with an existing (still-Pending) log only '
      "flips dnfMarked, never touching the log's own value",
      () async {
        final createResult = await goalService.createGoal(
          name: 'Water',
          startDate: '2026-08-01',
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.atLeast,
          targetValue: '8',
          trackingType: TrackingType.counter,
        );
        final goal = (createResult as Success).value;
        await goalService.logCounter(
          goalId: goal.id,
          date: '2026-08-15',
          delta: 3,
        );

        final result = await goalService.markDnf(
          goalId: goal.id,
          date: '2026-08-15',
          today: DateTime(2026, 8, 15),
        );

        expect(result, isA<GoalServiceSuccess<dynamic>>());
        expect(store.logs, hasLength(1));
        expect(store.logs.single.dnfMarked, isTrue);
        expect(store.logs.single.value, 3);
      },
    );

    test(
      'AC 2: a date preceding the goal (never eligible) is rejected with '
      'notEligibleOrAlreadyResolved, writing nothing',
      () async {
        final goalId = await createDailyGoal();

        final result = await goalService.markDnf(
          goalId: goalId,
          date: '2026-07-25',
        );

        expect(result, isA<GoalServiceFailureResult<dynamic>>());
        expect(
          (result as GoalServiceFailureResult).reason,
          GoalServiceFailure.notEligibleOrAlreadyResolved,
        );
        expect(store.logs, isEmpty);
      },
    );

    test(
      'AC 2: a date whose period already resolved to Fail is rejected, '
      'leaving the existing log untouched',
      () async {
        final goalId = await createDailyGoal();
        await goalService.logBoolean(
          goalId: goalId,
          date: '2026-08-15',
          completed: false,
        );

        final result = await goalService.markDnf(
          goalId: goalId,
          date: '2026-08-15',
        );

        expect(result, isA<GoalServiceFailureResult<dynamic>>());
        expect(
          (result as GoalServiceFailureResult).reason,
          GoalServiceFailure.notEligibleOrAlreadyResolved,
        );
        expect(store.logs, hasLength(1));
        expect(store.logs.single.dnfMarked, isFalse);
      },
    );

    test(
      'AC 2/3 regression: a DNF mark made while Pending is silently '
      "superseded once the period actually resolves — evaluate()'s output "
      'never references the flag',
      () async {
        final createResult = await goalService.createGoal(
          name: 'Read',
          startDate: '2026-08-03', // a Monday
          evaluationPeriod: EvaluationPeriod.weekly,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.atLeast,
          targetValue: '1',
          trackingType: TrackingType.boolean,
        );
        final goal = (createResult as Success).value;

        final dnfResult = await goalService.markDnf(
          goalId: goal.id,
          date: '2026-08-04',
          today: DateTime(2026, 8, 4),
        );
        expect(dnfResult, isA<GoalServiceSuccess<dynamic>>());
        expect(store.logs.single.dnfMarked, isTrue);

        // Logging a real Success elsewhere in the same week closes the
        // period out — the DNF placeholder never itself fed evaluate().
        await goalService.logBoolean(
          goalId: goal.id,
          date: '2026-08-05',
          completed: true,
        );

        final status = evaluate(
          goal: goal,
          versions: await goalVersionRepository.findAllForGoal(goal.id),
          logs: await goalLogRepository.findAllForGoal(goal.id),
          date: DateTime.parse('2026-08-04'),
        );

        expect(status.status, DayStatusValue.success);
      },
    );

    test(
      'a kill mid-transaction leaves zero partial rows (Transaction '
      'atomicity)',
      () async {
        final goalId = await createDailyGoal();

        goalLogRepository.shouldFailOnUpsert = true;
        await expectLater(
          goalService.markDnf(
            goalId: goalId,
            date: '2026-08-15',
            today: DateTime(2026, 8, 15),
          ),
          throwsA(isA<StateError>()),
        );

        expect(store.logs, isEmpty);
      },
    );
  });

  group('updateGoalCategory (Story 3.5)', () {
    Future<Goal> createGoalWithoutCategory() async {
      final result = await goalService.createGoal(
        name: 'Read',
        startDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );
      return (result as Success).value;
    }

    test(
      'Subtask 5.1: persists the category through GoalService and creates '
      'no spurious GoalVersion row',
      () async {
        final goal = await createGoalWithoutCategory();
        expect(store.versions, hasLength(1));

        final result = await goalService.updateGoalCategory(
          goalId: goal.id,
          category: 'Health',
        );

        expect(result, isA<GoalServiceSuccess<dynamic>>());
        expect(store.goals.single.category, 'Health');
        // No new GoalVersion segment was written for a metadata-only edit
        // (AD-6: category lives on GOAL, never GOAL_VERSION).
        expect(store.versions, hasLength(1));
      },
    );

    test('a null category clears an existing assignment back to none', () async {
      final goal = await createGoalWithoutCategory();
      await goalService.updateGoalCategory(goalId: goal.id, category: 'Health');

      await goalService.updateGoalCategory(goalId: goal.id, category: null);

      expect(store.goals.single.category, isNull);
    });

    test('an empty/whitespace-only category also clears the assignment', () async {
      final goal = await createGoalWithoutCategory();
      await goalService.updateGoalCategory(goalId: goal.id, category: 'Health');

      await goalService.updateGoalCategory(goalId: goal.id, category: '   ');

      expect(store.goals.single.category, isNull);
    });
  });

  group('Story 6.2 — GoalService import methods', () {
    test(
      'importGoal preserves the exact caller-supplied id, unlike createGoal',
      () async {
        final goal = Goal(
          id: 'file-goal-1',
          name: 'Restored Goal',
          archived: false,
          startDate: '2026-01-01',
        );

        await goalService.importGoal(goal);

        expect(store.goals, [goal]);
      },
    );

    test('importGoal upserts: a second call with the same id overwrites', () async {
      await goalService.importGoal(
        const Goal(
          id: 'file-goal-1',
          name: 'Original',
          archived: false,
          startDate: '2026-01-01',
        ),
      );
      await goalService.importGoal(
        const Goal(
          id: 'file-goal-1',
          name: 'Renamed',
          archived: false,
          startDate: '2026-01-01',
        ),
      );

      expect(store.goals, hasLength(1));
      expect(store.goals.single.name, 'Renamed');
    });

    test(
      'importVersion preserves the exact caller-supplied id, never running '
      'the versionLocked collision check',
      () async {
        final version = GoalVersion(
          id: 'file-version-1',
          goalId: 'file-goal-1',
          versionStartDate: '2026-01-01',
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.atLeast,
          targetValue: '1',
          trackingType: TrackingType.boolean,
        );

        await goalService.importVersion(version);

        expect(store.versions, [version]);
      },
    );

    test(
      'importLog preserves the exact caller-supplied id/timestamp/value, '
      'unlike logCounter\'s delta-add-and-floor semantics',
      () async {
        final log = GoalLog(
          id: 'file-log-1',
          goalId: 'file-goal-1',
          date: '2026-01-02',
          timestamp: '2026-01-02T08:00:00',
          value: 5,
          completed: true,
        );

        await goalService.importLog(log);

        expect(store.logs, [log]);
      },
    );

    test(
      'importCheatDay preserves the exact caller-supplied id and bypasses '
      'the live cheatDayQuota gate',
      () async {
        final cheatDay = CheatDay(
          id: 'file-cheat-1',
          goalId: 'file-goal-1',
          date: '2026-01-03',
        );

        await goalService.importCheatDay(cheatDay);

        expect(store.cheatDays, [cheatDay]);
      },
    );

    test(
      'importBlackoutDate preserves the exact caller-supplied id',
      () async {
        final blackoutDate = BlackoutDate(
          id: 'file-blackout-1',
          goalId: 'file-goal-1',
          date: '2026-01-04',
        );

        await goalService.importBlackoutDate(blackoutDate);

        expect(store.blackoutDates, [blackoutDate]);
      },
    );

    test(
      'finalizeImport rebuilds the status cache and syncs the widget bridge',
      () async {
        final goal = Goal(
          id: 'file-goal-1',
          name: 'Restored Goal',
          archived: false,
          startDate: '2026-01-01',
        );
        await goalService.importGoal(goal);
        await goalService.importVersion(
          GoalVersion(
            id: 'file-version-1',
            goalId: goal.id,
            versionStartDate: '2026-01-01',
            evaluationPeriod: EvaluationPeriod.daily,
            eligibleDaysRule: EligibleDaysRule.everyDay,
            targetComparison: TargetComparison.atLeast,
            targetValue: '1',
            trackingType: TrackingType.boolean,
          ),
        );
        expect(store.statusCache, isEmpty);

        await goalService.finalizeImport();

        expect(store.statusCache, isNotEmpty);
      },
    );
  });

  group('resetAll (Story 6.3)', () {
    late _FakeReminderSettingsRepository reminderSettingsRepository;
    late _FakeWeekStartSettingsRepository weekStartSettingsRepository;

    setUp(() {
      reminderSettingsRepository = _FakeReminderSettingsRepository();
      weekStartSettingsRepository = _FakeWeekStartSettingsRepository();
    });

    /// Populates every domain table plus the settings fakes, mirroring a
    /// Panda who has actually used the app — resetAll must wipe all of it.
    Future<void> populate() async {
      final goal = Goal(
        id: 'goal-1',
        name: 'Read',
        archived: false,
        startDate: '2026-08-01',
      );
      store.goals.add(goal);
      store.versions.add(
        GoalVersion(
          id: 'version-1',
          goalId: goal.id,
          versionStartDate: '2026-08-01',
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
          date: '2026-08-01',
          timestamp: '2026-08-01T08:00:00',
          value: 1,
          completed: true,
        ),
      );
      store.cheatDays.add(
        CheatDay(id: 'cheat-1', goalId: goal.id, date: '2026-08-02'),
      );
      store.blackoutDates.add(
        BlackoutDate(id: 'blackout-1', goalId: goal.id, date: '2026-08-03'),
      );
      store.statusCache['${goal.id}|2026-08-01'] = DayStatus(
        goalId: goal.id,
        date: '2026-08-01',
        status: DayStatusValue.success,
      );
      reminderSettingsRepository.stored = const TimeOfDayValue(
        hour: 7,
        minute: 30,
      );
      weekStartSettingsRepository.stored = WeekStart.sunday;
    }

    test(
      'Subtask 4.1/4.2: wipes every domain table and every settings value',
      () async {
        await populate();

        await goalService.resetAll(
          reminderSettingsRepository: reminderSettingsRepository,
          weekStartSettingsRepository: weekStartSettingsRepository,
        );

        expect(store.goals, isEmpty);
        expect(store.versions, isEmpty);
        expect(store.logs, isEmpty);
        expect(store.cheatDays, isEmpty);
        expect(store.blackoutDates, isEmpty);
        expect(store.statusCache, isEmpty);
        expect(reminderSettingsRepository.stored, isNull);
        expect(weekStartSettingsRepository.stored, isNull);
      },
    );

    test(
      'Subtask 4.3: a mid-transaction failure leaves every table untouched '
      '(all-or-nothing)',
      () async {
        await populate();
        goalRepository.shouldFailOnDeleteAll = true;

        await expectLater(
          () => goalService.resetAll(
            reminderSettingsRepository: reminderSettingsRepository,
            weekStartSettingsRepository: weekStartSettingsRepository,
          ),
          throwsStateError,
        );

        expect(store.goals, hasLength(1));
        expect(store.versions, hasLength(1));
        expect(store.logs, hasLength(1));
        expect(store.cheatDays, hasLength(1));
        expect(store.blackoutDates, hasLength(1));
        expect(store.statusCache, isNotEmpty);
        // The settings clear only runs after the transaction commits
        // successfully, so a transaction failure must also leave these
        // untouched.
        expect(reminderSettingsRepository.stored, isNotNull);
        expect(weekStartSettingsRepository.stored, isNotNull);
      },
    );
  });
}
