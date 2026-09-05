import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/evaluate.dart';
import 'package:tracker/domain/evaluator/period_boundary.dart';
import 'package:tracker/presentation/components/status_cell.dart';
import 'package:tracker/presentation/providers/current_date_provider.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';
import 'package:tracker/presentation/providers/week_start_provider.dart';
import 'package:tracker/presentation/screens/day_view.dart';
import 'package:tracker/presentation/screens/week_view.dart';

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

  GoalVersion weeklyBooleanVersion({
    String targetComparison = TargetComparison.atLeast,
  }) => GoalVersion(
    id: 'version-weekly',
    goalId: goal.id,
    versionStartDate: '2026-01-01',
    evaluationPeriod: EvaluationPeriod.weekly,
    eligibleDaysRule: EligibleDaysRule.everyDay,
    targetComparison: targetComparison,
    targetValue: '3',
    trackingType: TrackingType.boolean,
  );

  Widget buildApp(
    DateTime referenceDate, {
    List<WeekStart> weekStartOverride = const [],
  }) {
    store = InMemoryStore()
      ..goals.add(goal)
      ..versions.add(dailyBooleanVersion());
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
      child: MaterialApp(home: WeekViewScreen(referenceDate: referenceDate)),
    );
  }

  group('Week View — 7-day grid & progress summary (Subtask 6.1)', () {
    testWidgets(
      'renders 7 status-cells for the single goal plus a week progress summary '
      '(Monday week-start default)',
      (tester) async {
        await tester.pumpWidget(buildApp(DateTime(2026, 8, 19))); // a Wednesday
        await tester.pumpAndSettle();

        // Story 3.5's GoalFilterBar also renders each goal's name as a
        // chip label, so scope to the goal's own row rather than a bare
        // find.text.
        expect(
          find.descendant(
            of: find.byKey(const Key('week-goal-row-goal-1')),
            matching: find.text('Read'),
          ),
          findsOneWidget,
        );
        expect(find.byType(StatusCell), findsNWidgets(7));
        expect(find.textContaining('Week progress:'), findsOneWidget);
      },
    );

    testWidgets('Sunday week-start moves "Sun" left of "Mon" in the header', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(DateTime(2026, 8, 19), weekStartOverride: [WeekStart.sunday]),
      );
      await tester.pumpAndSettle();

      final sunX = tester.getTopLeft(find.text('Sun')).dx;
      final monX = tester.getTopLeft(find.text('Mon')).dx;
      expect(sunX, lessThan(monX));
    });

    testWidgets('Monday week-start (default) puts "Mon" left of "Sun"', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(DateTime(2026, 8, 19)));
      await tester.pumpAndSettle();

      final sunX = tester.getTopLeft(find.text('Sun')).dx;
      final monX = tester.getTopLeft(find.text('Mon')).dx;
      expect(monX, lessThan(sunX));
    });
  });

  group('Week View — tap/long-press interactions (Subtask 6.4)', () {
    testWidgets('tapping a day cell opens Day View for that date', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(DateTime(2026, 8, 19)));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(StatusCell).first);
      await tester.pumpAndSettle();

      expect(find.byType(DayViewScreen), findsOneWidget);
    });

    testWidgets(
      'long-pressing a day cell opens the Cheat/Blackout sheet for that goal',
      (tester) async {
        await tester.pumpWidget(buildApp(DateTime(2026, 8, 19)));
        await tester.pumpAndSettle();

        await tester.longPress(find.byType(StatusCell).first);
        await tester.pumpAndSettle();

        expect(find.text('Mark as Blackout Date'), findsWidgets);
      },
    );

    testWidgets('no swipe-to-reveal row action exists anywhere in Week View', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(DateTime(2026, 8, 19)));
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsNothing);
    });
  });

  group('Week-Start consistency: rendered week grid vs. evaluator boundary (Dev Notes)', () {
    testWidgets('Monday week-start: the rendered grid\'s first/last cell match evaluate()\'s '
        'own Weekly-period boundary for a Weekly goal', (tester) async {
      store = InMemoryStore()
        ..goals.add(goal)
        ..versions.add(weeklyBooleanVersion());
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
          child: MaterialApp(
            home: WeekViewScreen(referenceDate: DateTime(2026, 8, 19)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boundary = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.weekly,
        date: DateTime(2026, 8, 19),
        goalStartDate: DateTime(2026, 1, 1),
        weekStart: WeekStart.monday,
      );
      expect(boundary.start, DateTime(2026, 8, 17)); // Monday
      expect(boundary.end, DateTime(2026, 8, 23)); // Sunday
      expect(boundary.start.weekday, DateTime.monday);

      final cells = tester
          .widgetList<StatusCell>(find.byType(StatusCell))
          .toList();
      expect(cells, hasLength(7));

      for (var i = 0; i < 7; i++) {
        final day = boundary.start.add(Duration(days: i));
        final expected = evaluateDayOnly(
          goal: goal,
          versions: [weeklyBooleanVersion()],
          logs: const [],
          date: day,
          today: todayDateOnly(),
        ).status;
        expect(
          cells[i].status,
          expected,
          reason:
              'cell $i (${day.toIso8601String()}) must match evaluateDayOnly()',
        );
      }
    });

    testWidgets('Sunday week-start: the rendered grid\'s first/last cell match evaluate()\'s '
        'own Weekly-period boundary for a Weekly goal', (tester) async {
      store = InMemoryStore()
        ..goals.add(goal)
        ..versions.add(weeklyBooleanVersion());
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
            weekStartSettingProvider.overrideWithValue(WeekStart.sunday),
          ],
          child: MaterialApp(
            home: WeekViewScreen(
              referenceDate: DateTime(2026, 8, 17),
            ), // a Monday
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boundary = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.weekly,
        date: DateTime(2026, 8, 17),
        goalStartDate: DateTime(2026, 1, 1),
        weekStart: WeekStart.sunday,
      );
      expect(boundary.start, DateTime(2026, 8, 16)); // Sunday
      expect(boundary.end, DateTime(2026, 8, 22)); // Saturday
      expect(boundary.start.weekday, DateTime.sunday);

      final cells = tester
          .widgetList<StatusCell>(find.byType(StatusCell))
          .toList();
      expect(cells, hasLength(7));

      for (var i = 0; i < 7; i++) {
        final day = boundary.start.add(Duration(days: i));
        final expected = evaluateDayOnly(
          goal: goal,
          versions: [weeklyBooleanVersion()],
          logs: const [],
          date: day,
          today: todayDateOnly(),
        ).status;
        expect(
          cells[i].status,
          expected,
          reason:
              'cell $i (${day.toIso8601String()}) must match evaluateDayOnly()',
        );
      }
    });
  });

  group('Week View — Weekly-period goal per-day rendering (day-only semantics)', () {
    testWidgets(
      'renders evaluateDayOnly() per day for an in-progress Weekly goal — '
      'a day actually logged done reads Success even while the week as a '
      'whole (evaluate()) is still Pending',
      (tester) async {
      store = InMemoryStore()
        ..goals.add(goal)
        ..versions.add(weeklyBooleanVersion())
        ..logs.addAll([
          GoalLog(
            id: 'log-1',
            goalId: goal.id,
            date: '2026-08-17',
            timestamp: '2026-08-17T09:00:00.000',
            value: 1,
            completed: true,
          ),
          GoalLog(
            id: 'log-2',
            goalId: goal.id,
            date: '2026-08-18',
            timestamp: '2026-08-18T09:00:00.000',
            value: 1,
            completed: true,
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
          child: MaterialApp(
            home: WeekViewScreen(referenceDate: DateTime(2026, 8, 19)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cells = tester
          .widgetList<StatusCell>(find.byType(StatusCell))
          .toList();
      for (var i = 0; i < 7; i++) {
        final day = DateTime(2026, 8, 17).add(Duration(days: i));
        final expected = evaluateDayOnly(
          goal: goal,
          versions: [weeklyBooleanVersion()],
          logs: store.logs,
          date: day,
          today: todayDateOnly(),
        ).status;
        expect(cells[i].status, expected);
      }

      // The two actually-logged days must read Success individually, even
      // though the week's own target (3) was never reached (only 2 of the
      // required 3 were ever logged) — evaluate()'s period-aggregate can
      // never report Success for this fixture no matter when "today" is,
      // so this positively proves Week View is showing day-only status,
      // not a period-aggregate reinterpretation.
      expect(cells[0].status, DayStatusValue.success); // 2026-08-17
      expect(cells[1].status, DayStatusValue.success); // 2026-08-18
      final periodStatus = evaluate(
        goal: goal,
        versions: [weeklyBooleanVersion()],
        logs: store.logs,
        date: DateTime(2026, 8, 17),
        today: todayDateOnly(),
      ).status;
      expect(periodStatus, isNot(DayStatusValue.success));
    });
  });

  group('Week View — paused dates (Story 2.2 AC 2)', () {
    testWidgets(
      'a paused Version omits status-cells for its dates, never rendering '
      'Empty or Pending for them',
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
            child: MaterialApp(
              home: WeekViewScreen(referenceDate: DateTime(2026, 8, 19)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(StatusCell), findsNWidgets(7));

        // The Version governs every day of this week (its own start date,
        // 2026-01-01, precedes all of them) — flipping isPaused pauses the
        // whole week at once.
        await InMemoryGoalVersionRepository(store)
            .updateVersion(dailyBooleanVersion().copyWith(isPaused: true));
        await tester.pumpAndSettle();

        expect(find.byType(StatusCell), findsNothing);
      },
    );
  });

  group('Week View — archived goals (Story 2.3 AC 2)', () {
    testWidgets('an archived goal omits its row for the whole week', (
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
          child: MaterialApp(
            home: WeekViewScreen(referenceDate: DateTime(2026, 8, 19)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StatusCell), findsNWidgets(7));

      await InMemoryGoalRepository(store)
          .updateGoal(goal.copyWith(archived: true));
      await tester.pumpAndSettle();

      expect(find.byType(StatusCell), findsNothing);
    });
  });

  group('Week View — pre-start dates (Bug 5)', () {
    testWidgets(
      'a goal whose startDate falls after the whole displayed week renders '
      'no status-cells for it',
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
            child: MaterialApp(
              home: WeekViewScreen(referenceDate: DateTime(2026, 8, 19)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(StatusCell), findsNWidgets(7));

        await InMemoryGoalRepository(store)
            .updateGoal(goal.copyWith(startDate: '2026-09-01'));
        await tester.pumpAndSettle();

        expect(find.byType(StatusCell), findsNothing);

        // Boundary check: a startDate that falls back onto the displayed
        // week's own first day (Monday 2026-08-17, since the reference date
        // 2026-08-19 is a Wednesday) must render every cell again.
        await InMemoryGoalRepository(store)
            .updateGoal(goal.copyWith(startDate: '2026-08-17'));
        await tester.pumpAndSettle();

        expect(find.byType(StatusCell), findsNWidgets(7));
      },
    );
  });
}
