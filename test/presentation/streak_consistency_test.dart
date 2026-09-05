import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/date_format.dart';
import 'package:tracker/presentation/providers/reminder_settings_provider.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';
import 'package:tracker/presentation/screens/dashboard_screen.dart';
import 'package:tracker/presentation/screens/goal_detail_screen.dart';

import '../domain/services/fakes.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Story 3.3 AC 4/Subtask 4.6: `StatsService` (AD-8) is the sole streak
/// computer, so Dashboard and Goal Detail must never disagree about a
/// goal's streak — both call through the exact same [StatsService] method
/// (Story 3.3 Subtask 2.1's `_streakWalk`), so a mismatch here would mean
/// one screen regressed to a stopgap local computation.
void main() {
  late InMemoryStore store;
  late Goal goal;

  overrides() => [
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
    reminderTimeProvider.overrideWith((ref) async => null),
  ];

  setUp(() {
    store = InMemoryStore();
  });

  testWidgets(
    'a Daily goal renders the exact same streak number on Dashboard and '
    'Goal Detail (AC 4)',
    (tester) async {
      // Daily, not Weekly/Monthly: an unlogged "today" always resolves to
      // Pending unconditionally (no remaining-eligible-days ambiguity), so
      // this fixture stays deterministic regardless of test-run day —
      // unlike a period-type goal, a Daily goal also never needs to be
      // Paused to render on Dashboard, which only shows active goals.
      final goalStart = _today().subtract(const Duration(days: 5));
      goal = Goal(
        id: 'goal-1',
        name: 'Read',
        archived: false,
        startDate: formatDateOnly(goalStart),
      );
      store.goals.add(goal);
      store.versions.add(
        GoalVersion(
          id: 'version-1',
          goalId: goal.id,
          versionStartDate: formatDateOnly(goalStart),
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.exactly,
          targetValue: '1',
          trackingType: TrackingType.boolean,
        ),
      );
      // 3 consecutive successful days trailing up to today (left
      // unlogged/Pending, excluded) -> expected streak (current and
      // longest) is 3.
      for (final daysAgo in [3, 2, 1]) {
        final date = formatDateOnly(_today().subtract(Duration(days: daysAgo)));
        store.logs.add(
          GoalLog(
            id: 'log-$date',
            goalId: goal.id,
            date: date,
            timestamp: '${date}T09:00:00',
            value: 1,
            completed: true,
          ),
        );
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Streak: 3'), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: MaterialApp(home: GoalDetailScreen(goal: goal)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('goal-detail-current-streak-card')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('goal-detail-longest-streak-card')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a Rolling Window goal shows no Streak stat on either screen — Dashboard '
    'omits the "Streak:" row label, Goal Detail substitutes the current '
    'pace card (AC 3)',
    (tester) async {
      final goalStart = _today().subtract(const Duration(days: 20));
      goal = Goal(
        id: 'goal-rolling',
        name: 'Workout 10x in any 14 days',
        archived: false,
        startDate: formatDateOnly(goalStart),
      );
      store.goals.add(goal);
      store.versions.add(
        GoalVersion(
          id: 'version-rolling',
          goalId: goal.id,
          versionStartDate: formatDateOnly(goalStart),
          evaluationPeriod: EvaluationPeriod.rollingWindow(14),
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.atLeast,
          targetValue: '10',
          trackingType: TrackingType.counter,
        ),
      );
      for (var daysAgo = 1; daysAgo <= 5; daysAgo++) {
        final date = formatDateOnly(_today().subtract(Duration(days: daysAgo)));
        store.logs.add(
          GoalLog(
            id: 'log-$date',
            goalId: goal.id,
            date: date,
            timestamp: '${date}T09:00:00',
            value: 2,
            completed: true,
          ),
        );
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Streak:'), findsNothing);

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: MaterialApp(home: GoalDetailScreen(goal: goal)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('goal-detail-current-streak-card')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('goal-detail-longest-streak-card')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('goal-detail-current-pace-card')),
        findsOneWidget,
      );
      // Counter goal: numeric current/target fraction, not a status word.
      expect(find.text('10/10'), findsOneWidget);
    },
  );
}
