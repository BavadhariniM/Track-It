// The 13 worked-example patterns from PRD §4.2 (FR-12), each produced
// purely by composing the four independent axes — period (Story 1.3),
// eligible-days (Stories 1.4/1.5), tracking type (Stories 1.1/1.2/1.7), and
// target comparison (this story) — through the one shared `evaluate()`.
// This is NFR-6's single highest-value test coverage in Epic 1.
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/blackout_date.dart';
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

  GoalLog boolLog(String date, {bool completed = true}) => GoalLog(
    id: 'log-$date-bool',
    goalId: goal.id,
    date: date,
    timestamp: '${date}T09:00:00.000',
    value: completed ? 1 : 0,
    completed: completed,
  );

  GoalLog counterLog(String date, double value) => GoalLog(
    id: 'log-$date-counter',
    goalId: goal.id,
    date: date,
    timestamp: '${date}T09:00:00.000',
    value: value,
    completed: value > 0,
  );

  group(
    'Pattern 1: Meditate daily — Daily / every day / Boolean / Exactly 1',
    () {
      final v = version(
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        trackingType: TrackingType.boolean,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
      );

      test('logged done is Success', () {
        final status = evaluate(
          goal: goal,
          versions: [v],
          logs: [boolLog('2026-08-15')],
          date: DateTime(2026, 8, 15),
        );
        expect(status.status, DayStatusValue.success);
      });

      test('not logged is Pending', () {
        final status = evaluate(
          goal: goal,
          versions: [v],
          logs: const [],
          date: DateTime(2026, 8, 15),
        );
        expect(status.status, DayStatusValue.pending);
      });
    },
  );

  group('Pattern 2: Gym 3x/week, workdays only — Weekly / Workdays / '
      'Counter(done-count) / At least 3', () {
    final v = version(
      evaluationPeriod: EvaluationPeriod.weekly,
      eligibleDaysRule: EligibleDaysRule.workdays,
      trackingType: TrackingType.counterDoneCount,
      targetComparison: TargetComparison.atLeast,
      targetValue: '3',
    );

    test('3 done-days within the work week meets the target', () {
      // Mon 8/10 - Fri 8/14 are the workdays in this Mon-Sun week.
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [
          counterLog('2026-08-10', 1),
          counterLog('2026-08-11', 1),
          counterLog('2026-08-12', 1),
        ],
        date: DateTime(2026, 8, 15),
      );
      expect(status.status, DayStatusValue.success);
      expect(status.currentValue, 3);
    });

    test('only 2 done-days with the work week already over is certain '
        'failure (Red), and the count is days not reps', () {
      // Mon 8/10 - Fri 8/14 are the workdays; by Sat 8/15 all 5 have
      // already passed with only 2 done, so 3 workdays are genuinely
      // missed with zero remaining eligible days left in the pool —
      // failure is certain (FR-18), not merely "not yet met."
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [
          counterLog('2026-08-10', 5), // 5 reps in one day still counts 1
          counterLog('2026-08-11', 1),
        ],
        date: DateTime(2026, 8, 15),
      );
      expect(status.status, DayStatusValue.fail);
      expect(status.currentValue, 2); // not 6 — done-count, not summed
    });
  });

  group(
    'Pattern 3: Coffee limit — Daily / every day / Counter / At most 2',
    () {
      final v = version(
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        trackingType: TrackingType.counter,
        targetComparison: TargetComparison.atMost,
        targetValue: '2',
      );

      test('2 or fewer stays Pending until the day is known to be over', () {
        // Daily always has exactly 1 remaining/open eligible day (itself,
        // Story 1.8) — a later log that same day could still push the total
        // past 2, so it's not yet certain the limit won't be exceeded.
        final status = evaluate(
          goal: goal,
          versions: [v],
          logs: [counterLog('2026-08-15', 2)],
          date: DateTime(2026, 8, 15),
        );
        expect(status.status, DayStatusValue.pending);
      });

      test('exceeding the limit is immediate, certain failure', () {
        final status = evaluate(
          goal: goal,
          versions: [v],
          logs: [counterLog('2026-08-15', 3)],
          date: DateTime(2026, 8, 15),
        );
        expect(status.status, DayStatusValue.fail);
      });
    },
  );

  group(
    'Pattern 4: Sleep hours — Daily / every day / Counter / At least 7',
    () {
      final v = version(
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        trackingType: TrackingType.counter,
        targetComparison: TargetComparison.atLeast,
        targetValue: '7',
      );

      test('7.5 hours meets the target', () {
        final status = evaluate(
          goal: goal,
          versions: [v],
          logs: [counterLog('2026-08-15', 7.5)],
          date: DateTime(2026, 8, 15),
        );
        expect(status.status, DayStatusValue.success);
      });

      test('6 hours does not meet the target', () {
        final status = evaluate(
          goal: goal,
          versions: [v],
          logs: [counterLog('2026-08-15', 6)],
          date: DateTime(2026, 8, 15),
        );
        expect(status.status, DayStatusValue.pending);
      });
    },
  );

  group(
    'Pattern 5: Read every 3 days — Custom(every-N-days) / Boolean / Exactly 1',
    () {
      final v = version(
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: 'every_n_days:3',
        trackingType: TrackingType.boolean,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        versionStartDate: '2026-01-01',
      );

      test('an eligible day (Jan 7) logged done is Success', () {
        final status = evaluate(
          goal: goal,
          versions: [v],
          logs: [boolLog('2026-01-07')],
          date: DateTime(2026, 1, 7),
        );
        expect(status.status, DayStatusValue.success);
      });

      test('a non-eligible day (Jan 5) is Empty regardless of logging', () {
        final status = evaluate(
          goal: goal,
          versions: [v],
          logs: const [],
          date: DateTime(2026, 1, 5),
        );
        expect(status.status, DayStatusValue.empty);
      });
    },
  );

  group('Pattern 6: Deep clean, 2nd Saturday of month — Monthly / '
      'Nth-weekday-of-month / Boolean / Exactly 1', () {
    final v = version(
      evaluationPeriod: EvaluationPeriod.monthly,
      eligibleDaysRule: 'nth_weekday:2:6', // 2nd Saturday
      trackingType: TrackingType.boolean,
      targetComparison: TargetComparison.exactly,
      targetValue: '1',
    );

    test('logging done on the 2nd Saturday (Aug 8, 2026) is Success', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [boolLog('2026-08-08')],
        date: DateTime(2026, 8, 8),
      );
      expect(status.status, DayStatusValue.success);
    });

    test('not logging it is Pending, computed per-month independently', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: const [],
        date: DateTime(2026, 8, 8),
      );
      expect(status.status, DayStatusValue.pending);
    });
  });

  group('Pattern 7: Water 8 glasses, skip vacation days — Daily / every day + '
      'Blackout Dates / Counter / At least 8', () {
    final v = version(
      evaluationPeriod: EvaluationPeriod.daily,
      eligibleDaysRule: EligibleDaysRule.everyDay,
      trackingType: TrackingType.counter,
      targetComparison: TargetComparison.atLeast,
      targetValue: '8',
    );

    test('8 glasses meets the target', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [counterLog('2026-08-15', 8)],
        date: DateTime(2026, 8, 15),
      );
      expect(status.status, DayStatusValue.success);
    });

    test('a vacation day marked Blackout is exempt even with 0 logged', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: const [],
        blackoutDates: [
          BlackoutDate(id: 'bd-1', goalId: goal.id, date: '2026-08-15'),
        ],
        date: DateTime(2026, 8, 15),
      );
      expect(status.status, DayStatusValue.empty);
    });
  });

  group('Pattern 8: Quarterly review — Quarterly / specific day of month / '
      'Boolean / Exactly 1', () {
    final v = version(
      evaluationPeriod: EvaluationPeriod.quarterly,
      eligibleDaysRule: 'day_of_month:15',
      trackingType: TrackingType.boolean,
      targetComparison: TargetComparison.exactly,
      targetValue: '1',
    );

    test('logging done once on a 15th within the quarter is Success once no '
        'eligible day remains that could still overshoot Exactly-1', () {
      // Q3 2026 = Jul-Sep; eligible days are Jul 15, Aug 15, Sep 15.
      // Evaluating on Sep 16 (after Sep 15, the last eligible day, has
      // passed) closes the period — Sep 15 unlogged is a genuine miss,
      // not remaining capacity, so it can no longer push the count to 2
      // and overshoot the Exactly-1 target (Story 1.8).
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [boolLog('2026-08-15')],
        date: DateTime(2026, 9, 16),
      );
      expect(status.status, DayStatusValue.success);
    });

    test('not logging any of the quarter\'s eligible days is Pending', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: const [],
        date: DateTime(2026, 9, 1),
      );
      expect(status.status, DayStatusValue.pending);
    });
  });

  group('Pattern 9: Workout 10x in any rolling 14 days — Rolling Window(14d) / '
      'Counter / At least 10', () {
    final v = version(
      evaluationPeriod: EvaluationPeriod.rollingWindow(14),
      eligibleDaysRule: EligibleDaysRule.everyDay,
      trackingType: TrackingType.counter,
      targetComparison: TargetComparison.atLeast,
      targetValue: '10',
    );

    test('10 total within the trailing 14 days meets the target', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [counterLog('2026-08-05', 10)],
        date: DateTime(2026, 8, 15),
      );
      expect(status.status, DayStatusValue.success);
    });

    test('a log outside the trailing 14 days does not count', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [counterLog('2026-07-20', 10)], // 26 days before Aug 15
        date: DateTime(2026, 8, 15),
      );
      expect(status.status, DayStatusValue.pending);
      expect(status.currentValue, 0);
    });
  });

  group('Pattern 10: At least 3 days a week, any day — Weekly / every day / '
      'Boolean / At least 3', () {
    final v = version(
      evaluationPeriod: EvaluationPeriod.weekly,
      eligibleDaysRule: EligibleDaysRule.everyDay,
      trackingType: TrackingType.boolean,
      targetComparison: TargetComparison.atLeast,
      targetValue: '3',
    );

    test('3 done-days within the week meets the target', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [
          boolLog('2026-08-10'),
          boolLog('2026-08-13'),
          boolLog('2026-08-16'),
        ],
        date: DateTime(2026, 8, 15),
      );
      expect(status.status, DayStatusValue.success);
    });

    test('2 done-days is Pending', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [boolLog('2026-08-10'), boolLog('2026-08-13')],
        date: DateTime(2026, 8, 15),
      );
      expect(status.status, DayStatusValue.pending);
    });
  });

  group('Pattern 11: At least 3 days in the work week — Weekly / Workdays / '
      'Boolean / At least 3', () {
    final v = version(
      evaluationPeriod: EvaluationPeriod.weekly,
      eligibleDaysRule: EligibleDaysRule.workdays,
      trackingType: TrackingType.boolean,
      targetComparison: TargetComparison.atLeast,
      targetValue: '3',
    );

    test('3 done-workdays meets the target', () {
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [
          boolLog('2026-08-10'),
          boolLog('2026-08-11'),
          boolLog('2026-08-12'),
        ],
        date: DateTime(2026, 8, 15),
      );
      expect(status.status, DayStatusValue.success);
    });

    test('a weekend log does not count toward the workdays-only pool, and '
        'with the work week already over 2 of 5 is certain failure', () {
      // Evaluated on Saturday, all 5 workdays (Mon-Fri) have already
      // passed with only 2 done and the Saturday log doesn't count
      // (not an eligible day) — 3 workdays are genuinely missed with
      // zero remaining eligible days, so failure is certain (FR-18).
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [
          boolLog('2026-08-10'),
          boolLog('2026-08-11'),
          boolLog('2026-08-15'), // Saturday — not eligible
        ],
        date: DateTime(2026, 8, 15),
      );
      expect(status.status, DayStatusValue.fail);
      expect(status.currentValue, 2);
    });
  });

  group(
    'Pattern 12: Done on at least 3 of Mon/Tue/Thu/Sat — Weekly / arbitrary '
    'weekday set / Boolean / At least 3',
    () {
      final v = version(
        evaluationPeriod: EvaluationPeriod.weekly,
        eligibleDaysRule: EligibleDaysRule.fromWeekdays({1, 2, 4, 6}),
        trackingType: TrackingType.boolean,
        targetComparison: TargetComparison.atLeast,
        targetValue: '3',
      );

      test('3 of the 4 eligible days meets the target', () {
        final status = evaluate(
          goal: goal,
          versions: [v],
          logs: [
            boolLog('2026-08-10'), // Mon
            boolLog('2026-08-11'), // Tue
            boolLog('2026-08-13'), // Thu
          ],
          date: DateTime(2026, 8, 15),
        );
        expect(status.status, DayStatusValue.success);
      });

      test('2 of the 4 eligible days is Pending', () {
        final status = evaluate(
          goal: goal,
          versions: [v],
          logs: [boolLog('2026-08-10'), boolLog('2026-08-11')],
          date: DateTime(2026, 8, 15),
        );
        expect(status.status, DayStatusValue.pending);
      });
    },
  );

  group('Pattern 13: Done on exactly 2 of Mon/Tue/Thu/Sat — Weekly / arbitrary '
      'weekday set / Boolean / Exactly 2', () {
    final v = version(
      evaluationPeriod: EvaluationPeriod.weekly,
      eligibleDaysRule: EligibleDaysRule.fromWeekdays({1, 2, 4, 6}),
      trackingType: TrackingType.boolean,
      targetComparison: TargetComparison.exactly,
      targetValue: '2',
    );

    test('exactly 2 done-days meets the target once the week is over and no '
        'eligible day remains that could still overshoot it', () {
      // Eligible days this Mon-Sun week (8/10-8/16) are Mon 8/10, Tue
      // 8/11, Thu 8/13, Sat 8/15. Explicitly logging Thu 8/13 as
      // not-done, and evaluating on Sun 8/16 (after all 4 have passed),
      // closes the period — Sat 8/15 unlogged is a genuine miss, not
      // remaining capacity, so the count can no longer be pushed to 3
      // and overshoot Exactly-2 (Story 1.8).
      final status = evaluate(
        goal: goal,
        versions: [v],
        logs: [
          boolLog('2026-08-10'),
          boolLog('2026-08-11'),
          boolLog('2026-08-13', completed: false),
        ],
        date: DateTime(2026, 8, 16),
      );
      expect(status.status, DayStatusValue.success);
      expect(status.currentValue, 2);
    });

    test(
      '3 done-days overshoots Exactly-2 and is immediate, certain failure',
      () {
        final status = evaluate(
          goal: goal,
          versions: [v],
          logs: [
            boolLog('2026-08-10'),
            boolLog('2026-08-11'),
            boolLog('2026-08-13'),
          ],
          date: DateTime(2026, 8, 15),
        );
        expect(status.status, DayStatusValue.fail);
      },
    );
  });

  group('Axis independence (AC #3)', () {
    test('swapping Weekly for Biweekly (Pattern 10) only changes the period '
        'boundary — eligible-days/type/comparison logic is unaffected', () {
      final weekly = version(
        evaluationPeriod: EvaluationPeriod.weekly,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        trackingType: TrackingType.boolean,
        targetComparison: TargetComparison.atLeast,
        targetValue: '3',
      );
      final biweekly = version(
        evaluationPeriod: EvaluationPeriod.biweekly,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        trackingType: TrackingType.boolean,
        targetComparison: TargetComparison.atLeast,
        targetValue: '3',
      );
      final logs = [
        boolLog('2026-01-01'),
        boolLog('2026-01-02'),
        boolLog('2026-01-03'),
      ];

      // Both should meet the same "at least 3 boolean days" target — the
      // comparison and aggregation logic doesn't care which period type
      // produced the eligible-day pool it's counting over.
      final weeklyStatus = evaluate(
        goal: goal,
        versions: [weekly],
        logs: logs,
        date: DateTime(2026, 1, 3),
      );
      final biweeklyStatus = evaluate(
        goal: goal,
        versions: [biweekly],
        logs: logs,
        date: DateTime(2026, 1, 3),
      );

      expect(weeklyStatus.status, DayStatusValue.success);
      expect(biweeklyStatus.status, DayStatusValue.success);
    });

    test('swapping At Least for Exactly (same period/eligible-days/type) only '
        'changes the comparison outcome', () {
      final atLeast = version(
        evaluationPeriod: EvaluationPeriod.weekly,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        trackingType: TrackingType.boolean,
        targetComparison: TargetComparison.atLeast,
        targetValue: '2',
      );
      final exactly = version(
        evaluationPeriod: EvaluationPeriod.weekly,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        trackingType: TrackingType.boolean,
        targetComparison: TargetComparison.exactly,
        targetValue: '2',
      );
      final logs = [
        boolLog('2026-08-10'),
        boolLog('2026-08-11'),
        boolLog('2026-08-12'), // 3 done-days
      ];

      final atLeastStatus = evaluate(
        goal: goal,
        versions: [atLeast],
        logs: logs,
        date: DateTime(2026, 8, 15),
      );
      final exactlyStatus = evaluate(
        goal: goal,
        versions: [exactly],
        logs: logs,
        date: DateTime(2026, 8, 15),
      );

      // Same eligible-day pool, same aggregation (currentValue), but
      // different comparison outcomes — proving only the comparison axis
      // changed the result.
      expect(atLeastStatus.currentValue, exactlyStatus.currentValue);
      expect(atLeastStatus.status, DayStatusValue.success); // 3 >= 2
      // 3 overshoots Exactly-2 — an immediate, certain failure (Story
      // 1.8), not merely "not yet met."
      expect(exactlyStatus.status, DayStatusValue.fail);
    });
  });
}
