import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/evaluate.dart';
import 'package:tracker/domain/services/goal_service.dart';

import 'fakes.dart';

/// Story 3.1 Subtask 5.2. Exercised through [InMemoryCacheWriter] — the
/// same fake-over-real-Drift convention every other repository test in this
/// suite already uses (no test file in this suite constructs a real
/// `AppDatabase`); `InMemoryCacheWriter` mirrors `DriftCacheWriter`'s
/// algorithm exactly, over the shared `InMemoryStore` instead of Drift.
void main() {
  late InMemoryStore store;

  const goal = Goal(
    id: 'goal-1',
    name: 'Read',
    archived: false,
    startDate: '2026-08-01',
  );
  final version = GoalVersion(
    id: 'version-1',
    goalId: goal.id,
    versionStartDate: '2026-08-01',
    evaluationPeriod: EvaluationPeriod.daily,
    eligibleDaysRule: EligibleDaysRule.everyDay,
    targetComparison: TargetComparison.exactly,
    targetValue: '1',
    trackingType: TrackingType.boolean,
  );

  setUp(() {
    store = InMemoryStore();
  });

  test(
    'a GoalLog commit through GoalService writes a matching status_cache '
    'row inside the same transaction (AC 4)',
    () async {
      store.goals.add(goal);
      store.versions.add(version);

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

      await goalService.logBoolean(
        goalId: goal.id,
        date: '2026-08-05',
        completed: true,
      );

      final cached = store.statusCache['${goal.id}|2026-08-05'];
      expect(cached, isNotNull);
      expect(cached!.status, DayStatusValue.success);
    },
  );

  test(
    'rebuildAll() reproduces identical DayStatus values to a fresh '
    'evaluate() call for the same inputs (cache is provably re-derivable, '
    'AD-7)',
    () async {
      final log = GoalLog(
        id: 'log-1',
        goalId: goal.id,
        date: '2026-08-03',
        timestamp: '2026-08-03T09:00:00',
        value: 1,
        completed: true,
      );
      store.goals.add(goal);
      store.versions.add(version);
      store.logs.add(log);

      await InMemoryCacheWriter(store).rebuildAll();

      final expected = evaluate(
        goal: goal,
        versions: [version],
        logs: [log],
        date: DateTime(2026, 8, 3),
      );
      expect(store.statusCache['${goal.id}|2026-08-03'], expected);

      // An eligible day with no log is re-derived as Pending, not skipped.
      final expectedGap = evaluate(
        goal: goal,
        versions: [version],
        logs: [log],
        date: DateTime(2026, 8, 2),
      );
      expect(store.statusCache['${goal.id}|2026-08-02'], expectedGap);
    },
  );
}
