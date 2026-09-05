import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/evaluate.dart';
import 'package:tracker/domain/services/reminder_suppression_service.dart';

/// Story 4.2 Task 3.1's full correctness matrix: 3 Target Comparisons
/// (At Least, At Most, Exactly) x {not yet met, exactly met, exceeded} x
/// {eligible today, not eligible today} x {Active, Paused, Archived} — all
/// via `filterRemindableGoals`'s single entry point, never a second
/// evaluation code path.
void main() {
  final today = DateTime(2026, 8, 30);
  final todayStr = '2026-08-30';

  // A rule that excludes today's actual weekday (whatever it is), so the
  // "not eligible today" cases are deterministic regardless of which
  // calendar date `today` happens to be.
  final notTodayRule = EligibleDaysRule.fromWeekdays(
    {1, 2, 3, 4, 5, 6, 7}..remove(today.weekday),
  );

  Goal goal(String id, {bool archived = false}) => Goal(
    id: id,
    name: 'Goal $id',
    archived: archived,
    startDate: '2020-01-01',
  );

  GoalVersion version({
    required String goalId,
    required String targetComparison,
    String targetValue = '8',
    String trackingType = TrackingType.counter,
    String eligibleDaysRule = EligibleDaysRule.everyDay,
    bool isPaused = false,
  }) => GoalVersion(
    id: 'version-$goalId',
    goalId: goalId,
    versionStartDate: '2020-01-01',
    evaluationPeriod: EvaluationPeriod.daily,
    eligibleDaysRule: eligibleDaysRule,
    targetComparison: targetComparison,
    targetValue: targetValue,
    trackingType: trackingType,
    isPaused: isPaused,
  );

  GoalLog counterLog(String goalId, double value) => GoalLog(
    id: 'log-$goalId',
    goalId: goalId,
    date: todayStr,
    timestamp: '${todayStr}T09:00:00',
    value: value,
    completed: value > 0,
  );

  List<Goal> filterOne({
    required Goal g,
    required GoalVersion v,
    List<GoalLog> logs = const [],
  }) {
    return filterRemindableGoals(
      goals: [
        GoalReminderInput(goal: g, versions: [v], logs: logs),
      ],
      date: today,
    );
  }

  group('At Least (≥)', () {
    test('target met → goal still included (AC #4)', () {
      final g = goal('water');
      final v = version(goalId: g.id, targetComparison: TargetComparison.atLeast, targetValue: '8');
      final result = filterOne(g: g, v: v, logs: [counterLog(g.id, 8)]);
      expect(result, [g]);
    });

    test('target exceeded → goal still included (AC #4)', () {
      final g = goal('water');
      final v = version(goalId: g.id, targetComparison: TargetComparison.atLeast, targetValue: '8');
      final result = filterOne(g: g, v: v, logs: [counterLog(g.id, 10)]);
      expect(result, [g]);
    });

    test('target not yet met → goal included', () {
      final g = goal('water');
      final v = version(goalId: g.id, targetComparison: TargetComparison.atLeast, targetValue: '8');
      final result = filterOne(g: g, v: v, logs: [counterLog(g.id, 3)]);
      expect(result, [g]);
    });
  });

  group('At Most (≤)', () {
    test('target met → goal suppressed', () {
      final g = goal('coffee');
      final v = version(goalId: g.id, targetComparison: TargetComparison.atMost, targetValue: '2');
      final result = filterOne(g: g, v: v, logs: [counterLog(g.id, 2)]);
      expect(result, isEmpty);
    });

    test('target exceeded → goal suppressed (ceiling already broken)', () {
      final g = goal('coffee');
      final v = version(goalId: g.id, targetComparison: TargetComparison.atMost, targetValue: '2');
      final result = filterOne(g: g, v: v, logs: [counterLog(g.id, 3)]);
      expect(result, isEmpty);
    });

    test('target not yet met → goal included', () {
      final g = goal('coffee');
      final v = version(goalId: g.id, targetComparison: TargetComparison.atMost, targetValue: '2');
      final result = filterOne(g: g, v: v, logs: [counterLog(g.id, 1)]);
      expect(result, [g]);
    });
  });

  group('Exactly (=)', () {
    test('target met → goal suppressed', () {
      final g = goal('meditate');
      final v = version(
        goalId: g.id,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );
      final log = GoalLog(
        id: 'log-${g.id}',
        goalId: g.id,
        date: todayStr,
        timestamp: '${todayStr}T09:00:00',
        value: 1,
        completed: true,
      );
      final result = filterOne(g: g, v: v, logs: [log]);
      expect(result, isEmpty);
    });

    test('target not yet met → goal included', () {
      final g = goal('meditate');
      final v = version(
        goalId: g.id,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );
      final result = filterOne(g: g, v: v, logs: const []);
      expect(result, [g]);
    });

    test('target exceeded (counter) → goal suppressed', () {
      final g = goal('pushups');
      final v = version(goalId: g.id, targetComparison: TargetComparison.exactly, targetValue: '5');
      final result = filterOne(g: g, v: v, logs: [counterLog(g.id, 6)]);
      expect(result, isEmpty);
    });
  });

  group('eligibility and lifecycle exclusions', () {
    test(
      'not eligible today → excluded regardless of target state (any comparison)',
      () {
        for (final comparison in [
          TargetComparison.atLeast,
          TargetComparison.atMost,
          TargetComparison.exactly,
        ]) {
          final g = goal('goal-$comparison');
          final v = version(
            goalId: g.id,
            targetComparison: comparison,
            eligibleDaysRule: notTodayRule,
          );
          final result = filterOne(g: g, v: v, logs: [counterLog(g.id, 100)]);
          expect(result, isEmpty, reason: 'comparison=$comparison');
        }
      },
    );

    test('Paused → excluded (any comparison)', () {
      for (final comparison in [
        TargetComparison.atLeast,
        TargetComparison.atMost,
        TargetComparison.exactly,
      ]) {
        final g = goal('goal-$comparison');
        final v = version(
          goalId: g.id,
          targetComparison: comparison,
          isPaused: true,
        );
        final result = filterOne(g: g, v: v);
        expect(result, isEmpty, reason: 'comparison=$comparison');
      }
    });

    test('Archived → excluded (any comparison)', () {
      for (final comparison in [
        TargetComparison.atLeast,
        TargetComparison.atMost,
        TargetComparison.exactly,
      ]) {
        final g = goal('goal-$comparison', archived: true);
        final v = version(goalId: g.id, targetComparison: comparison);
        final result = filterOne(g: g, v: v);
        expect(result, isEmpty, reason: 'comparison=$comparison');
      }
    });

    test(
      'a Paused non-Daily goal whose entire period is paused is excluded '
      'even though evaluate() itself reports it as fail, not empty '
      '(Task 3.3 — proves the Paused/Archived check reads Version state '
      'directly rather than re-deriving it from evaluate()s status, since '
      'a fully-paused period is one case where those two would disagree)',
      () {
        final g = goal('weekly-paused');
        final weeklyPausedVersion = GoalVersion(
          id: 'version-${g.id}',
          goalId: g.id,
          versionStartDate: '2020-01-01',
          evaluationPeriod: EvaluationPeriod.weekly,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.atLeast,
          targetValue: '3',
          trackingType: TrackingType.counter,
          isPaused: true,
        );

        // Sanity-check the premise: evaluate() reports `fail` (a
        // misconfiguration-shaped "zero eligible days" signal), not
        // `empty`, for this fully-paused week — so a suppression
        // implementation relying solely on `status == empty` would
        // wrongly include this goal.
        final status = evaluate(
          goal: g,
          versions: [weeklyPausedVersion],
          logs: const [],
          date: today,
        );
        expect(status.status, isNot(DayStatusValue.empty));

        final result = filterOne(g: g, v: weeklyPausedVersion);
        expect(result, isEmpty);
      },
    );
  });

  test('all goals suppressed → empty remindable set', () {
    final archived = goal('archived', archived: true);
    final archivedVersion = version(
      goalId: archived.id,
      targetComparison: TargetComparison.atLeast,
    );
    final coffee = goal('coffee');
    final coffeeVersion = version(
      goalId: coffee.id,
      targetComparison: TargetComparison.atMost,
      targetValue: '2',
    );

    final result = filterRemindableGoals(
      goals: [
        GoalReminderInput(goal: archived, versions: [archivedVersion], logs: const []),
        GoalReminderInput(
          goal: coffee,
          versions: [coffeeVersion],
          logs: [counterLog(coffee.id, 2)],
        ),
      ],
      date: today,
    );

    expect(result, isEmpty);
  });
}
