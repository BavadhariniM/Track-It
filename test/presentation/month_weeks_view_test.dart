import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/presentation/components/status_cell.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';
import 'package:tracker/presentation/screens/month_weeks_view.dart';

import '../domain/services/fakes.dart';

/// Covers `MonthWeeksViewScreen`'s three per-goal-period-type week-cell
/// rules (Daily/Weekly/Monthly), each exercised against a FIXED, wholly
/// past month (August 2026 — this test environment's real clock is already
/// past that month, so every day within it is permanently "elapsed," which
/// makes Success/Fail outcomes deterministic without any Pending-state
/// timing flakiness), plus month-to-month paging.
void main() {
  late InMemoryStore store;

  const dailyGoal = Goal(
    id: 'goal-daily',
    name: 'Meditate',
    archived: false,
    startDate: '2020-01-01',
  );
  const weeklyGoal = Goal(
    id: 'goal-weekly',
    name: 'Read',
    archived: false,
    startDate: '2020-01-01',
  );
  const monthlyGoal = Goal(
    id: 'goal-monthly',
    name: 'Review',
    archived: false,
    startDate: '2020-01-01',
  );

  GoalVersion dailyVersion() => const GoalVersion(
    id: 'v-daily',
    goalId: 'goal-daily',
    versionStartDate: '2020-01-01',
    evaluationPeriod: EvaluationPeriod.daily,
    eligibleDaysRule: EligibleDaysRule.everyDay,
    targetComparison: TargetComparison.exactly,
    targetValue: '1',
    trackingType: TrackingType.boolean,
  );
  GoalVersion weeklyVersion() => const GoalVersion(
    id: 'v-weekly',
    goalId: 'goal-weekly',
    versionStartDate: '2020-01-01',
    evaluationPeriod: EvaluationPeriod.weekly,
    eligibleDaysRule: EligibleDaysRule.everyDay,
    targetComparison: TargetComparison.atLeast,
    targetValue: '1',
    trackingType: TrackingType.boolean,
  );
  GoalVersion monthlyVersion() => const GoalVersion(
    id: 'v-monthly',
    goalId: 'goal-monthly',
    versionStartDate: '2020-01-01',
    evaluationPeriod: EvaluationPeriod.monthly,
    eligibleDaysRule: EligibleDaysRule.everyDay,
    targetComparison: TargetComparison.exactly,
    targetValue: '1',
    trackingType: TrackingType.boolean,
  );

  GoalLog boolLog(String goalId, String date) => GoalLog(
    id: 'log-$goalId-$date',
    goalId: goalId,
    date: date,
    timestamp: '${date}T09:00:00.000',
    value: 1,
    completed: true,
  );

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
      ],
      child: MaterialApp(
        home: MonthWeeksViewScreen(initialMonth: DateTime(2026, 8)),
      ),
    );
  }

  /// No `initialMonth` override — defaults to the real current month, the
  /// same convention `month_view_test.dart`'s own paging tests use, so
  /// "jump to today" can be asserted to return to the page the screen
  /// opened on.
  Widget buildAppDefaultMonth() {
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
      ],
      child: const MaterialApp(home: MonthWeeksViewScreen()),
    );
  }

  List<StatusCell> cellsFor(WidgetTester tester, String goalId) {
    return tester
        .widgetList<StatusCell>(
          find.descendant(
            of: find.byKey(Key('month-weeks-goal-row-$goalId')),
            matching: find.byType(StatusCell),
          ),
        )
        .toList();
  }

  group('MonthWeeksViewScreen — per-goal-period-type week-cell rules', () {
    testWidgets(
      'Daily goal: a week with every day logged done is Success; a week '
      'with one elapsed unlogged day is Fail',
      (tester) async {
        store = InMemoryStore()
          ..goals.add(dailyGoal)
          ..versions.add(dailyVersion())
          ..logs.addAll([
            // Week of Mon 2026-08-03..09: every day logged done.
            for (var d = 3; d <= 9; d++)
              boolLog('goal-daily', '2026-08-${d.toString().padLeft(2, '0')}'),
            // Week of Mon 2026-08-10..16: every day EXCEPT the 12th.
            for (var d = 10; d <= 16; d++)
              if (d != 12)
                boolLog(
                  'goal-daily',
                  '2026-08-${d.toString().padLeft(2, '0')}',
                ),
          ]);

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final cells = cellsFor(tester, 'goal-daily');
        // Week-column order matches _weekStartsFor's Jul27/Aug3/Aug10/...
        // padding — index 1 is the Aug3 week, index 2 is the Aug10 week.
        expect(cells[1].status, DayStatusValue.success);
        expect(cells[2].status, DayStatusValue.fail);
      },
    );

    testWidgets(
      'Weekly goal: a week with its target met is Success; a week with no '
      'log at all, fully elapsed, is Fail',
      (tester) async {
        store = InMemoryStore()
          ..goals.add(weeklyGoal)
          ..versions.add(weeklyVersion())
          ..logs.add(boolLog('goal-weekly', '2026-08-05'));

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final cells = cellsFor(tester, 'goal-weekly');
        expect(cells[1].status, DayStatusValue.success); // Aug3 week: logged
        expect(cells[2].status, DayStatusValue.fail); // Aug10 week: unlogged
      },
    );

    testWidgets(
      'Monthly goal: one whole-month result is repeated across every '
      'week-column',
      (tester) async {
        store = InMemoryStore()
          ..goals.add(monthlyGoal)
          ..versions.add(monthlyVersion())
          ..logs.add(boolLog('goal-monthly', '2026-08-15'));

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final cells = cellsFor(tester, 'goal-monthly');
        expect(cells, isNotEmpty);
        for (final cell in cells) {
          expect(cell.status, DayStatusValue.success);
        }
      },
    );
  });

  group('MonthWeeksViewScreen — month-to-month paging', () {
    testWidgets('swiping left moves the header title to the adjacent month', (
      tester,
    ) async {
      store = InMemoryStore();
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      String titleText() => tester
          .widget<Text>(
            find.descendant(of: find.byType(AppBar), matching: find.byType(Text)),
          )
          .data!;

      final initialTitle = titleText();
      expect(initialTitle, contains('August 2026'));

      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(titleText(), isNot(initialTitle));
      expect(titleText(), contains('September 2026'));
    });

    testWidgets(
      '"jump to today" is reachable after navigating several months away',
      (tester) async {
        store = InMemoryStore();
        await tester.pumpWidget(buildAppDefaultMonth());
        await tester.pumpAndSettle();

        String titleText() => tester
            .widget<Text>(
              find.descendant(
                of: find.byType(AppBar),
                matching: find.byType(Text),
              ),
            )
            .data!;

        final initialTitle = titleText();

        for (var i = 0; i < 3; i++) {
          await tester.drag(find.byType(PageView), const Offset(-600, 0));
          await tester.pumpAndSettle();
        }
        expect(titleText(), isNot(initialTitle));

        await tester.tap(find.byTooltip('Jump to today'));
        await tester.pumpAndSettle();

        expect(titleText(), initialTitle);
      },
    );
  });
}
