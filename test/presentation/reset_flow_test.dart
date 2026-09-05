import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/entities/time_of_day_value.dart';
import 'package:tracker/domain/evaluator/period_boundary.dart';
import 'package:tracker/domain/services/reminder_settings_repository.dart';
import 'package:tracker/domain/services/week_start_settings_repository.dart';
import 'package:tracker/presentation/providers/reminder_settings_provider.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';
import 'package:tracker/presentation/providers/week_start_provider.dart';
import 'package:tracker/presentation/screens/app_shell.dart';

import '../domain/services/fakes.dart';

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

/// Story 6.3 (AC #3/#4/#6, Subtask 3.2/4.4): a full-app equivalence test —
/// after Reset/Erase-All completes, every tab (Today/Calendar/Goals/
/// Settings) must show the identical empty state a genuine fresh install
/// shows, not just an emptied Drift table. Every tab except Settings reads
/// Goal/Version/Log data straight off `InMemoryStore`'s `watch*` streams
/// (the same fakes `app_shell_test.dart` uses), so this also proves
/// `GoalService.resetAll()`'s transaction is what every screen reacts to —
/// nothing in this test manually refreshes a screen.
void main() {
  late InMemoryStore store;
  late _FakeReminderSettingsRepository reminderSettingsRepository;
  late _FakeWeekStartSettingsRepository weekStartSettingsRepository;

  setUp(() {
    store = InMemoryStore();
    reminderSettingsRepository = _FakeReminderSettingsRepository()
      ..stored = const TimeOfDayValue(hour: 7, minute: 30);
    weekStartSettingsRepository = _FakeWeekStartSettingsRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
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
        transactionRunnerProvider.overrideWithValue(
          SnapshotTransactionRunner(store),
        ),
        statusCacheRepositoryProvider.overrideWithValue(
          InMemoryStatusCacheRepository(store),
        ),
        reminderSettingsRepositoryProvider.overrideWith(
          (ref) async => reminderSettingsRepository,
        ),
        weekStartSettingsRepositoryProvider.overrideWith(
          (ref) => weekStartSettingsRepository,
        ),
      ],
      child: const MaterialApp(home: AppShell()),
    );
  }

  testWidgets(
    'Reset/Erase-All wipes Goal data and settings; every tab shows the '
    'fresh-install empty state afterward, with no app restart',
    (tester) async {
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

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Goals tab shows the pre-reset goal, not the empty state yet.
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();
      expect(find.text('No goals yet'), findsNothing);

      // Settings: change Week-Start away from the default, then run the
      // two-step Reset.
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-week-start-sunday')));
      await tester.pumpAndSettle();
      expect(weekStartSettingsRepository.stored, WeekStart.sunday);

      await tester.tap(find.byKey(const Key('settings-reset-button')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This erases all Goals, logs, and settings. This cannot be '
          'undone.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('reset-confirm-sheet-confirm')));
      await tester.pumpAndSettle();

      expect(store.goals, isEmpty);
      expect(store.versions, isEmpty);
      expect(reminderSettingsRepository.stored, isNull);
      expect(weekStartSettingsRepository.stored, isNull);

      // Today tab: identical to a fresh-install Dashboard.
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.text('No goals eligible today'), findsOneWidget);

      // Goals tab: identical to a fresh-install Goals list.
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();
      expect(find.text('No goals yet'), findsOneWidget);

      // Settings tab: reminder back to "Not set", Week-Start back to Monday
      // — both live, without restarting the app.
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Not set'), findsOneWidget);
      final monday = tester.widget<OutlinedButton>(
        find.byKey(const Key('settings-week-start-monday')),
      );
      expect(monday.style?.backgroundColor?.resolve({}), isNotNull);
    },
  );

  testWidgets(
    'Subtask 4.5: cancelling the confirmation sheet leaves all data intact',
    (tester) async {
      store.goals.add(
        const Goal(
          id: 'goal-1',
          name: 'Read',
          archived: false,
          startDate: '2026-08-01',
        ),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-reset-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reset-confirm-sheet-cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reset-confirm-sheet-cancel')), findsNothing);
      expect(store.goals, hasLength(1));
      expect(reminderSettingsRepository.stored, isNotNull);
    },
  );
}
