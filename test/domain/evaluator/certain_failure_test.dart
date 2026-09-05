// Story 1.8: certain-failure math (FR-18) and the zero-eligible-days
// exception (FR-5). Complements `thirteen_patterns_test.dart`'s worked
// examples with dedicated boundary-math coverage — the exact day/count at
// which Pending flips to Red for each Target Comparison, since off-by-one
// errors here are the most consequential bug class in the evaluator
// (Dev Notes' Testing Standards).
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/evaluate.dart';

void main() {
  final goal = Goal(
    id: 'goal-1',
    name: 'Test Goal',
    archived: false,
    startDate: '2026-01-01',
  );

  GoalVersion version({
    required String evaluationPeriod,
    required String eligibleDaysRule,
    required String trackingType,
    required String targetComparison,
    required String targetValue,
    String versionStartDate = '2026-01-01',
  }) {
    return GoalVersion(
      id: 'version-1',
      goalId: goal.id,
      versionStartDate: versionStartDate,
      evaluationPeriod: evaluationPeriod,
      eligibleDaysRule: eligibleDaysRule,
      targetComparison: targetComparison,
      targetValue: targetValue,
      trackingType: trackingType,
    );
  }

  GoalLog counterLog(String date, double value) => GoalLog(
    id: 'log-$date-counter',
    goalId: goal.id,
    date: date,
    timestamp: '${date}T09:00:00.000',
    value: value,
    completed: value > 0,
  );

  group('AC #1/#2: Weekly "at least 3 of 5 workdays"', () {
    final v = version(
      evaluationPeriod: EvaluationPeriod.weekly,
      eligibleDaysRule: EligibleDaysRule.workdays,
      trackingType: TrackingType.boolean,
      targetComparison: TargetComparison.atLeast,
      targetValue: '3',
    );

    test('AC #1: 2 of 5 workdays missed so far, 3 still remaining — Pending, '
        'not Red', () {
      // Mon 8/10 - Fri 8/14 are the workdays. Evaluated on Wed 8/12: Mon
      // and Tue are unlogged and already past (2 genuine misses), while
      // Wed/Thu/Fri are today-or-future and still open (3 remaining) —
      // even a perfect run on all 3 remaining days reaches exactly 3, so
      // failure is not yet certain (FR-18).
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: const [],
        date: DateTime(2026, 8, 12),
      );
      expect(status.status, DayStatusValue.pending);
    });

    test(
      'AC #2: 3 of 5 workdays already missed — Red, failure is now certain',
      () {
        // Evaluated on Thu 8/13: Mon/Tue/Wed are unlogged and already past
        // (3 genuine misses), leaving only Thu/Fri (2 remaining) — even a
        // perfect run on both remaining days can only reach 2, never the
        // target of 3, so failure is mathematically certain.
        final status = evaluate(
          goal: goal,
          versions: [v],
          logs: const [],
          date: DateTime(2026, 8, 13),
        );
        expect(status.status, DayStatusValue.fail);
      },
    );
  });

  group('AC #3: Rolling-Window "10x in any 14 days" — Counter (summed) / '
      'At least 10', () {
    final v = version(
      evaluationPeriod: EvaluationPeriod.rollingWindow(14),
      eligibleDaysRule: EligibleDaysRule.workdays,
      trackingType: TrackingType.counter,
      targetComparison: TargetComparison.atLeast,
      targetValue: '10',
    );
    final logs = [counterLog('2026-08-03', 3)]; // well under 10

    test('no other condition triggers Red prematurely — far under target but '
        'the window is still open stays Pending', () {
      // Fri 8/14 is itself a workday (eligible, unlogged) — a summed
      // Counter's remaining day is uncapped (no per-day maximum), so
      // even though 3 is nowhere near 10, the window isn't mathematically
      // closed yet and must not turn Red just because the target isn't
      // hit (FR-18's core anti-pattern).
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: logs,
        date: DateTime(2026, 8, 14),
      );
      expect(status.status, DayStatusValue.pending);
    });

    test('the very next day, once the window can no longer reach 10, turns '
        'Red — with no other red-triggering condition', () {
      // Sat 8/15 is not a workday, so it is excluded from the eligible
      // pool entirely — and since every workday in the trailing-14-day
      // window is now strictly before the evaluation date, none of them
      // count as "remaining" either. The window is genuinely closed
      // with total still at 3: failure is certain.
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: logs,
        date: DateTime(2026, 8, 15),
      );
      expect(status.status, DayStatusValue.fail);
    });
  });

  group('AC #4: zero-eligible-days exception (FR-5)', () {
    test('an Eligible-Days Rule that resolves to no weekdays at all fails the '
        'entire period — a deliberate misconfiguration signal, not Empty', () {
      // A genuine, reachable misconfiguration: a wizard that lets every
      // weekday be deselected produces this exact empty rule. With zero
      // eligible days across the whole Weekly period boundary, the
      // certain-failure math would otherwise degenerate ambiguously (zero
      // remaining days, vacuously "nothing missed yet") — Task 2's
      // short-circuit forces Fail/Red instead.
      final noWeekdaysAtAll = version(
        evaluationPeriod: EvaluationPeriod.weekly,
        eligibleDaysRule: EligibleDaysRule.fromWeekdays({}),
        trackingType: TrackingType.boolean,
        targetComparison: TargetComparison.atLeast,
        targetValue: '1',
      );

      final status = evaluate(
        goal: goal,
        versions: [noWeekdaysAtAll],
        logs: const [],
        date: DateTime(2026, 8, 15),
      );
      expect(status.status, DayStatusValue.fail);
    });

    test(
      'a normal single non-eligible day within an otherwise-populated period '
      'still renders Empty, not the zero-eligible-days Fail (Story 1.4/1.8 '
      'boundary)',
      () {
        // Contrast with the test above: here the Eligible-Days Rule
        // (workdays) produces PLENTY of eligible days elsewhere in the
        // goal's life — only this one Daily-period query date (a Saturday)
        // happens to be non-eligible. That is Story 1.4's ordinary per-day
        // Empty case and must never be conflated with Task 2's
        // whole-period-is-zero exception.
        final workdaysOnly = version(
          evaluationPeriod: EvaluationPeriod.daily,
          eligibleDaysRule: EligibleDaysRule.workdays,
          trackingType: TrackingType.boolean,
          targetComparison: TargetComparison.exactly,
          targetValue: '1',
        );

        // 2026-08-15 is a Saturday.
        final status = evaluate(
          goal: goal,
          versions: [workdaysOnly],
          logs: const [],
          date: DateTime(2026, 8, 15),
        );
        expect(status.status, DayStatusValue.empty);
      },
    );
  });

  group('Certain-failure boundary math: At Most (period aggregation)', () {
    final v = version(
      evaluationPeriod: EvaluationPeriod.weekly,
      eligibleDaysRule: EligibleDaysRule.workdays,
      trackingType: TrackingType.counter,
      targetComparison: TargetComparison.atMost,
      targetValue: '10',
    );

    test('under the limit, mid-week, stays Pending — not yet certain', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [counterLog('2026-08-10', 5)], // Mon
        date: DateTime(2026, 8, 12), // Wed — Thu/Fri still open
      );
      expect(status.status, DayStatusValue.pending);
    });

    test('exceeding the limit is immediate, certain failure — no remaining-day '
        'math needed, even mid-week', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [counterLog('2026-08-10', 15)], // already over 10
        date: DateTime(2026, 8, 12), // still Wednesday, days remain
      );
      expect(status.status, DayStatusValue.fail);
    });

    test('Success is withheld until the work week is truly over, even though '
        'never exceeded', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [counterLog('2026-08-10', 8)],
        date: DateTime(2026, 8, 15), // Saturday — all workdays passed
      );
      expect(status.status, DayStatusValue.success);
    });
  });

  group('Certain-failure boundary math: Exactly (period aggregation)', () {
    final v = version(
      evaluationPeriod: EvaluationPeriod.weekly,
      eligibleDaysRule: EligibleDaysRule.workdays,
      trackingType: TrackingType.counter,
      targetComparison: TargetComparison.exactly,
      targetValue: '10',
    );

    test('on-target mid-week stays Pending — a later remaining day could still '
        'overshoot it', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [
          counterLog('2026-08-10', 4), // Mon
          counterLog('2026-08-11', 3), // Tue
          counterLog('2026-08-12', 3), // Wed, sum = 10
        ],
        date: DateTime(2026, 8, 13), // Thu/Fri still open
      );
      expect(status.status, DayStatusValue.pending);
    });

    test('overshoot mid-week is immediate, certain failure', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [
          counterLog('2026-08-10', 8),
          counterLog('2026-08-11', 7), // sum = 15, already over 10
        ],
        date: DateTime(2026, 8, 12), // Wednesday, days remain
      );
      expect(status.status, DayStatusValue.fail);
    });

    test('exactly on target once the work week is truly over is Success', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [
          counterLog('2026-08-10', 4),
          counterLog('2026-08-11', 3),
          counterLog('2026-08-12', 3), // sum = 10 across the work week
        ],
        date: DateTime(2026, 8, 15), // Saturday — all workdays passed
      );
      expect(status.status, DayStatusValue.success);
    });
  });
}
