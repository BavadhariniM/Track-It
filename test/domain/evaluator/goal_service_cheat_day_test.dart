import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/evaluate.dart';
import 'package:tracker/domain/services/goal_service.dart';
import 'package:tracker/domain/services/goal_service_result.dart';
import 'package:tracker/domain/services/result.dart';

import '../services/fakes.dart';

/// Story 2.4 testing standard: a regression confirming `evaluate()`'s Cheat
/// Day exemption (already exercised against synthetic fixtures in
/// `test/domain/evaluator/evaluate_test.dart`) still behaves correctly
/// against a real, `GoalService.markCheatDay`-persisted row — closing the
/// loop on AC 3 without re-deriving the exemption math itself (that stays
/// entirely inside `evaluate()`, per AD-4).
void main() {
  test('a GoalService-persisted CheatDay keeps an otherwise-certain-Fail '
      'Weekly At Least period Pending instead', () async {
    final store = InMemoryStore();
    final goalService = GoalService(
      goalRepository: InMemoryGoalRepository(store),
      goalVersionRepository: InMemoryGoalVersionRepository(store),
      goalLogRepository: InMemoryGoalLogRepository(store),
      blackoutDateRepository: InMemoryBlackoutDateRepository(store),
      cheatDayRepository: InMemoryCheatDayRepository(store),
      transactionRunner: SnapshotTransactionRunner(store),
      cacheWriter: InMemoryCacheWriter(store),
      widgetBridgeWriter: InMemoryWidgetBridgeWriter(),
    );

    final createResult = await goalService.createGoal(
      name: 'Read',
      startDate: '2026-08-01',
      evaluationPeriod: EvaluationPeriod.weekly,
      eligibleDaysRule: EligibleDaysRule.everyDay,
      targetComparison: TargetComparison.atLeast,
      targetValue: '7', // must succeed every eligible day this week.
      trackingType: TrackingType.boolean,
      cheatDayQuota: 1,
    );
    final goal = (createResult as Success).value;

    // Mon/Tue done via the real GoalService write path; Wed missed.
    await goalService.logBoolean(
      goalId: goal.id,
      date: '2026-08-10',
      completed: true,
    );
    await goalService.logBoolean(
      goalId: goal.id,
      date: '2026-08-11',
      completed: true,
    );

    final markResult = await goalService.markCheatDay(
      goalId: goal.id,
      date: '2026-08-12',
    );
    expect(markResult, isA<GoalServiceSuccess<dynamic>>());

    final versions = store.versions;
    final logs = store.logs;

    final withoutCheatDay = evaluate(
      goal: goal,
      versions: versions,
      logs: logs,
      date: DateTime(2026, 8, 13),
    );
    final withCheatDay = evaluate(
      goal: goal,
      versions: versions,
      logs: logs,
      cheatDays: store.cheatDays,
      date: DateTime(2026, 8, 13),
    );

    expect(withoutCheatDay.status, DayStatusValue.fail);
    expect(withCheatDay.status, DayStatusValue.pending);
    expect(withCheatDay.targetValue, withoutCheatDay.targetValue);
    expect(withCheatDay.currentValue, withoutCheatDay.currentValue);
  });
}
