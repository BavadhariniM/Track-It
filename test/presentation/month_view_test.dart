import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/date_format.dart';
import 'package:tracker/domain/evaluator/period_boundary.dart';
import 'package:tracker/main.dart';
import 'package:tracker/presentation/components/goal_row.dart';
import 'package:tracker/presentation/components/status_cell.dart';
import 'package:tracker/presentation/providers/reminder_settings_provider.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';
import 'package:tracker/presentation/providers/week_start_provider.dart';
import 'package:tracker/presentation/screens/day_view.dart';
import 'package:tracker/presentation/screens/month_view.dart';

import '../domain/services/fakes.dart';

void main() {
  late InMemoryStore store;

  const goal = Goal(
    id: 'goal-1',
    name: 'Read',
    archived: false,
    startDate: '2026-01-01',
  );

  GoalVersion dailyBooleanVersion() => GoalVersion(
    id: 'version-1',
    goalId: goal.id,
    versionStartDate: '2026-01-01',
    evaluationPeriod: EvaluationPeriod.daily,
    eligibleDaysRule: EligibleDaysRule.everyDay,
    targetComparison: TargetComparison.exactly,
    targetValue: '1',
    trackingType: TrackingType.boolean,
  );

  Widget buildApp({List<WeekStart> weekStartOverride = const []}) {
    store = InMemoryStore();
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
        if (weekStartOverride.isNotEmpty)
          weekStartSettingProvider.overrideWithValue(weekStartOverride.single),
      ],
      child: const MaterialApp(home: MonthViewScreen()),
    );
  }

  ({DateTime month, DateTime gridStart, int totalDays}) currentMonthGrid(
    WeekStart weekStart,
  ) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final gridStart = periodBoundaryFor(
      evaluationPeriod: EvaluationPeriod.weekly,
      date: month,
      goalStartDate: month,
      weekStart: weekStart,
    ).start;
    final gridEnd = periodBoundaryFor(
      evaluationPeriod: EvaluationPeriod.weekly,
      date: lastDay,
      goalStartDate: lastDay,
      weekStart: weekStart,
    ).end;
    return (
      month: month,
      gridStart: gridStart,
      totalDays: gridEnd.difference(gridStart).inDays + 1,
    );
  }

  group('Month View — default landing & grid rendering (Subtask 6.2)', () {
    testWidgets(
      'Month View is the default sub-view of the Calendar tab (AC #2); '
      'Story 3.1 moves the app-wide landing tab to Today/Dashboard',
      (tester) async {
        store = InMemoryStore();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              goalRepositoryProvider.overrideWithValue(
                InMemoryGoalRepository(store),
              ),
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
            ],
            child: const TrackerApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Today (Dashboard) is the app-wide landing tab (Story 3.1 AC 6).
        expect(find.byType(MonthViewScreen), findsNothing);

        await tester.tap(find.text('Calendar'));
        await tester.pumpAndSettle();

        expect(find.byType(MonthViewScreen), findsOneWidget);
      },
    );

    testWidgets(
      'renders one status-cell per grid day, a multiple of 7 (Monday week-start default)',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final grid = currentMonthGrid(WeekStart.monday);
        expect(find.byType(StatusCell).evaluate().length, grid.totalDays);
        expect(grid.totalDays % 7, 0);
      },
    );

    testWidgets('Sunday week-start moves "Sun" left of "Mon" in the header', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(weekStartOverride: [WeekStart.sunday]));
      await tester.pumpAndSettle();

      final sunX = tester.getTopLeft(find.text('Sun')).dx;
      final monX = tester.getTopLeft(find.text('Mon')).dx;
      expect(sunX, lessThan(monX));
    });

    testWidgets('Monday week-start (default) puts "Mon" left of "Sun"', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final sunX = tester.getTopLeft(find.text('Sun')).dx;
      final monX = tester.getTopLeft(find.text('Mon')).dx;
      expect(monX, lessThan(sunX));
    });
  });

  group('Month View — swipe navigation & jump to today (Subtask 6.3)', () {
    testWidgets('swiping left moves the header title to the adjacent month', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
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

      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(titleText(), isNot(initialTitle));
    });

    testWidgets(
      '"jump to today" is reachable after navigating several months away',
      (tester) async {
        await tester.pumpWidget(buildApp());
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

        for (var i = 0; i < 4; i++) {
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

  group('Month View — tap/long-press interactions (Subtask 6.4)', () {
    testWidgets('tapping a day cell opens Day View for that date', (
      tester,
    ) async {
      store = InMemoryStore()
        ..goals.add(goal)
        ..versions.add(dailyBooleanVersion());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(
              InMemoryGoalRepository(store),
            ),
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
          child: const MaterialApp(home: MonthViewScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final grid = currentMonthGrid(WeekStart.monday);
      final target = DateTime(grid.month.year, grid.month.month, 15);
      final index = target.difference(grid.gridStart).inDays;

      await tester.tap(find.byType(StatusCell).at(index));
      await tester.pumpAndSettle();

      expect(find.byType(DayViewScreen), findsOneWidget);
      // Story 3.5's GoalFilterBar also renders each goal's name as a chip
      // label, so scope to the actual GoalRow rather than a bare find.text.
      expect(find.widgetWithText(GoalRow, 'Read'), findsOneWidget);
    });

    testWidgets(
      'long-pressing a day cell with a single goal opens the Cheat/Blackout sheet',
      (tester) async {
        store = InMemoryStore()
          ..goals.add(goal)
          ..versions.add(dailyBooleanVersion());
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              goalRepositoryProvider.overrideWithValue(
                InMemoryGoalRepository(store),
              ),
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
            child: const MaterialApp(home: MonthViewScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final grid = currentMonthGrid(WeekStart.monday);
        final target = DateTime(grid.month.year, grid.month.month, 15);
        final index = target.difference(grid.gridStart).inDays;

        await tester.longPress(find.byType(StatusCell).at(index));
        await tester.pumpAndSettle();

        expect(find.text('Mark as Blackout Date'), findsWidgets);
      },
    );

    testWidgets('no swipe-to-reveal row action exists anywhere in Month View', (
      tester,
    ) async {
      store = InMemoryStore()
        ..goals.add(goal)
        ..versions.add(dailyBooleanVersion());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(
              InMemoryGoalRepository(store),
            ),
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
          child: const MaterialApp(home: MonthViewScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsNothing);
    });
  });

  group('Month View — multi-goal aggregation rule (Subtask 3.1 / 6.5)', () {
    test('aggregateDayStatus is worst-status-wins: Fail > Pending > Cheat > Success > Empty', () {
      expect(
        aggregateDayStatus([DayStatusValue.success, DayStatusValue.fail]),
        DayStatusValue.fail,
      );
      expect(
        aggregateDayStatus([DayStatusValue.success, DayStatusValue.pending]),
        DayStatusValue.pending,
      );
      expect(
        aggregateDayStatus([DayStatusValue.success, DayStatusValue.cheat]),
        DayStatusValue.cheat,
      );
      expect(
        aggregateDayStatus([DayStatusValue.empty, DayStatusValue.success]),
        DayStatusValue.success,
      );
      expect(aggregateDayStatus(const []), DayStatusValue.empty);
      expect(
        aggregateDayStatus([
          DayStatusValue.pending,
          DayStatusValue.fail,
          DayStatusValue.cheat,
        ]),
        DayStatusValue.fail,
      );
    });

    testWidgets(
      'a day with one Failed goal and one Successful goal renders the Fail glyph, not Success',
      (tester) async {
        const goalA = Goal(
          id: 'goal-a',
          name: 'Gym',
          archived: false,
          startDate: '2026-01-01',
        );
        const goalB = Goal(
          id: 'goal-b',
          name: 'Read',
          archived: false,
          startDate: '2026-01-01',
        );
        final versionA = GoalVersion(
          id: 'version-a',
          goalId: goalA.id,
          versionStartDate: '2026-01-01',
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.exactly,
          targetValue: '1',
          trackingType: TrackingType.boolean,
        );
        final versionB = versionA.copyWith(id: 'version-b', goalId: goalB.id);

        final now = DateTime.now();
        final targetDate = DateTime(now.year, now.month, 1);
        final dateStr =
            '${targetDate.year.toString().padLeft(4, '0')}-'
            '${targetDate.month.toString().padLeft(2, '0')}-'
            '${targetDate.day.toString().padLeft(2, '0')}';

        store = InMemoryStore()
          ..goals.addAll([goalA, goalB])
          ..versions.addAll([versionA, versionB])
          ..logs.addAll([
            GoalLog(
              id: 'log-a',
              goalId: goalA.id,
              date: dateStr,
              timestamp: '${dateStr}T09:00:00.000',
              value: 0,
              completed: false, // explicit failure: certain Fail
            ),
            GoalLog(
              id: 'log-b',
              goalId: goalB.id,
              date: dateStr,
              timestamp: '${dateStr}T09:00:00.000',
              value: 1,
              completed: true, // Success
            ),
          ]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              goalRepositoryProvider.overrideWithValue(
                InMemoryGoalRepository(store),
              ),
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
            child: const MaterialApp(home: MonthViewScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final grid = currentMonthGrid(WeekStart.monday);
        final index = targetDate.difference(grid.gridStart).inDays;
        final cell = tester.widget<StatusCell>(
          find.byType(StatusCell).at(index),
        );

        expect(cell.status, DayStatusValue.fail);
      },
    );
  });

  group('Month View — paused dates (Story 2.2 AC 2)', () {
    testWidgets(
      'a paused goal is excluded from a day\'s aggregation, rendering Empty '
      'where it would otherwise show Pending',
      (tester) async {
        store = InMemoryStore()
          ..goals.add(goal)
          ..versions.add(dailyBooleanVersion());
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              goalRepositoryProvider.overrideWithValue(
                InMemoryGoalRepository(store),
              ),
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
            child: const MaterialApp(home: MonthViewScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final grid = currentMonthGrid(WeekStart.monday);
        final target = DateTime(grid.month.year, grid.month.month, 15);
        final index = target.difference(grid.gridStart).inDays;

        final beforePause = tester.widget<StatusCell>(
          find.byType(StatusCell).at(index),
        );
        expect(beforePause.status, DayStatusValue.pending);

        await InMemoryGoalVersionRepository(store)
            .updateVersion(dailyBooleanVersion().copyWith(isPaused: true));
        await tester.pumpAndSettle();

        final afterPause = tester.widget<StatusCell>(
          find.byType(StatusCell).at(index),
        );
        expect(afterPause.status, DayStatusValue.empty);
      },
    );
  });

  group('Month View — archived goals (Story 2.3 AC 2)', () {
    testWidgets(
      'an archived goal is excluded from a day\'s aggregation, rendering '
      'Empty where it would otherwise show Pending',
      (tester) async {
        store = InMemoryStore()
          ..goals.add(goal)
          ..versions.add(dailyBooleanVersion());
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              goalRepositoryProvider.overrideWithValue(
                InMemoryGoalRepository(store),
              ),
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
            child: const MaterialApp(home: MonthViewScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final grid = currentMonthGrid(WeekStart.monday);
        final target = DateTime(grid.month.year, grid.month.month, 15);
        final index = target.difference(grid.gridStart).inDays;

        expect(
          tester.widget<StatusCell>(find.byType(StatusCell).at(index)).status,
          DayStatusValue.pending,
        );

        await InMemoryGoalRepository(store)
            .updateGoal(goal.copyWith(archived: true));
        await tester.pumpAndSettle();

        expect(
          tester.widget<StatusCell>(find.byType(StatusCell).at(index)).status,
          DayStatusValue.empty,
        );
      },
    );
  });

  group('Month View — pre-start dates (Bug 5)', () {
    testWidgets(
      'a goal is excluded from a day\'s aggregation once its startDate moves '
      'past that day, rendering Empty where it would otherwise show Pending',
      (tester) async {
        store = InMemoryStore()
          ..goals.add(goal)
          ..versions.add(dailyBooleanVersion());
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              goalRepositoryProvider.overrideWithValue(
                InMemoryGoalRepository(store),
              ),
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
            child: const MaterialApp(home: MonthViewScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final grid = currentMonthGrid(WeekStart.monday);
        final target = DateTime(grid.month.year, grid.month.month, 15);
        final index = target.difference(grid.gridStart).inDays;

        expect(
          tester.widget<StatusCell>(find.byType(StatusCell).at(index)).status,
          DayStatusValue.pending,
        );

        final future = DateTime(grid.month.year, grid.month.month, 20);
        await InMemoryGoalRepository(store)
            .updateGoal(goal.copyWith(startDate: formatDateOnly(future)));
        await tester.pumpAndSettle();

        expect(
          tester.widget<StatusCell>(find.byType(StatusCell).at(index)).status,
          DayStatusValue.empty,
        );

        // Boundary check: a startDate that falls back onto the target day
        // itself must include the goal in that day's aggregate again.
        await InMemoryGoalRepository(store)
            .updateGoal(goal.copyWith(startDate: formatDateOnly(target)));
        await tester.pumpAndSettle();

        expect(
          tester.widget<StatusCell>(find.byType(StatusCell).at(index)).status,
          DayStatusValue.pending,
        );
      },
    );
  });
}
