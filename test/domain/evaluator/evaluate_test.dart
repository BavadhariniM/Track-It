import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/blackout_date.dart';
import 'package:tracker/domain/entities/cheat_day.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/evaluate.dart';

void main() {
  final goal = Goal(
    id: 'goal-1',
    name: 'Read',
    archived: false,
    startDate: '2026-08-01',
  );

  GoalVersion dailyBooleanVersion({
    String versionStartDate = '2026-08-01',
    bool isPaused = false,
  }) {
    return GoalVersion(
      id: 'version-1',
      goalId: goal.id,
      versionStartDate: versionStartDate,
      evaluationPeriod: EvaluationPeriod.daily,
      eligibleDaysRule: EligibleDaysRule.everyDay,
      targetComparison: TargetComparison.exactly,
      targetValue: '1',
      trackingType: TrackingType.boolean,
      isPaused: isPaused,
    );
  }

  group('evaluate — Daily / every-day / Boolean / Exactly-1', () {
    test('an eligible day with no log yet is Pending, never Success', () {
      final status = evaluate(
        goal: goal,
        versions: [dailyBooleanVersion()],
        logs: const [],
        date: DateTime(2026, 8, 15),
      );

      expect(status.status, DayStatusValue.pending);
      expect(status.goalId, goal.id);
      expect(status.date, '2026-08-15');
    });

    test('an eligible day logged as completed is Success', () {
      final log = GoalLog(
        id: 'log-1',
        goalId: goal.id,
        date: '2026-08-15',
        timestamp: '2026-08-15T09:00:00.000',
        value: 1,
        completed: true,
      );

      final status = evaluate(
        goal: goal,
        versions: [dailyBooleanVersion()],
        logs: [log],
        date: DateTime(2026, 8, 15),
      );

      expect(status.status, DayStatusValue.success);
    });

    test('a date before the goal has any Version is Empty', () {
      final status = evaluate(
        goal: goal,
        versions: [dailyBooleanVersion(versionStartDate: '2026-08-01')],
        logs: const [],
        date: DateTime(2026, 7, 31),
      );

      expect(status.status, DayStatusValue.empty);
    });

    test(
      'a date governed by a paused Version is Empty (AD-4 pause-awareness)',
      () {
        final status = evaluate(
          goal: goal,
          versions: [dailyBooleanVersion(isPaused: true)],
          logs: const [],
          date: DateTime(2026, 8, 15),
        );

        expect(status.status, DayStatusValue.empty);
      },
    );

    test('versions and logs given out of order do not change the result', () {
      final earlyVersion = dailyBooleanVersion(versionStartDate: '2026-08-01');
      final laterVersion = GoalVersion(
        id: 'version-2',
        goalId: goal.id,
        versionStartDate: '2026-09-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );
      final log = GoalLog(
        id: 'log-1',
        goalId: goal.id,
        date: '2026-08-15',
        timestamp: '2026-08-15T09:00:00.000',
        value: 1,
        completed: true,
      );
      final unrelatedLog = GoalLog(
        id: 'log-2',
        goalId: goal.id,
        date: '2026-08-20',
        timestamp: '2026-08-20T09:00:00.000',
        value: 1,
        completed: true,
      );

      // Deliberately passed out of chronological order.
      final status = evaluate(
        goal: goal,
        versions: [laterVersion, earlyVersion],
        logs: [unrelatedLog, log],
        date: DateTime(2026, 8, 15),
      );

      expect(status.status, DayStatusValue.success);
    });
  });

  group('evaluate — Daily / every-day / Counter / At-least', () {
    GoalVersion dailyCounterVersion({String targetValue = '8'}) {
      return GoalVersion(
        id: 'version-counter',
        goalId: goal.id,
        versionStartDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.atLeast,
        targetValue: targetValue,
        trackingType: TrackingType.counter,
      );
    }

    GoalLog counterLog({required String id, required double value}) {
      return GoalLog(
        id: id,
        goalId: goal.id,
        date: '2026-08-15',
        timestamp: '2026-08-15T09:00:00.000',
        value: value,
        completed: value > 0,
      );
    }

    test('a single log below target is Pending, not Fail', () {
      final status = evaluate(
        goal: goal,
        versions: [dailyCounterVersion()],
        logs: [counterLog(id: 'log-1', value: 5)],
        date: DateTime(2026, 8, 15),
      );

      expect(status.status, DayStatusValue.pending);
      expect(status.currentValue, 5);
      expect(status.targetValue, 8);
    });

    test('a single log meeting or exceeding target is Success', () {
      final status = evaluate(
        goal: goal,
        versions: [dailyCounterVersion()],
        logs: [counterLog(id: 'log-1', value: 8)],
        date: DateTime(2026, 8, 15),
      );

      expect(status.status, DayStatusValue.success);
      expect(status.currentValue, 8);
    });

    test('multiple same-day logs sum defensively even though the write path '
        'only ever upserts one row', () {
      final status = evaluate(
        goal: goal,
        versions: [dailyCounterVersion()],
        logs: [
          counterLog(id: 'log-1', value: 3),
          counterLog(id: 'log-2', value: 5),
        ],
        date: DateTime(2026, 8, 15),
      );

      expect(status.currentValue, 8);
      expect(status.status, DayStatusValue.success);
    });

    test('decimal values are summed and compared without precision loss', () {
      final status = evaluate(
        goal: goal,
        versions: [dailyCounterVersion(targetValue: '8')],
        logs: [counterLog(id: 'log-1', value: 7.5)],
        date: DateTime(2026, 8, 15),
      );

      expect(status.currentValue, 7.5);
      expect(status.status, DayStatusValue.pending);
    });

    test('no logs yet is Pending with currentValue defaulting to 0', () {
      final status = evaluate(
        goal: goal,
        versions: [dailyCounterVersion()],
        logs: const [],
        date: DateTime(2026, 8, 15),
      );

      expect(status.status, DayStatusValue.pending);
      expect(status.currentValue, 0);
    });
  });

  group('evaluate — Weekly / Boolean period aggregation', () {
    GoalVersion weeklyVersion({
      String versionStartDate = '2026-08-01',
      bool isPaused = false,
    }) {
      return GoalVersion(
        id: 'version-weekly',
        goalId: goal.id,
        versionStartDate: versionStartDate,
        evaluationPeriod: EvaluationPeriod.weekly,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.atLeast,
        targetValue: '3',
        trackingType: TrackingType.boolean,
        isPaused: isPaused,
      );
    }

    GoalLog doneLog(String date) => GoalLog(
      id: 'log-$date',
      goalId: goal.id,
      date: date,
      timestamp: '${date}T09:00:00.000',
      value: 1,
      completed: true,
    );

    test(
      '3 completions within the Mon–Sun week meets an at-least-3 target',
      () {
        final status = evaluate(
          goal: goal,
          versions: [weeklyVersion()],
          logs: [
            doneLog('2026-08-10'),
            doneLog('2026-08-12'),
            doneLog('2026-08-14'),
          ],
          date: DateTime(
            2026,
            8,
            15,
          ), // Saturday, same week (Mon 8/10–Sun 8/16)
        );

        expect(status.status, DayStatusValue.success);
        expect(status.currentValue, 3);
      },
    );

    test('only 2 completions within the week is Pending, not Fail', () {
      final status = evaluate(
        goal: goal,
        versions: [weeklyVersion()],
        logs: [doneLog('2026-08-10'), doneLog('2026-08-12')],
        date: DateTime(2026, 8, 15),
      );

      expect(status.status, DayStatusValue.pending);
      expect(status.currentValue, 2);
    });

    test(
      'a completion in the following week does not count toward this week',
      () {
        final status = evaluate(
          goal: goal,
          versions: [weeklyVersion()],
          logs: [
            doneLog('2026-08-10'),
            doneLog('2026-08-12'),
            doneLog('2026-08-17'), // Monday of the NEXT week
          ],
          date: DateTime(2026, 8, 15),
        );

        expect(status.currentValue, 2);
        expect(status.status, DayStatusValue.pending);
      },
    );

    test('a pause-only Version boundary does not split the period, and paused '
        'days contribute zero to the eligible pool (AD-5 carve-out)', () {
      // Same weekly/at-least-3/Boolean rule on both sides of a 2-day
      // pause in the middle of the week — must NOT be treated as a
      // rule-change boundary that truncates the period.
      final beforePause = weeklyVersion(versionStartDate: '2026-08-01');
      final paused = weeklyVersion(
        versionStartDate: '2026-08-12',
        isPaused: true,
      );
      final afterPause = weeklyVersion(versionStartDate: '2026-08-14');

      // Aug 12 is logged done, but it falls under the paused Version, so
      // it must not count toward the total.
      final loggedThroughPause = evaluate(
        goal: goal,
        versions: [beforePause, paused, afterPause],
        logs: [
          doneLog('2026-08-10'),
          doneLog('2026-08-12'),
          doneLog('2026-08-14'),
        ],
        date: DateTime(2026, 8, 15),
      );
      expect(loggedThroughPause.currentValue, 2); // Aug 12 excluded
      expect(loggedThroughPause.status, DayStatusValue.pending);

      // Adding a 3rd *eligible* (non-paused) completion reaches target,
      // proving the period stayed one continuous window rather than
      // being split into unreachable fragments.
      final metAfterThirdEligibleLog = evaluate(
        goal: goal,
        versions: [beforePause, paused, afterPause],
        logs: [
          doneLog('2026-08-10'),
          doneLog('2026-08-12'),
          doneLog('2026-08-14'),
          doneLog('2026-08-15'),
        ],
        date: DateTime(2026, 8, 15),
      );
      expect(metAfterThirdEligibleLog.currentValue, 3);
      expect(metAfterThirdEligibleLog.status, DayStatusValue.success);
    });
  });

  group('evaluate — Bug 9: `today` vs `date` for period aggregation', () {
    GoalVersion weekendWeeklyVersion({String targetValue = '1'}) {
      return GoalVersion(
        id: 'version-weekend',
        goalId: goal.id,
        versionStartDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.weekly,
        eligibleDaysRule: EligibleDaysRule.weekends,
        targetComparison: TargetComparison.atLeast,
        targetValue: targetValue,
        trackingType: TrackingType.boolean,
      );
    }

    test(
      'a future weekend cell queried mid-week stays Pending, not the Fail '
      'the pre-fix `date`-as-vantage logic would certainly have produced',
      () {
        // Week of Mon 8/10–Sun 8/16, weekend-only, at-least-2 (i.e. BOTH
        // Sat and Sun are needed), never logged. Real today is Wed 8/12;
        // the cell being rendered is the future Sunday. This case is
        // deliberately chosen to discriminate old vs. new behavior: under
        // the pre-fix `!cursor.isBefore(date)` vantage (date = Sunday),
        // Saturday would look already-elapsed relative to the queried
        // Sunday and get excluded from `remainingEligibleDays`, leaving
        // only 1 remaining day against a target of 2 — mathematically
        // certain Fail, even though real-life today is only Wednesday and
        // neither weekend day has happened yet. The fixed `today`-vantage
        // logic keeps both Sat and Sun open, so the goal is still
        // reachable and must stay Pending.
        final status = evaluate(
          goal: goal,
          versions: [weekendWeeklyVersion(targetValue: '2')],
          logs: const [],
          date: DateTime(2026, 8, 16), // Sunday
          today: DateTime(2026, 8, 12), // Wednesday, same week
        );

        expect(status.status, DayStatusValue.pending);
      },
    );

    test(
      'a past cell within a still-ongoing period shows that period\'s '
      'current live status, not a stale as-of-that-day snapshot',
      () {
        // Week of Mon 8/10–Sun 8/16, every day eligible, at-least-3,
        // logged done on Mon and Wed only. Real today is Thu 8/13 (the
        // week is still open). Querying Monday's own cell must return the
        // exact same live status as querying today's cell — Monday is not
        // stuck showing whatever the answer would have been "as observed
        // on Monday."
        final version = GoalVersion(
          id: 'version-everyday',
          goalId: goal.id,
          versionStartDate: '2026-08-01',
          evaluationPeriod: EvaluationPeriod.weekly,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: TargetComparison.atLeast,
          targetValue: '3',
          trackingType: TrackingType.boolean,
        );
        final logs = [
          GoalLog(
            id: 'log-mon',
            goalId: goal.id,
            date: '2026-08-10',
            timestamp: '2026-08-10T09:00:00.000',
            value: 1,
            completed: true,
          ),
          GoalLog(
            id: 'log-wed',
            goalId: goal.id,
            date: '2026-08-12',
            timestamp: '2026-08-12T09:00:00.000',
            value: 1,
            completed: true,
          ),
        ];
        final today = DateTime(2026, 8, 13); // Thursday, mid-week

        final mondayCell = evaluate(
          goal: goal,
          versions: [version],
          logs: logs,
          date: DateTime(2026, 8, 10), // Monday — a past date
          today: today,
        );
        final todaysCell = evaluate(
          goal: goal,
          versions: [version],
          logs: logs,
          date: today,
          today: today,
        );

        expect(mondayCell.status, todaysCell.status);
        expect(mondayCell.currentValue, todaysCell.currentValue);
        expect(mondayCell.status, DayStatusValue.pending);
      },
    );

    test(
      'every cell of an already-concluded past week shows the same final '
      'outcome, regardless of which date within it is queried',
      () {
        // Week of Mon 8/10–Sun 8/16, weekend-only, at-least-1, never
        // logged. Real today is now well after the week ended (8/20).
        final versions = [weekendWeeklyVersion()];
        const logs = <GoalLog>[];
        final realToday = DateTime(2026, 8, 20);

        final mondayCell = evaluate(
          goal: goal,
          versions: versions,
          logs: logs,
          date: DateTime(2026, 8, 10), // Monday
          today: realToday,
        );
        final saturdayCell = evaluate(
          goal: goal,
          versions: versions,
          logs: logs,
          date: DateTime(2026, 8, 15), // Saturday
          today: realToday,
        );

        expect(mondayCell.status, DayStatusValue.fail);
        expect(saturdayCell.status, DayStatusValue.fail);
      },
    );

    test('omitting `today` defaults it to `date`, unchanged from before Bug 9', () {
      final withoutToday = evaluate(
        goal: goal,
        versions: [weekendWeeklyVersion()],
        logs: const [],
        date: DateTime(2026, 8, 15), // Saturday
      );
      final explicitSameAsDate = evaluate(
        goal: goal,
        versions: [weekendWeeklyVersion()],
        logs: const [],
        date: DateTime(2026, 8, 15),
        today: DateTime(2026, 8, 15),
      );

      expect(withoutToday.status, explicitSameAsDate.status);
      expect(withoutToday.currentValue, explicitSameAsDate.currentValue);
    });
  });

  group('evaluate — Rolling Window / Counter period aggregation', () {
    GoalVersion rollingVersion() {
      return GoalVersion(
        id: 'version-rolling',
        goalId: goal.id,
        versionStartDate: '2026-01-01',
        evaluationPeriod: EvaluationPeriod.rollingWindow(14),
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.atLeast,
        targetValue: '10',
        trackingType: TrackingType.counter,
      );
    }

    GoalLog counterLog(String date, double value) => GoalLog(
      id: 'log-$date',
      goalId: goal.id,
      date: date,
      timestamp: '${date}T09:00:00.000',
      value: value,
      completed: value > 0,
    );

    test('the window shifts with the evaluation date — a log that ages out stops counting', () {
      final logs = [counterLog('2026-08-01', 10)];

      final withinWindow = evaluate(
        goal: goal,
        versions: [rollingVersion()],
        logs: logs,
        date: DateTime(2026, 8, 10), // 9 days after the log — still within 14
      );
      final agedOut = evaluate(
        goal: goal,
        versions: [rollingVersion()],
        logs: logs,
        date: DateTime(2026, 8, 20), // 19 days after the log — outside 14
      );

      expect(withinWindow.currentValue, 10);
      expect(withinWindow.status, DayStatusValue.success);
      expect(agedOut.currentValue, 0);
      expect(agedOut.status, DayStatusValue.pending);
    });
  });

  group('evaluate — ordering independence (AC #4, full AD-4 signature)', () {
    test(
      'cheatDays/blackoutDates in reversed order do not change the result',
      () {
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
        final log = GoalLog(
          id: 'log-1',
          goalId: goal.id,
          date: '2026-08-15',
          timestamp: '2026-08-15T09:00:00.000',
          value: 1,
          completed: true,
        );
        final cheatDayA = CheatDay(
          id: 'cd-1',
          goalId: goal.id,
          date: '2026-08-05',
        );
        final cheatDayB = CheatDay(
          id: 'cd-2',
          goalId: goal.id,
          date: '2026-08-10',
        );
        final blackoutA = BlackoutDate(
          id: 'bd-1',
          goalId: goal.id,
          date: '2026-08-03',
        );
        final blackoutB = BlackoutDate(
          id: 'bd-2',
          goalId: goal.id,
          date: '2026-08-07',
        );

        final forward = evaluate(
          goal: goal,
          versions: [version],
          logs: [log],
          cheatDays: [cheatDayA, cheatDayB],
          blackoutDates: [blackoutA, blackoutB],
          date: DateTime(2026, 8, 15),
        );
        final reversed = evaluate(
          goal: goal,
          versions: [version],
          logs: [log],
          cheatDays: [cheatDayB, cheatDayA],
          blackoutDates: [blackoutB, blackoutA],
          date: DateTime(2026, 8, 15),
        );

        expect(reversed.status, forward.status);
        expect(reversed.currentValue, forward.currentValue);
      },
    );
  });

  group('evaluate — Eligible-Days Rule (Story 1.4)', () {
    test('a non-eligible day is Empty, never Pending or Fail', () {
      final workdaysOnly = GoalVersion(
        id: 'version-workdays',
        goalId: goal.id,
        versionStartDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.workdays,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );

      // 2026-08-15 is a Saturday.
      final status = evaluate(
        goal: goal,
        versions: [workdaysOnly],
        logs: const [],
        date: DateTime(2026, 8, 15),
      );

      expect(status.status, DayStatusValue.empty);
    });

    test('an eligible day under the same rule still evaluates normally', () {
      final workdaysOnly = GoalVersion(
        id: 'version-workdays',
        goalId: goal.id,
        versionStartDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.workdays,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );

      // 2026-08-14 is a Friday.
      final status = evaluate(
        goal: goal,
        versions: [workdaysOnly],
        logs: const [],
        date: DateTime(2026, 8, 14),
      );

      expect(status.status, DayStatusValue.pending);
    });
  });

  group('evaluate — Blackout Dates (Story 1.6)', () {
    final dailyVersion = GoalVersion(
      id: 'version-1',
      goalId: goal.id,
      versionStartDate: '2026-08-01',
      evaluationPeriod: EvaluationPeriod.daily,
      eligibleDaysRule: EligibleDaysRule.everyDay,
      targetComparison: TargetComparison.exactly,
      targetValue: '1',
      trackingType: TrackingType.boolean,
    );

    test('an unlogged blacked-out day is Empty, not Pending', () {
      final status = evaluate(
        goal: goal,
        versions: [dailyVersion],
        logs: const [],
        blackoutDates: [
          BlackoutDate(id: 'bd-1', goalId: goal.id, date: '2026-08-15'),
        ],
        date: DateTime(2026, 8, 15),
      );

      expect(status.status, DayStatusValue.empty);
    });

    test(
      'a blacked-out day with an explicit not-done log is exempted from Fail',
      () {
        final status = evaluate(
          goal: goal,
          versions: [dailyVersion],
          logs: [
            GoalLog(
              id: 'log-1',
              goalId: goal.id,
              date: '2026-08-15',
              timestamp: '2026-08-15T09:00:00.000',
              value: 0,
              completed: false,
            ),
          ],
          blackoutDates: [
            BlackoutDate(id: 'bd-1', goalId: goal.id, date: '2026-08-15'),
          ],
          date: DateTime(2026, 8, 15),
        );

        expect(status.status, DayStatusValue.empty);
      },
    );

    test('a blacked-out day that was still logged done stays Success', () {
      final status = evaluate(
        goal: goal,
        versions: [dailyVersion],
        logs: [
          GoalLog(
            id: 'log-1',
            goalId: goal.id,
            date: '2026-08-15',
            timestamp: '2026-08-15T09:00:00.000',
            value: 1,
            completed: true,
          ),
        ],
        blackoutDates: [
          BlackoutDate(id: 'bd-1', goalId: goal.id, date: '2026-08-15'),
        ],
        date: DateTime(2026, 8, 15),
      );

      expect(status.status, DayStatusValue.success);
    });

    test('a Blackout Date on a different date, or for a different goal, has no effect', () {
      final differentDate = evaluate(
        goal: goal,
        versions: [dailyVersion],
        logs: const [],
        blackoutDates: [
          BlackoutDate(id: 'bd-1', goalId: goal.id, date: '2026-08-20'),
        ],
        date: DateTime(2026, 8, 15),
      );
      expect(differentDate.status, DayStatusValue.pending);

      final differentGoal = evaluate(
        goal: goal,
        versions: [dailyVersion],
        logs: const [],
        blackoutDates: [
          BlackoutDate(
            id: 'bd-1',
            goalId: 'some-other-goal',
            date: '2026-08-15',
          ),
        ],
        date: DateTime(2026, 8, 15),
      );
      expect(differentGoal.status, DayStatusValue.pending);
    });

    test('a Blackout Date within a Weekly period changes neither the required '
        'count nor the eligible-day pool (FR-10 consequence)', () {
      final weeklyVersion = GoalVersion(
        id: 'version-weekly',
        goalId: goal.id,
        versionStartDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.weekly,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.atLeast,
        targetValue: '3',
        trackingType: TrackingType.boolean,
      );
      GoalLog doneLog(String date) => GoalLog(
        id: 'log-$date',
        goalId: goal.id,
        date: date,
        timestamp: '${date}T09:00:00.000',
        value: 1,
        completed: true,
      );
      final logs = [
        doneLog('2026-08-10'),
        doneLog('2026-08-12'),
      ]; // 2 of 3 needed, within Mon 8/10–Sun 8/16.

      final withoutBlackout = evaluate(
        goal: goal,
        versions: [weeklyVersion],
        logs: logs,
        date: DateTime(2026, 8, 15),
      );
      final withBlackout = evaluate(
        goal: goal,
        versions: [weeklyVersion],
        logs: logs,
        blackoutDates: [
          BlackoutDate(id: 'bd-1', goalId: goal.id, date: '2026-08-13'),
        ],
        date: DateTime(2026, 8, 15),
      );

      // Same required count (target unchanged), same eligible-day pool
      // (currentValue unchanged) — the Blackout Date reduces neither.
      expect(withBlackout.targetValue, withoutBlackout.targetValue);
      expect(withBlackout.currentValue, withoutBlackout.currentValue);
      expect(withBlackout.status, withoutBlackout.status);
    });
  });

  group('evaluate — Cheat Days (Story 2.4)', () {
    final dailyVersion = GoalVersion(
      id: 'version-1',
      goalId: goal.id,
      versionStartDate: '2026-08-01',
      evaluationPeriod: EvaluationPeriod.daily,
      eligibleDaysRule: EligibleDaysRule.everyDay,
      targetComparison: TargetComparison.exactly,
      targetValue: '1',
      trackingType: TrackingType.boolean,
    );

    test('AC 1: an unlogged Cheat Day is Cheat, not Pending', () {
      final status = evaluate(
        goal: goal,
        versions: [dailyVersion],
        logs: const [],
        cheatDays: [CheatDay(id: 'cd-1', goalId: goal.id, date: '2026-08-15')],
        date: DateTime(2026, 8, 15),
      );

      expect(status.status, DayStatusValue.cheat);
    });

    test('a Cheat Day with an explicit not-done log is exempted from Fail, '
        'rendered Cheat', () {
      final status = evaluate(
        goal: goal,
        versions: [dailyVersion],
        logs: [
          GoalLog(
            id: 'log-1',
            goalId: goal.id,
            date: '2026-08-15',
            timestamp: '2026-08-15T09:00:00.000',
            value: 0,
            completed: false,
          ),
        ],
        cheatDays: [CheatDay(id: 'cd-1', goalId: goal.id, date: '2026-08-15')],
        date: DateTime(2026, 8, 15),
      );

      expect(status.status, DayStatusValue.cheat);
    });

    test('a Cheat Day that was still logged done stays Success', () {
      final status = evaluate(
        goal: goal,
        versions: [dailyVersion],
        logs: [
          GoalLog(
            id: 'log-1',
            goalId: goal.id,
            date: '2026-08-15',
            timestamp: '2026-08-15T09:00:00.000',
            value: 1,
            completed: true,
          ),
        ],
        cheatDays: [CheatDay(id: 'cd-1', goalId: goal.id, date: '2026-08-15')],
        date: DateTime(2026, 8, 15),
      );

      expect(status.status, DayStatusValue.success);
    });

    test(
      'a Cheat Day on a different date, or for a different goal, has no effect',
      () {
        final differentDate = evaluate(
          goal: goal,
          versions: [dailyVersion],
          logs: const [],
          cheatDays: [
            CheatDay(id: 'cd-1', goalId: goal.id, date: '2026-08-20'),
          ],
          date: DateTime(2026, 8, 15),
        );
        expect(differentDate.status, DayStatusValue.pending);

        final differentGoal = evaluate(
          goal: goal,
          versions: [dailyVersion],
          logs: const [],
          cheatDays: [
            CheatDay(id: 'cd-1', goalId: 'some-other-goal', date: '2026-08-15'),
          ],
          date: DateTime(2026, 8, 15),
        );
        expect(differentGoal.status, DayStatusValue.pending);
      },
    );

    test('AC 3: within a Weekly period, a used Cheat Day changes neither the '
        'required count nor the eligible-day pool, and applies identically '
        'across At Least, At Most, and Exactly', () {
      for (final comparison in [
        TargetComparison.atLeast,
        TargetComparison.atMost,
        TargetComparison.exactly,
      ]) {
        final weeklyVersion = GoalVersion(
          id: 'version-weekly',
          goalId: goal.id,
          versionStartDate: '2026-08-01',
          evaluationPeriod: EvaluationPeriod.weekly,
          eligibleDaysRule: EligibleDaysRule.everyDay,
          targetComparison: comparison,
          targetValue: '3',
          trackingType: TrackingType.boolean,
        );
        GoalLog doneLog(String date) => GoalLog(
          id: 'log-$date',
          goalId: goal.id,
          date: date,
          timestamp: '${date}T09:00:00.000',
          value: 1,
          completed: true,
        );
        final logs = [doneLog('2026-08-10'), doneLog('2026-08-12')];

        final withoutCheatDay = evaluate(
          goal: goal,
          versions: [weeklyVersion],
          logs: logs,
          date: DateTime(2026, 8, 15),
        );
        final withCheatDay = evaluate(
          goal: goal,
          versions: [weeklyVersion],
          logs: logs,
          cheatDays: [
            CheatDay(id: 'cd-1', goalId: goal.id, date: '2026-08-13'),
          ],
          date: DateTime(2026, 8, 15),
        );

        expect(
          withCheatDay.targetValue,
          withoutCheatDay.targetValue,
          reason: '$comparison: required count must be unchanged',
        );
        expect(
          withCheatDay.currentValue,
          withoutCheatDay.currentValue,
          reason: '$comparison: eligible-day pool must be unchanged',
        );
      }
    });

    test('AC 1/3: a used Cheat Day keeps an otherwise-certain-Fail Weekly '
        'At Least period Pending instead, without inflating currentValue', () {
      final weeklyVersion = GoalVersion(
        id: 'version-weekly',
        goalId: goal.id,
        versionStartDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.weekly,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.atLeast,
        targetValue: '7', // must succeed every eligible day this week.
        trackingType: TrackingType.boolean,
      );
      GoalLog doneLog(String date) => GoalLog(
        id: 'log-$date',
        goalId: goal.id,
        date: date,
        timestamp: '${date}T09:00:00.000',
        value: 1,
        completed: true,
      );
      // Mon/Tue done; Wed missed (no log). Query date: Thursday, so
      // Mon–Wed are already closed and Thu–Sun are still open.
      final logs = [doneLog('2026-08-10'), doneLog('2026-08-11')];

      final withoutCheatDay = evaluate(
        goal: goal,
        versions: [weeklyVersion],
        logs: logs,
        date: DateTime(2026, 8, 13),
      );
      final withCheatDay = evaluate(
        goal: goal,
        versions: [weeklyVersion],
        logs: logs,
        cheatDays: [CheatDay(id: 'cd-1', goalId: goal.id, date: '2026-08-12')],
        date: DateTime(2026, 8, 13),
      );

      expect(withoutCheatDay.status, DayStatusValue.fail);
      expect(withCheatDay.status, DayStatusValue.pending);
      expect(withCheatDay.targetValue, withoutCheatDay.targetValue);
      expect(withCheatDay.currentValue, withoutCheatDay.currentValue);
    });
  });
}
