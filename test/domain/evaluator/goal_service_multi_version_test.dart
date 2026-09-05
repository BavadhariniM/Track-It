import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/goal_version_draft.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/evaluate.dart';
import 'package:tracker/domain/services/goal_service.dart';
import 'package:tracker/domain/services/goal_service_result.dart';
import 'package:tracker/domain/services/result.dart';

import '../services/fakes.dart';

/// Story 2.1 Subtask 5.4: an evaluator regression proving AD-5's
/// version-boundary splitting holds against *real, GoalService-authored*
/// multi-version data — Epic 1 only ever exercised `evaluate()`'s
/// `versions` parameter against synthetic, hand-built fixtures, since
/// nothing before this story could actually persist a second `GoalVersion`
/// for the same goal (AD-6's write-time collision algorithm didn't exist
/// yet). This file is the first to call `evaluate()` against Versions that
/// `GoalService.editGoalVersion` itself wrote.
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

  test('AC 2: a day logged under Version A, then a real GoalService-created '
      'Version B effective later, re-evaluating the earlier day still '
      'returns Version A\'s outcome', () async {
    final createResult = await goalService.createGoal(
      name: 'Pushups',
      startDate: '2026-08-01',
      evaluationPeriod: EvaluationPeriod.daily,
      eligibleDaysRule: EligibleDaysRule.everyDay,
      targetComparison: TargetComparison.atLeast,
      targetValue: '10',
      trackingType: TrackingType.counter,
    );
    final goal = (createResult as Success).value;

    // Log 12 under the original Version A (target: at least 10/day) —
    // a clear Success under A's rule.
    await goalService.logCounter(
      goalId: goal.id,
      date: '2026-08-10',
      delta: 12,
    );

    // Real GoalService write of a second Version B, effective 2026-08-20,
    // tightening the target to at least 20/day — exercising the exact
    // AD-6 collision-algorithm INSERT path this story adds.
    final editResult = await goalService.editGoalVersion(
      goalId: goal.id,
      effectiveDate: '2026-08-20',
      newRules: const GoalVersionDraft(
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.atLeast,
        targetValue: '20',
        trackingType: TrackingType.counter,
      ),
    );
    expect(editResult, isA<GoalServiceSuccess<dynamic>>());
    expect(store.versions, hasLength(2));

    // Re-evaluating 2026-08-10 (before Version B's start) must still
    // apply Version A's target (10), not Version B's (20) — AC 2 / AD-5.
    final earlierDayStatus = evaluate(
      goal: goal,
      versions: store.versions,
      logs: store.logs,
      date: DateTime(2026, 8, 10),
    );
    expect(earlierDayStatus.status, DayStatusValue.success);
    expect(earlierDayStatus.currentValue, 12);
    expect(earlierDayStatus.targetValue, 10);

    // A day governed by Version B with the same 12 logged now reads
    // Pending, not Success — the same total that satisfied Version A's
    // looser target (10) does not satisfy Version B's stricter one (20)
    // — confirming Version B's rule (not Version A's) actually governs
    // dates on/after its start, not merely its own presence in the list.
    await goalService.logCounter(
      goalId: goal.id,
      date: '2026-08-20',
      delta: 12,
    );
    final laterDayStatus = evaluate(
      goal: goal,
      versions: store.versions,
      logs: store.logs,
      date: DateTime(2026, 8, 20),
    );
    expect(laterDayStatus.currentValue, 12);
    expect(laterDayStatus.targetValue, 20);
    expect(laterDayStatus.status, DayStatusValue.pending);
  });

  test('FR-9 regression: editing effective on a date '
      'that is NOT itself aligned to the Goal-anchored EveryNDays cycle '
      'still keeps every eligible date anchored to Goal.startDate, not the '
      'new Version.versionStartDate', () async {
    // EveryNDays(3) anchored at 2026-08-01: eligible on 01, 04, 07, 10,
    // 13, 16, 19, 22...
    final createResult = await goalService.createGoal(
      name: 'Deep clean',
      startDate: '2026-08-01',
      evaluationPeriod: EvaluationPeriod.daily,
      eligibleDaysRule: 'every_n_days:3',
      targetComparison: TargetComparison.exactly,
      targetValue: '1',
      trackingType: TrackingType.boolean,
    );
    final goal = (createResult as Success).value;

    // 2026-08-15 is NOT itself a Goal-anchored eligible date (diff=14,
    // 14 % 3 != 0). Editing effective here means: if the bug re-anchored
    // to the Version's own start, 2026-08-18 (3 days later) would wrongly
    // become "eligible" (Version-anchor diff=3); under the correct
    // Goal-anchored rule, 2026-08-18's Goal-anchor diff is 17
    // (17 % 3 != 0) — NOT eligible.
    final editResult = await goalService.editGoalVersion(
      goalId: goal.id,
      effectiveDate: '2026-08-15',
      newRules: const GoalVersionDraft(
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: 'every_n_days:3',
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      ),
    );
    expect(editResult, isA<GoalServiceSuccess<dynamic>>());

    final wronglyEligibleIfVersionAnchored = evaluate(
      goal: goal,
      versions: store.versions,
      logs: store.logs,
      date: DateTime(2026, 8, 18),
    );
    // Not eligible -> Empty, confirming the anchor is still Goal.startDate.
    expect(wronglyEligibleIfVersionAnchored.status, DayStatusValue.empty);

    // 2026-08-19 IS Goal-anchor eligible (diff=18, 18 % 3 == 0),
    // confirming the rule still fires correctly on genuinely-anchored
    // dates after the edit.
    final genuinelyEligible = evaluate(
      goal: goal,
      versions: store.versions,
      logs: store.logs,
      date: DateTime(2026, 8, 19),
    );
    expect(genuinelyEligible.status, DayStatusValue.pending);
  });
}
