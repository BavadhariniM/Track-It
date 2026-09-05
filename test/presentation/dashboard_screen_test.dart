import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/entities/time_of_day_value.dart';
import 'package:tracker/domain/evaluator/date_format.dart';
import 'package:tracker/presentation/providers/reminder_settings_provider.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';
import 'package:tracker/presentation/components/counter_stepper.dart';
import 'package:tracker/presentation/screens/dashboard_screen.dart';
import 'package:tracker/presentation/screens/goal_detail_screen.dart';

import '../domain/services/fakes.dart';

/// Story 3.1 Subtask 5.3.
void main() {
  late InMemoryStore store;

  const goal = Goal(
    id: 'goal-1',
    name: 'Read',
    archived: false,
    startDate: '2020-01-01',
  );
  final version = GoalVersion(
    id: 'version-1',
    goalId: goal.id,
    versionStartDate: '2020-01-01',
    evaluationPeriod: EvaluationPeriod.daily,
    eligibleDaysRule: EligibleDaysRule.everyDay,
    targetComparison: TargetComparison.exactly,
    targetValue: '1',
    trackingType: TrackingType.boolean,
  );

  Widget buildApp({TimeOfDayValue? reminderTime}) {
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
        reminderTimeProvider.overrideWith((ref) async => reminderTime),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    );
  }

  setUp(() {
    store = InMemoryStore()
      ..goals.add(goal)
      ..versions.add(version);
  });

  testWidgets(
    'renders a goal-row for a goal eligible today, and both rollup section '
    'headers (AC 1, AC 2)',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Read'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
    },
  );

  testWidgets('renders the next reminder time when configured (AC 3)', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(reminderTime: const TimeOfDayValue(hour: 7, minute: 30)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('07:30'), findsOneWidget);
  });

  testWidgets(
    'renders nothing for the reminder time when unset, rather than an error '
    'or placeholder (Subtask 4.5)',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('Next reminder'), findsNothing);
    },
  );

  testWidgets('shows an empty state when no goals are eligible today', (
    tester,
  ) async {
    store = InMemoryStore();
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('No goals eligible today'), findsOneWidget);
  });

  group('Bug 8: split tap zones', () {
    testWidgets('tapping the name area navigates to Goal Detail', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Read'));
      await tester.pumpAndSettle();

      expect(find.byType(GoalDetailScreen), findsOneWidget);
    });

    testWidgets(
      'tapping the right/status side of an unlogged boolean goal marks it '
      'done for today',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(store.logs, isEmpty);

        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        expect(store.logs, hasLength(1));
        final log = store.logs.single;
        expect(log.goalId, goal.id);
        expect(log.date, formatDateOnly(DateTime.now()));
        expect(log.completed, isTrue);
      },
    );

    testWidgets('tapping it again undoes today\'s completion', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(store.logs, hasLength(1));

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(store.logs, isEmpty);
    });

    testWidgets(
      'tapping the right side of a counter goal opens the shared stepper '
      'dialog scoped to today',
      (tester) async {
        const counterGoal = Goal(
          id: 'goal-2',
          name: 'Water',
          archived: false,
          startDate: '2020-01-01',
        );
        final counterVersion = GoalVersion(
          id: 'version-2',
          goalId: counterGoal.id,
          versionStartDate: '2020-01-01',
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.atLeast,
          targetValue: '8',
          trackingType: TrackingType.counter,
        );
        store = InMemoryStore()
          ..goals.add(counterGoal)
          ..versions.add(counterVersion);

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // The counter row's trailing area renders "current/target".
        await tester.tap(find.textContaining('/8'));
        await tester.pumpAndSettle();

        final dialog = tester.widget<CounterStepperDialog>(
          find.byType(CounterStepperDialog),
        );
        expect(dialog.goal.id, counterGoal.id);
        expect(formatDateOnly(dialog.date), formatDateOnly(DateTime.now()));
      },
    );

    testWidgets(
      'tapping the right side still logs today\'s own action even when '
      'today\'s period already resolved via a different date — the row '
      'renders evaluateDayOnly(), not the period aggregate, so an '
      'already-resolved period no longer blocks logging today separately',
      (tester) async {
        // Use a Monthly period so the "another date within the period" test
        // fixture is deterministic regardless of which real-world weekday
        // the suite runs on (a Weekly fixture would need to account for the
        // configurable week-start setting).
        final now = DateTime.now();
        final resolvedDate = now.day == 1
            ? DateTime(now.year, now.month, 2)
            : DateTime(now.year, now.month, 1);
        final monthlyVersion = GoalVersion(
          id: 'version-1',
          goalId: goal.id,
          versionStartDate: '2020-01-01',
          evaluationPeriod: EvaluationPeriod.monthly,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.atLeast,
          targetValue: '1',
          trackingType: TrackingType.boolean,
        );
        store = InMemoryStore()
          ..goals.add(goal)
          ..versions.add(monthlyVersion)
          ..logs.add(
            GoalLog(
              id: 'resolved-log',
              goalId: goal.id,
              date: formatDateOnly(resolvedDate),
              timestamp: '${formatDateOnly(resolvedDate)}T08:00:00',
              value: 1,
              completed: true,
            ),
          );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(store.logs, hasLength(1));

        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        // A second log, for today specifically, was written — the
        // pre-existing resolvedDate log is untouched, and today's own
        // action is now tracked independently of the period's outcome.
        expect(store.logs, hasLength(2));
        expect(
          store.logs.any(
            (log) =>
                log.id != 'resolved-log' &&
                log.date == formatDateOnly(DateTime.now()) &&
                log.completed,
          ),
          isTrue,
        );
      },
    );

    testWidgets('long-pressing a row opens the Cheat Day/Blackout sheet', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Read'));
      await tester.pumpAndSettle();

      expect(find.text('Mark as Blackout Date'), findsWidgets);
    });
  });
}
