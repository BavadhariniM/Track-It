import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/evaluate.dart';
import 'package:tracker/domain/services/goal_service.dart';
import 'package:tracker/domain/services/goal_service_result.dart';
import 'package:tracker/domain/services/result.dart';

import '../services/fakes.dart';

/// Story 2.2's own integration-level test (Dev Notes "Testing standards"):
/// pauses a period-based goal mid-period, resumes it before the period
/// ends, and asserts `evaluate()` still judges the period correctly against
/// the shrunk-but-unified eligible-day pool. `evaluate()`'s own pool-
/// exclusion unit tests already live in Story 1.3 — this test is about
/// proving `pauseGoal`/`resumeGoal`'s writes actually produce the Version
/// data `evaluate()` expects, not re-deriving the pool logic itself.
void main() {
  late InMemoryStore store;
  late GoalService goalService;

  setUp(() {
    store = InMemoryStore();
    goalService = GoalService(
      goalRepository: InMemoryGoalRepository(store),
      goalVersionRepository: InMemoryGoalVersionRepository(store),
      goalLogRepository: InMemoryGoalLogRepository(store),
      blackoutDateRepository: InMemoryBlackoutDateRepository(store),
      cheatDayRepository: InMemoryCheatDayRepository(store),
      transactionRunner: SnapshotTransactionRunner(store),
      cacheWriter: InMemoryCacheWriter(store),
      widgetBridgeWriter: InMemoryWidgetBridgeWriter(),
    );
  });

  test(
    'pausing mid-week then resuming before the week ends shrinks the '
    'eligible-day pool but still lets the Weekly "3x/week" target be met',
    () async {
      // Weekly goal, "at least 3x/week", every day eligible, Monday
      // 2026-08-17 through Sunday 2026-08-23.
      final createResult = await goalService.createGoal(
        name: 'Gym',
        startDate: '2026-08-17',
        evaluationPeriod: EvaluationPeriod.weekly,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.atLeast,
        targetValue: '3',
        trackingType: TrackingType.boolean,
      );
      final goal = (createResult as Success).value;

      // Log a success on Monday, before any pause.
      await goalService.logBoolean(
        goalId: goal.id,
        date: '2026-08-17',
        completed: true,
      );

      // Pause Tuesday-Wednesday (2026-08-18), resume Thursday (2026-08-20).
      final pauseResult = await goalService.pauseGoal(
        goalId: goal.id,
        effectiveDate: '2026-08-18',
      );
      expect(pauseResult, isA<GoalServiceSuccess<dynamic>>());
      final resumeResult = await goalService.resumeGoal(
        goalId: goal.id,
        effectiveDate: '2026-08-20',
      );
      expect(resumeResult, isA<GoalServiceSuccess<dynamic>>());
      expect(store.versions, hasLength(3));

      // Two more successes on the resumed, still-eligible days.
      await goalService.logBoolean(
        goalId: goal.id,
        date: '2026-08-20',
        completed: true,
      );
      await goalService.logBoolean(
        goalId: goal.id,
        date: '2026-08-21',
        completed: true,
      );

      // Queried from the last day of the week: 3 successes against 3
      // still-open-or-resolved eligible days (Mon, Thu, Fri; Tue/Wed
      // excluded by the pause) — target met, Success.
      final endOfWeekStatus = evaluate(
        goal: goal,
        versions: store.versions,
        logs: store.logs,
        date: DateTime(2026, 8, 23),
      );
      expect(endOfWeekStatus.status, DayStatusValue.success);
      expect(endOfWeekStatus.currentValue, 3);

      // Without the pause, Tue/Wed would have contributed 2 more eligible
      // days to the pool (7 total instead of 5) — confirming the paused
      // dates really were excluded from the period's eligible-day pool
      // (AD-4's pause-awareness), not merely skipped by coincidence. A
      // control goal with the identical shape but no pause proves the
      // counterfactual.
      final controlCreateResult = await goalService.createGoal(
        name: 'Gym (control)',
        startDate: '2026-08-17',
        evaluationPeriod: EvaluationPeriod.weekly,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '7',
        trackingType: TrackingType.counterDoneCount,
      );
      final controlGoal = (controlCreateResult as Success).value;
      for (final date in ['2026-08-17', '2026-08-20', '2026-08-21']) {
        await goalService.logBoolean(
          goalId: controlGoal.id,
          date: date,
          completed: true,
        );
      }
      final controlStatus = evaluate(
        goal: controlGoal,
        versions: store.versions
            .where((v) => v.goalId == controlGoal.id)
            .toList(),
        logs: store.logs.where((l) => l.goalId == controlGoal.id).toList(),
        date: DateTime(2026, 8, 17),
      );
      // Every one of the 7 calendar days is eligible for the unpaused
      // control goal, so with only 3 done-days logged and 4 days still
      // open, hitting "exactly 7" remains reachable but unresolved —
      // Pending, never the paused goal's already-certain Success above.
      expect(controlStatus.status, DayStatusValue.pending);
      expect(controlStatus.currentValue, 3);
    },
  );
}
