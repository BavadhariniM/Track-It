import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/date_format.dart';
import 'package:tracker/presentation/components/stat_card.dart';
import 'package:tracker/presentation/components/status_cell.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';
import 'package:tracker/presentation/screens/goal_detail_screen.dart';

import '../domain/services/fakes.dart';

/// Story 2.2 Subtask 4.2: widget coverage for the Pause/Resume action on
/// Goal Detail — label toggling via `resolveLifecycleStatus` and the
/// single-tap, no-confirmation write through `GoalService.pauseGoal`/
/// `resumeGoal` (UX-DR24).
DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

void main() {
  late InMemoryStore store;
  late Goal goal;

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
      child: MaterialApp(home: GoalDetailScreen(goal: goal)),
    );
  }

  setUp(() {
    store = InMemoryStore();
    goal = const Goal(
      id: 'goal-1',
      name: 'Run',
      archived: false,
      startDate: '2026-01-01',
    );
  });

  testWidgets(
    'shows "Pause" for an active goal; tapping it pauses effective today, '
    'copying every rule field forward unchanged',
    (tester) async {
      store.versions.add(
        GoalVersion(
          id: 'version-1',
          goalId: goal.id,
          versionStartDate: '2026-01-01',
          evaluationPeriod: EvaluationPeriod.weekly,
          eligibleDaysRule: EligibleDaysRule.workdays,
          targetComparison: TargetComparison.atLeast,
          targetValue: '3',
          trackingType: TrackingType.counter,
        ),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Resume'), findsNothing);

      await tester.tap(
        find.byKey(const Key('goal-detail-pause-resume-button')),
      );
      await tester.pumpAndSettle();

      expect(store.versions, hasLength(2));
      final paused = store.versions.firstWhere(
        (v) => v.versionStartDate == formatDateOnly(_today()),
      );
      expect(paused.isPaused, isTrue);
      expect(paused.evaluationPeriod, EvaluationPeriod.weekly);
      expect(paused.eligibleDaysRule, EligibleDaysRule.workdays);
      expect(paused.targetComparison, TargetComparison.atLeast);
      expect(paused.targetValue, '3');
      expect(paused.trackingType, TrackingType.counter);
      expect(find.text('Resume'), findsOneWidget);
    },
  );

  testWidgets(
    'shows "Resume" for a paused goal; tapping it resumes effective today '
    'with no confirmation dialog (UX-DR24)',
    (tester) async {
      store.versions.add(
        GoalVersion(
          id: 'version-1',
          goalId: goal.id,
          versionStartDate: '2026-01-01',
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.exactly,
          targetValue: '1',
          trackingType: TrackingType.boolean,
          isPaused: true,
        ),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Resume'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('goal-detail-pause-resume-button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(store.versions, hasLength(2));
      final resumed = store.versions.firstWhere(
        (v) => v.versionStartDate == formatDateOnly(_today()),
      );
      expect(resumed.isPaused, isFalse);
      expect(find.text('Pause'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Archive archives the goal, shows a non-blocking confirmation, '
    'and never a confirmation dialog (Story 2.3 Subtask 3.4, UX-DR24)',
    (tester) async {
      store.goals.add(goal);
      store.versions.add(
        GoalVersion(
          id: 'version-1',
          goalId: goal.id,
          versionStartDate: '2026-01-01',
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.exactly,
          targetValue: '1',
          trackingType: TrackingType.boolean,
        ),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('goal-detail-archive-button')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(store.goals.single.archived, isTrue);
      expect(
        find.text('Archived Goals leave active views but keep full history'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'renders the stat-card row (current/longest streak, completion %), the '
    'Version Timeline, and the historical calendar (Story 3.2 AC 1, AC 2, '
    'Subtask 6.1)',
    (tester) async {
      goal = Goal(
        id: 'goal-1',
        name: 'Run',
        archived: false,
        startDate: formatDateOnly(_today().subtract(const Duration(days: 3))),
      );
      store.goals.add(goal);
      store.versions.add(
        GoalVersion(
          id: 'version-1',
          goalId: goal.id,
          versionStartDate: goal.startDate,
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.exactly,
          targetValue: '1',
          trackingType: TrackingType.boolean,
        ),
      );
      for (final daysAgo in [3, 2, 1]) {
        final dateStr = formatDateOnly(
          _today().subtract(Duration(days: daysAgo)),
        );
        store.logs.add(
          GoalLog(
            id: 'log-$dateStr',
            goalId: goal.id,
            date: dateStr,
            timestamp: '${dateStr}T09:00:00',
            value: 1,
            completed: true,
          ),
        );
      }

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('goal-detail-current-streak-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('goal-detail-longest-streak-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('goal-detail-completion-card')),
        findsOneWidget,
      );
      // Current streak and longest streak both resolve to 3 (three
      // consecutive completed days, unbroken). Scoped to each card's own
      // key since Story 3.4 adds further cards (e.g. Successful Periods)
      // that legitimately also read "3" for this same fixture.
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
      expect(find.text('100%'), findsOneWidget);
      // Story 3.4 Subtask 4.3: a Boolean goal never renders the
      // Counter-only average/total value cards — not a zero, not N/A, the
      // cards simply don't exist for it.
      expect(
        find.byKey(const Key('goal-detail-average-value-card')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('goal-detail-total-value-card')),
        findsNothing,
      );

      expect(
        find.byKey(const Key('goal-detail-version-timeline')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('goal-detail-historical-calendar')),
        findsOneWidget,
      );
      // Goal.startDate through today, inclusive: 4 days.
      expect(find.byType(StatusCell), findsNWidgets(4));
    },
  );

  testWidgets(
    'Goal Detail renders correctly — no crash, every new section populates '
    'from history — for an Archived goal with multiple past Versions and '
    'logs (Story 3.2 AC 4, Subtask 6.3)',
    (tester) async {
      final start = _today().subtract(const Duration(days: 20));
      final laterVersionStart = _today().subtract(const Duration(days: 8));
      goal = Goal(
        id: 'goal-archived-multi',
        name: 'Old habit',
        archived: true,
        startDate: formatDateOnly(start),
      );
      store.goals.add(goal);
      store.versions.addAll([
        GoalVersion(
          id: 'version-a',
          goalId: goal.id,
          versionStartDate: formatDateOnly(start),
          evaluationPeriod: EvaluationPeriod.weekly,
          eligibleDaysRule: EligibleDaysRule.workdays,
          targetComparison: TargetComparison.atLeast,
          targetValue: '3',
          trackingType: TrackingType.counter,
        ),
        GoalVersion(
          id: 'version-b',
          goalId: goal.id,
          versionStartDate: formatDateOnly(laterVersionStart),
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.exactly,
          targetValue: '1',
          trackingType: TrackingType.boolean,
        ),
      ]);
      final logDate = formatDateOnly(_today().subtract(const Duration(days: 2)));
      store.logs.add(
        GoalLog(
          id: 'log-archived-1',
          goalId: goal.id,
          date: logDate,
          timestamp: '${logDate}T09:00:00',
          value: 1,
          completed: true,
        ),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('goal-detail-rule-summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('goal-detail-current-streak-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('goal-detail-longest-streak-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('goal-detail-completion-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('goal-detail-version-timeline')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('goal-detail-version-segment-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('goal-detail-version-segment-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('goal-detail-historical-calendar')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Story 3.4 Subtask 4.4: a goal fixture with several years of history '
    'renders all stats correctly and the screen scrolls to reveal full '
    'history without truncation (AC 4)',
    (tester) async {
      final start = _today().subtract(const Duration(days: 800));
      goal = Goal(
        id: 'goal-long-history',
        name: 'Meditate',
        archived: false,
        startDate: formatDateOnly(start),
      );
      store.goals.add(goal);
      store.versions.add(
        GoalVersion(
          id: 'version-long-history',
          goalId: goal.id,
          versionStartDate: goal.startDate,
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.exactly,
          targetValue: '1',
          trackingType: TrackingType.boolean,
        ),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Goal.startDate through today inclusive: 801 days, every one
      // rendered — the historical calendar is not paginated or windowed to
      // a "recent" subset (AC 4).
      expect(find.byType(StatusCell), findsNWidgets(801));

      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, -5000),
        3000,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Story 3.4 Subtask 4.5: every stat-card (Story 3.2\'s original three '
    "plus this story's additions) renders through the same `stat-card` "
    'component — tabular figures, no icon widgets present (AC 3)',
    (tester) async {
      goal = Goal(
        id: 'goal-all-cards',
        name: 'Push-ups',
        archived: false,
        startDate: formatDateOnly(_today().subtract(const Duration(days: 5))),
      );
      store.goals.add(goal);
      store.versions.add(
        GoalVersion(
          id: 'version-all-cards',
          goalId: goal.id,
          versionStartDate: goal.startDate,
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.atLeast,
          targetValue: '10',
          trackingType: TrackingType.counter,
        ),
      );
      for (final daysAgo in [5, 4, 3]) {
        final dateStr = formatDateOnly(
          _today().subtract(Duration(days: daysAgo)),
        );
        store.logs.add(
          GoalLog(
            id: 'log-all-cards-$dateStr',
            goalId: goal.id,
            date: dateStr,
            timestamp: '${dateStr}T09:00:00',
            value: 10,
            completed: true,
          ),
        );
      }

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final grid = find.byKey(const Key('goal-detail-stat-card-grid'));
      expect(grid, findsOneWidget);

      // Current streak, longest streak, completion %, successful periods,
      // failed periods, cheat days, average value, total value: 8 cards,
      // all through the one `StatCard` widget (UX-DR8) — never a second
      // stat-display pattern.
      final statCards = find.descendant(
        of: grid,
        matching: find.byType(StatCard),
      );
      expect(statCards, findsNWidgets(8));
      expect(
        find.descendant(of: grid, matching: find.byType(Icon)),
        findsNothing,
      );

      final tabularValueTexts = find.descendant(
        of: grid,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.style?.fontFeatures?.contains(
                    const FontFeature.tabularFigures(),
                  ) ??
                  false),
        ),
      );
      expect(tabularValueTexts, findsNWidgets(8));
    },
  );
}
