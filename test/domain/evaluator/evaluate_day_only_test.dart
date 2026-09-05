import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/blackout_date.dart';
import 'package:tracker/domain/entities/cheat_day.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/evaluate.dart';

/// Covers `evaluateDayOnly()`: "did this specific date get logged done,"
/// as distinct from `evaluate()`'s period-aggregate "is the goal on track"
/// question — the two must be able to disagree for a period-type goal, and
/// `evaluateDayOnly` must reuse `_evaluateDay`'s existing single-day rules
/// (blackout/cheat/elapsed/pause/eligibility) unchanged for any period type.
void main() {
  final goal = Goal(
    id: 'goal-1',
    name: 'Read twice a week',
    archived: false,
    startDate: '2026-08-03', // a Monday
  );

  GoalLog boolLog(String date, {bool completed = true}) => GoalLog(
    id: 'log-$date-$completed',
    goalId: goal.id,
    date: date,
    timestamp: '${date}T09:00:00.000',
    value: completed ? 1 : 0,
    completed: completed,
  );

  GoalVersion weeklyBooleanVersion({
    String versionStartDate = '2026-08-03',
    String eligibleDaysRule = EligibleDaysRule.everyDay,
    bool isPaused = false,
    double target = 2,
  }) {
    return GoalVersion(
      id: 'v-weekly-bool',
      goalId: goal.id,
      versionStartDate: versionStartDate,
      evaluationPeriod: EvaluationPeriod.weekly,
      eligibleDaysRule: eligibleDaysRule,
      targetComparison: TargetComparison.atLeast,
      targetValue: '$target',
      trackingType: TrackingType.boolean,
      isPaused: isPaused,
    );
  }

  group('evaluateDayOnly — disagrees with evaluate() for a period-type goal', () {
    test(
      'a Weekly "at least 2" boolean goal, 1-of-2 logged: the logged day is '
      'day-only Success while evaluate() still reports the week Pending',
      () {
        final versions = [weeklyBooleanVersion()];
        final logs = [boolLog('2026-08-05')]; // Wednesday

        final periodStatus = evaluate(
          goal: goal,
          versions: versions,
          logs: logs,
          date: DateTime(2026, 8, 5),
          today: DateTime(2026, 8, 5),
        );
        final dayOnlyStatus = evaluateDayOnly(
          goal: goal,
          versions: versions,
          logs: logs,
          date: DateTime(2026, 8, 5),
          today: DateTime(2026, 8, 5),
        );

        expect(periodStatus.status, DayStatusValue.pending);
        expect(dayOnlyStatus.status, DayStatusValue.success);
      },
    );

    test(
      'the same week\'s unlogged days stay day-only Pending while today-or-future',
      () {
        final versions = [weeklyBooleanVersion()];
        final logs = [boolLog('2026-08-05')];

        final status = evaluateDayOnly(
          goal: goal,
          versions: versions,
          logs: logs,
          date: DateTime(2026, 8, 6), // Thursday, unlogged
          today: DateTime(2026, 8, 5), // Wednesday is "today"
        );

        expect(status.status, DayStatusValue.pending);
      },
    );

    test('an unlogged, already-elapsed day within the week is day-only Fail', () {
      final versions = [weeklyBooleanVersion()];
      final logs = [boolLog('2026-08-05')];

      final status = evaluateDayOnly(
        goal: goal,
        versions: versions,
        logs: logs,
        date: DateTime(2026, 8, 4), // Tuesday, unlogged
        today: DateTime(2026, 8, 6), // Thursday: Tuesday has elapsed
      );

      expect(status.status, DayStatusValue.fail);
    });

    test('an explicit not-done log for that date is day-only Fail regardless of elapsed', () {
      final versions = [weeklyBooleanVersion()];
      final logs = [boolLog('2026-08-05', completed: false)];

      final status = evaluateDayOnly(
        goal: goal,
        versions: versions,
        logs: logs,
        date: DateTime(2026, 8, 5),
        today: DateTime(2026, 8, 5),
      );

      expect(status.status, DayStatusValue.fail);
    });
  });

  group('evaluateDayOnly — blackout/cheat exemptions carry over unchanged', () {
    test('an unlogged, blacked-out date is Empty, not Fail, even once elapsed', () {
      final versions = [weeklyBooleanVersion()];

      final status = evaluateDayOnly(
        goal: goal,
        versions: versions,
        logs: const [],
        blackoutDates: [
          BlackoutDate(id: 'bd-1', goalId: goal.id, date: '2026-08-04'),
        ],
        date: DateTime(2026, 8, 4),
        today: DateTime(2026, 8, 6),
      );

      expect(status.status, DayStatusValue.empty);
    });

    test('an unlogged, used Cheat Day is Cheat, not Fail, even once elapsed', () {
      final versions = [weeklyBooleanVersion()];

      final status = evaluateDayOnly(
        goal: goal,
        versions: versions,
        logs: const [],
        cheatDays: [CheatDay(id: 'cd-1', goalId: goal.id, date: '2026-08-04')],
        date: DateTime(2026, 8, 4),
        today: DateTime(2026, 8, 6),
      );

      expect(status.status, DayStatusValue.cheat);
    });
  });

  group('evaluateDayOnly — pause / pre-start / ineligibility', () {
    test('a date governed by a paused Version is Empty', () {
      final versions = [weeklyBooleanVersion(isPaused: true)];

      final status = evaluateDayOnly(
        goal: goal,
        versions: versions,
        logs: const [],
        date: DateTime(2026, 8, 5),
        today: DateTime(2026, 8, 5),
      );

      expect(status.status, DayStatusValue.empty);
    });

    test('a date before any Version exists is Empty', () {
      final versions = [weeklyBooleanVersion(versionStartDate: '2026-08-10')];

      final status = evaluateDayOnly(
        goal: goal,
        versions: versions,
        logs: const [],
        date: DateTime(2026, 8, 5),
        today: DateTime(2026, 8, 5),
      );

      expect(status.status, DayStatusValue.empty);
    });

    test(
      'a date this goal\'s own eligible-days rule excludes is Empty, even '
      'for a Weekly (not Daily) goal',
      () {
        final versions = [
          weeklyBooleanVersion(eligibleDaysRule: EligibleDaysRule.workdays),
        ];

        final status = evaluateDayOnly(
          goal: goal,
          versions: versions,
          logs: const [],
          date: DateTime(2026, 8, 8), // a Saturday
          today: DateTime(2026, 8, 8),
        );

        expect(status.status, DayStatusValue.empty);
      },
    );
  });

  group('evaluateDayOnly — summed Counter falls back to the period aggregate', () {
    test(
      'matches whatever evaluate() returns for the same date, never a '
      'fabricated single-day verdict',
      () {
        final counterVersion = GoalVersion(
          id: 'v-weekly-counter',
          goalId: goal.id,
          versionStartDate: '2026-08-03',
          evaluationPeriod: EvaluationPeriod.weekly,
          eligibleDaysRule: EligibleDaysRule.workdays,
          targetComparison: TargetComparison.atLeast,
          targetValue: '2',
          trackingType: TrackingType.counter,
        );
        final logs = [
          GoalLog(
            id: 'log-1',
            goalId: goal.id,
            date: '2026-08-03',
            timestamp: '2026-08-03T09:00:00.000',
            value: 1,
            completed: true,
          ),
        ];

        // A Saturday: individually non-eligible under the workdays-only
        // rule, but the Counter fallback must still show the week's live
        // aggregate rather than short-circuiting to Empty on this date.
        final periodStatus = evaluate(
          goal: goal,
          versions: [counterVersion],
          logs: logs,
          date: DateTime(2026, 8, 8),
          today: DateTime(2026, 8, 8),
        );
        final dayOnlyStatus = evaluateDayOnly(
          goal: goal,
          versions: [counterVersion],
          logs: logs,
          date: DateTime(2026, 8, 8),
          today: DateTime(2026, 8, 8),
        );

        expect(dayOnlyStatus.status, periodStatus.status);
        expect(dayOnlyStatus.currentValue, periodStatus.currentValue);
      },
    );
  });
}
