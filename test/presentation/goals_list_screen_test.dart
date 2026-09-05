import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/date_format.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';
import 'package:tracker/presentation/screens/goals/goals_list_screen.dart';

import '../domain/services/fakes.dart';

/// Story 2.3 Subtask 3.3: the Goals list groups by lifecycle status so
/// Archived/Expired goals — hidden everywhere else (AC 2) — stay reachable.
void main() {
  late InMemoryStore store;

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
      child: const MaterialApp(home: GoalsListScreen()),
    );
  }

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

  testWidgets(
    'an Archived goal renders under the Archived group, an Active goal '
    'under Active',
    (tester) async {
      const activeGoal = Goal(
        id: 'goal-active',
        name: 'Read',
        archived: false,
        startDate: '2026-01-01',
      );
      const archivedGoal = Goal(
        id: 'goal-archived',
        name: 'Old habit',
        archived: true,
        startDate: '2026-01-01',
      );
      store = InMemoryStore()
        ..goals.addAll([activeGoal, archivedGoal])
        ..versions.addAll([
          versionFor('goal-active'),
          versionFor('goal-archived'),
        ]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('goals-list-group-active')), findsOneWidget);
      expect(
        find.byKey(const Key('goals-list-group-archived')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('goals-list-group-paused')), findsNothing);
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Old habit'), findsOneWidget);
    },
  );

  testWidgets(
    'a goal whose startDate is in the future is omitted from the list, '
    'without leaving a dangling "Active" header, while a goal starting '
    'today still renders under it (Bug 5)',
    (tester) async {
      final future = DateTime.now().add(const Duration(days: 5));
      final futureGoal = Goal(
        id: 'goal-future',
        name: 'Not yet',
        archived: false,
        startDate: formatDateOnly(future),
      );
      final todayGoal = Goal(
        id: 'goal-today',
        name: 'Starts today',
        archived: false,
        startDate: formatDateOnly(DateTime.now()),
      );
      store = InMemoryStore()
        ..goals.addAll([futureGoal, todayGoal])
        ..versions.addAll([
          versionFor('goal-future'),
          versionFor('goal-today'),
        ]);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Not yet'), findsNothing);
      expect(find.text('Starts today'), findsOneWidget);
      expect(find.byKey(const Key('goals-list-group-active')), findsOneWidget);
    },
  );

  testWidgets(
    'a group whose only goal has not started yet renders no header at all '
    '(Bug 5)',
    (tester) async {
      final future = DateTime.now().add(const Duration(days: 5));
      final futureGoal = Goal(
        id: 'goal-future',
        name: 'Not yet',
        archived: false,
        startDate: formatDateOnly(future),
      );
      store = InMemoryStore()
        ..goals.add(futureGoal)
        ..versions.add(versionFor('goal-future'));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('goals-list-group-active')), findsNothing);
    },
  );
}
