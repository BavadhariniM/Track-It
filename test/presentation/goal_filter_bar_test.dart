import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/presentation/components/goal_row.dart';
import 'package:tracker/presentation/components/status_cell.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';
import 'package:tracker/presentation/screens/day_view.dart';

import '../domain/services/fakes.dart';

/// Story 3.5 Subtask 5.5: applying a category filter on the Calendar
/// updates the displayed goal set without altering any individual goal's
/// displayed status — filtering scopes *which* goals are evaluated, never
/// *how* (AD-7's live-calendar-never-reads-cache rule stays intact).
void main() {
  late InMemoryStore store;

  const healthGoal = Goal(
    id: 'goal-health',
    name: 'Read',
    category: 'Health',
    archived: false,
    startDate: '2026-01-01',
  );
  const financeGoal = Goal(
    id: 'goal-finance',
    name: 'Save',
    category: 'Finance',
    archived: false,
    startDate: '2026-01-01',
  );

  GoalVersion versionFor(String goalId) => GoalVersion(
    id: 'version-$goalId',
    goalId: goalId,
    versionStartDate: '2026-01-01',
    evaluationPeriod: EvaluationPeriod.daily,
    eligibleDaysRule: EligibleDaysRule.everyDay,
    targetComparison: TargetComparison.exactly,
    targetValue: '1',
    trackingType: TrackingType.boolean,
  );

  Widget buildApp(DateTime date) {
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
      child: MaterialApp(home: DayViewScreen(date: date)),
    );
  }

  bool readRowIsSuccess(WidgetTester tester) {
    final readRow = find.widgetWithText(GoalRow, 'Read');
    final statusCell = tester.widget<StatusCell>(
      find.descendant(of: readRow, matching: find.byType(StatusCell)),
    );
    return statusCell.status == DayStatusValue.success;
  }

  testWidgets(
    'selecting a category chip hides the non-matching goal and leaves the '
    'matching goal\'s displayed status unchanged',
    (tester) async {
      final today = DateTime.now();
      final todayDateOnly = DateTime(today.year, today.month, today.day);
      final todayStr =
          '${todayDateOnly.year.toString().padLeft(4, '0')}-'
          '${todayDateOnly.month.toString().padLeft(2, '0')}-'
          '${todayDateOnly.day.toString().padLeft(2, '0')}';

      store = InMemoryStore()
        ..goals.addAll([healthGoal, financeGoal])
        ..versions.addAll([
          versionFor(healthGoal.id),
          versionFor(financeGoal.id),
        ])
        ..logs.add(
          GoalLog(
            id: 'log-1',
            goalId: healthGoal.id,
            date: todayStr,
            timestamp: DateTime.now().toIso8601String(),
            value: 1,
            completed: true,
          ),
        );

      await tester.pumpWidget(buildApp(todayDateOnly));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(GoalRow, 'Read'), findsOneWidget);
      expect(find.widgetWithText(GoalRow, 'Save'), findsOneWidget);
      expect(readRowIsSuccess(tester), isTrue);

      // Bug 6: filtering is category-only — no per-goal chip is rendered.
      expect(
        find.byKey(const Key('goal-filter-goal-goal-health')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('goal-filter-goal-goal-finance')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('goal-filter-category-Health')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(GoalRow, 'Read'), findsOneWidget);
      expect(find.widgetWithText(GoalRow, 'Save'), findsNothing);
      expect(readRowIsSuccess(tester), isTrue);

      // Switching back to All restores both rows.
      await tester.tap(find.byKey(const Key('goal-filter-all')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(GoalRow, 'Read'), findsOneWidget);
      expect(find.widgetWithText(GoalRow, 'Save'), findsOneWidget);
    },
  );
}
