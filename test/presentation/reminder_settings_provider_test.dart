import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/entities/time_of_day_value.dart';
import 'package:tracker/domain/services/reminder_scheduler.dart';
import 'package:tracker/domain/services/reminder_settings_repository.dart';
import 'package:tracker/presentation/providers/current_date_provider.dart';
import 'package:tracker/presentation/providers/reminder_settings_provider.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';

import '../domain/services/fakes.dart';

/// In-memory fake standing in for `SharedPrefsReminderSettingsRepository` —
/// exercises [ReminderTimeController] without any real `shared_preferences`
/// I/O (Story 4.1 Dev Notes: "fully unit-testable with fakes/mocks").
class FakeReminderSettingsRepository implements ReminderSettingsRepository {
  TimeOfDayValue? stored;

  @override
  Future<TimeOfDayValue?> getReminderTime() async => stored;

  @override
  Future<void> setReminderTime(TimeOfDayValue time) async => stored = time;

  @override
  Future<void> clear() async => stored = null;
}

/// Records every call made to it, standing in for the
/// `flutter_local_notifications`-backed scheduler (Subtask 4.2's "mock
/// ReminderScheduler").
class FakeReminderScheduler implements ReminderScheduler {
  final List<TimeOfDayValue> scheduledTimes = [];

  /// Every [ReminderContent] resolved by a `contentBuilder` call — Story
  /// 4.2 Subtask 3.2's seam for verifying suppression: a `null` entry is
  /// what the real `FlutterLocalNotificationsReminderScheduler` treats as
  /// "cancel, do not fire" (AC #5), so asserting on this list stands in for
  /// asserting against the real notification-firing plugin API without any
  /// real device/plugin I/O.
  final List<ReminderContent?> builtContent = [];
  int cancelCallCount = 0;
  bool initializeCalled = false;

  @override
  Future<void> initialize() async => initializeCalled = true;

  @override
  Future<void> scheduleDaily({
    required TimeOfDayValue time,
    required ReminderContentBuilder contentBuilder,
  }) async {
    scheduledTimes.add(time);
    builtContent.add(await contentBuilder());
  }

  @override
  Future<void> cancel() async => cancelCallCount++;
}

void main() {
  late FakeReminderSettingsRepository repository;
  late FakeReminderScheduler scheduler;
  late InMemoryStore store;

  Widget buildApp({required Widget child}) {
    return ProviderScope(
      overrides: [
        reminderSettingsRepositoryProvider.overrideWith((ref) => repository),
        reminderSchedulerProvider.overrideWith((ref) => scheduler),
        // Story 4.2's contentBuilder reads every Goal's evaluate() inputs —
        // these stand in for the real Drift-backed repositories so
        // `setReminderTime`'s reschedule call never touches a real database.
        goalRepositoryProvider.overrideWithValue(InMemoryGoalRepository(store)),
        goalVersionRepositoryProvider.overrideWithValue(
          InMemoryGoalVersionRepository(store),
        ),
        goalLogRepositoryProvider.overrideWithValue(
          InMemoryGoalLogRepository(store),
        ),
        blackoutDateRepositoryProvider.overrideWithValue(
          InMemoryBlackoutDateRepository(store),
        ),
        cheatDayRepositoryProvider.overrideWithValue(
          InMemoryCheatDayRepository(store),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  setUp(() {
    repository = FakeReminderSettingsRepository();
    scheduler = FakeReminderScheduler();
    store = InMemoryStore();
  });

  testWidgets(
    'setReminderTime writes through the repository and triggers a reschedule '
    'call on the scheduler (Subtask 1.4/2.4)',
    (tester) async {
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        buildApp(
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await capturedRef
          .read(reminderTimeControllerProvider.notifier)
          .setReminderTime(const TimeOfDayValue(hour: 7, minute: 30));

      expect(repository.stored, const TimeOfDayValue(hour: 7, minute: 30));
      expect(scheduler.scheduledTimes, [
        const TimeOfDayValue(hour: 7, minute: 30),
      ]);
    },
  );

  testWidgets(
    'reminderTimeProvider reflects the newly-set time reactively after '
    'setReminderTime completes',
    (tester) async {
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        buildApp(
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        await capturedRef.read(reminderTimeProvider.future),
        isNull,
      );

      await capturedRef
          .read(reminderTimeControllerProvider.notifier)
          .setReminderTime(const TimeOfDayValue(hour: 20, minute: 15));
      await tester.pumpAndSettle();

      expect(
        await capturedRef.read(reminderTimeProvider.future),
        const TimeOfDayValue(hour: 20, minute: 15),
      );
    },
  );

  group('Story 4.2 — suppression-aware content (Subtask 3.2)', () {
    testWidgets(
      'an empty remindable-goal set results in no notification content '
      'being built, so the scheduler never fires (AC #5)',
      (tester) async {
        final today = todayDateOnly();
        final todayStr =
            '${today.year.toString().padLeft(4, '0')}-'
            '${today.month.toString().padLeft(2, '0')}-'
            '${today.day.toString().padLeft(2, '0')}';

        final goal = Goal(
          id: 'goal-1',
          name: 'Coffee',
          archived: false,
          startDate: '2020-01-01',
        );
        final version = GoalVersion(
          id: 'version-1',
          goalId: goal.id,
          versionStartDate: '2020-01-01',
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.atMost,
          targetValue: '2',
          trackingType: TrackingType.counter,
        );
        final log = GoalLog(
          id: 'log-1',
          goalId: goal.id,
          date: todayStr,
          timestamp: '${todayStr}T09:00:00',
          value: 2,
          completed: true,
        );
        store.goals.add(goal);
        store.versions.add(version);
        store.logs.add(log);

        late WidgetRef capturedRef;
        await tester.pumpWidget(
          buildApp(
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await capturedRef
            .read(reminderTimeControllerProvider.notifier)
            .setReminderTime(const TimeOfDayValue(hour: 7, minute: 30));

        expect(scheduler.builtContent, [null]);
      },
    );

    testWidgets(
      'a non-empty remindable-goal set results in exactly one call with the '
      'correctly filtered goal list in its content',
      (tester) async {
        final remindableGoal = Goal(
          id: 'goal-remindable',
          name: 'Water',
          archived: false,
          startDate: '2020-01-01',
        );
        final remindableVersion = GoalVersion(
          id: 'version-remindable',
          goalId: remindableGoal.id,
          versionStartDate: '2020-01-01',
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.atLeast,
          targetValue: '8',
          trackingType: TrackingType.counter,
        );

        final suppressedGoal = Goal(
          id: 'goal-suppressed',
          name: 'Archived Goal',
          archived: true,
          startDate: '2020-01-01',
        );
        final suppressedVersion = GoalVersion(
          id: 'version-suppressed',
          goalId: suppressedGoal.id,
          versionStartDate: '2020-01-01',
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.atLeast,
          targetValue: '1',
          trackingType: TrackingType.counter,
        );

        store.goals.addAll([remindableGoal, suppressedGoal]);
        store.versions.addAll([remindableVersion, suppressedVersion]);

        late WidgetRef capturedRef;
        await tester.pumpWidget(
          buildApp(
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await capturedRef
            .read(reminderTimeControllerProvider.notifier)
            .setReminderTime(const TimeOfDayValue(hour: 7, minute: 30));

        expect(scheduler.builtContent, hasLength(1));
        final content = scheduler.builtContent.single;
        expect(content, isNotNull);
        expect(content!.body, contains('Water'));
        expect(content.body, isNot(contains('Archived Goal')));
      },
    );
  });
}
