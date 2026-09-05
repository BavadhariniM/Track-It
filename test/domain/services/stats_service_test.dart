import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/cheat_day.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/date_format.dart';
import 'package:tracker/domain/services/stats_service.dart';

import 'fakes.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// The Monday on or before [date] (Week-Start = Monday, `StatsService`'s
/// default) — used to build weekly fixtures whose period boundaries are
/// deterministic regardless of which weekday tests happen to run on.
DateTime _mondayOnOrBefore(DateTime date) {
  final diff = (date.weekday - DateTime.monday) % 7;
  return date.subtract(Duration(days: diff));
}

GoalLog _completedLog(String goalId, String date, {bool completed = true}) {
  return GoalLog(
    id: 'log-$goalId-$date',
    goalId: goalId,
    date: date,
    timestamp: '${date}T09:00:00',
    value: completed ? 1 : 0,
    completed: completed,
  );
}

/// Story 3.1 Subtask 5.1. `StatsService`'s cache-hit/cache-miss mechanics
/// (AD-8) and Daily-goal streak correctness — the only streak correctness
/// this story's suite is responsible for (Story 3.3 owns non-Daily
/// correctness; see the story's Dev Notes testing standard).
void main() {
  late InMemoryStore store;
  late StatsService statsService;

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
    store = InMemoryStore()
      ..goals.add(goal)
      ..versions.add(version);
    statsService = StatsService(
      goalRepository: InMemoryGoalRepository(store),
      goalVersionRepository: InMemoryGoalVersionRepository(store),
      goalLogRepository: InMemoryGoalLogRepository(store),
      blackoutDateRepository: InMemoryBlackoutDateRepository(store),
      cheatDayRepository: InMemoryCheatDayRepository(store),
      statusCacheRepository: InMemoryStatusCacheRepository(store),
    );
  });

  test(
    'a cache hit returns the cached value without calling evaluate() (AD-8)',
    () async {
      // No GoalLog exists for this date — a fresh evaluate() would return
      // Pending, never Cheat. Getting Cheat back proves the cached row won.
      store.statusCache['${goal.id}|2026-08-05'] = DayStatus(
        goalId: goal.id,
        date: '2026-08-05',
        status: DayStatusValue.cheat,
      );

      final status = await statsService.statusFor(
        goal: goal,
        date: DateTime(2026, 8, 5),
        today: DateTime(2026, 8, 5),
      );

      expect(status.status, DayStatusValue.cheat);
    },
  );

  test(
    'a cache miss falls back to evaluate() and returns a correct value with '
    'no thrown error (AD-8 consequence)',
    () async {
      store.logs.add(
        GoalLog(
          id: 'log-1',
          goalId: goal.id,
          date: '2026-08-06',
          timestamp: '2026-08-06T09:00:00',
          value: 1,
          completed: true,
        ),
      );

      final status = await statsService.statusFor(
        goal: goal,
        date: DateTime(2026, 8, 6),
        today: DateTime(2026, 8, 6),
      );

      expect(status.status, DayStatusValue.success);
    },
  );

  test(
    'todayProgress includes only currently-active goals eligible today, '
    'excluding archived goals (AC 1)',
    () async {
      const archivedGoal = Goal(
        id: 'goal-archived',
        name: 'Old habit',
        archived: true,
        startDate: '2026-08-01',
      );
      final archivedVersion = GoalVersion(
        id: 'version-archived',
        goalId: archivedGoal.id,
        versionStartDate: '2026-08-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );
      store.goals.add(archivedGoal);
      store.versions.add(archivedVersion);

      final progress = await statsService.todayProgress(
        DateTime(2026, 8, 10),
      );

      expect(progress.map((g) => g.goal.id).toList(), [goal.id]);
    },
  );

  test(
    'currentStreak counts consecutive successful days ending yesterday for '
    'a Daily goal, without an unresolved today zeroing it out',
    () async {
      const streakGoal = Goal(
        id: 'goal-streak',
        name: 'Stretch',
        archived: false,
        startDate: '2000-01-01',
      );
      final streakVersion = GoalVersion(
        id: 'version-streak',
        goalId: streakGoal.id,
        versionStartDate: '2000-01-01',
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );
      store.goals.add(streakGoal);
      store.versions.add(streakVersion);

      final today = DateTime.now();
      final todayDateOnly = DateTime(today.year, today.month, today.day);
      for (var daysAgo = 1; daysAgo <= 3; daysAgo++) {
        final dateStr = formatDateOnly(
          todayDateOnly.subtract(Duration(days: daysAgo)),
        );
        store.logs.add(
          GoalLog(
            id: 'log-$dateStr',
            goalId: streakGoal.id,
            date: dateStr,
            timestamp: '${dateStr}T09:00:00',
            value: 1,
            completed: true,
          ),
        );
      }
      // No log for "today" — deliberately unresolved.

      final streak = await statsService.currentStreak(streakGoal.id);

      expect(streak, 3);
    },
  );

  test(
    "Story 3.2 Subtask 6.4: goalStats' currentStreak field is the exact "
    "same currentStreak() value Dashboard's provider calls — never a "
    'second computation (AD-8)',
    () async {
      const goalId = 'goal-stats-current-streak';
      final goalStart = _today().subtract(const Duration(days: 5));
      final fullGoal = Goal(
        id: goalId,
        name: 'Stretch',
        archived: false,
        startDate: formatDateOnly(goalStart),
      );
      final statsVersion = GoalVersion(
        id: 'version-stats-current-streak',
        goalId: goalId,
        versionStartDate: formatDateOnly(goalStart),
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );
      store.goals.add(fullGoal);
      store.versions.add(statsVersion);
      for (var daysAgo = 1; daysAgo <= 3; daysAgo++) {
        final dateStr = formatDateOnly(
          _today().subtract(Duration(days: daysAgo)),
        );
        store.logs.add(
          GoalLog(
            id: 'log-stats-$dateStr',
            goalId: goalId,
            date: dateStr,
            timestamp: '${dateStr}T09:00:00',
            value: 1,
            completed: true,
          ),
        );
      }

      final direct = await statsService.currentStreak(goalId);
      final bundled = await statsService.goalStats(goalId);

      expect(direct, 3);
      expect(bundled.currentStreak, direct);
    },
  );

  test(
    'goalStats.longestStreak finds the longest run of consecutive success/'
    "cheat days across the goal's whole history, even when it isn't the "
    'currently active streak, and completionPercentage is successDays / '
    'resolvedDays (Subtask 1.1)',
    () async {
      const goalId = 'goal-longest-streak';
      final goalStart = _today().subtract(const Duration(days: 10));
      final fullGoal = Goal(
        id: goalId,
        name: 'Meditate',
        archived: false,
        startDate: formatDateOnly(goalStart),
      );
      final longestVersion = GoalVersion(
        id: 'version-longest-streak',
        goalId: goalId,
        versionStartDate: formatDateOnly(goalStart),
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );
      store.goals.add(fullGoal);
      store.versions.add(longestVersion);

      // A 5-day run (daysAgo 10..6), then 2 explicit fails (daysAgo 5, 4),
      // then a shorter 2-day run (daysAgo 3..2), then one more explicit
      // fail (daysAgo 1, "yesterday"), then an unlogged/unresolved
      // "today" (excluded — an unlogged Boolean-Daily day stays Pending
      // forever, per `evaluate()`; only an explicit `completed: false` log
      // ever produces a real Fail). So the longest run (5) is not the
      // current one (0, since the last resolved day, yesterday, is a
      // Fail).
      void log(int daysAgo, {required bool completed}) {
        final dateStr = formatDateOnly(
          _today().subtract(Duration(days: daysAgo)),
        );
        store.logs.add(
          GoalLog(
            id: 'log-longest-$dateStr',
            goalId: goalId,
            date: dateStr,
            timestamp: '${dateStr}T09:00:00',
            value: completed ? 1 : 0,
            completed: completed,
          ),
        );
      }

      for (final daysAgo in [10, 9, 8, 7, 6]) {
        log(daysAgo, completed: true);
      }
      log(5, completed: false);
      log(4, completed: false);
      log(3, completed: true);
      log(2, completed: true);
      log(1, completed: false);

      final stats = await statsService.goalStats(goalId);

      expect(stats.longestStreak, 5);
      expect(stats.currentStreak, 0);
      // Resolved days: 5 + 2 + 2 + 1 = 10 total, 7 of which succeeded.
      expect(stats.completionPercentage, closeTo(70.0, 0.001));
    },
  );

  test(
    'historicalStatuses returns one DayStatus per day from Goal.startDate '
    "through today inclusive, cache-first with evaluate() fallback for "
    'uncached dates (Subtask 2.1)',
    () async {
      const goalId = 'goal-historical';
      final goalStart = _today().subtract(const Duration(days: 4));
      final fullGoal = Goal(
        id: goalId,
        name: 'Journal',
        archived: false,
        startDate: formatDateOnly(goalStart),
      );
      final historicalVersion = GoalVersion(
        id: 'version-historical',
        goalId: goalId,
        versionStartDate: formatDateOnly(goalStart),
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
      );
      store.goals.add(fullGoal);
      store.versions.add(historicalVersion);

      // The oldest day is pre-populated in the cache with a value
      // evaluate() would never produce on its own (no log exists for it) —
      // proving the cache wins for that date.
      final startDateStr = formatDateOnly(goalStart);
      store.statusCache['$goalId|$startDateStr'] = DayStatus(
        goalId: goalId,
        date: startDateStr,
        status: DayStatusValue.cheat,
      );
      // The next day has a real completed log, resolved via the
      // evaluate() fallback (no cache row for it).
      final secondDateStr = formatDateOnly(
        goalStart.add(const Duration(days: 1)),
      );
      store.logs.add(
        GoalLog(
          id: 'log-historical-$secondDateStr',
          goalId: goalId,
          date: secondDateStr,
          timestamp: '${secondDateStr}T09:00:00',
          value: 1,
          completed: true,
        ),
      );

      final statuses = await statsService.historicalStatuses(goalId);

      expect(statuses, hasLength(5));
      expect(statuses.first.date, startDateStr);
      expect(statuses.first.status, DayStatusValue.cheat);
      expect(statuses[1].date, secondDateStr);
      expect(statuses[1].status, DayStatusValue.success);
      expect(statuses.last.date, formatDateOnly(_today()));
    },
  );

  group('Story 3.3: rule-aware streaks (FR-29)', () {
    GoalVersion weeklyVersion({
      required String goalId,
      required String versionStartDate,
      bool isPaused = false,
    }) {
      return GoalVersion(
        id: 'version-weekly-$goalId-$versionStartDate',
        goalId: goalId,
        versionStartDate: versionStartDate,
        evaluationPeriod: EvaluationPeriod.weekly,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.atLeast,
        targetValue: '3',
        trackingType: TrackingType.boolean,
        isPaused: isPaused,
      );
    }

    test(
      'AC 1/Subtask 4.1: a Weekly "3x/week" goal with 4 consecutive '
      'successful weeks then 1 failed week (failed week most recent) '
      'reports current streak 0 and longest streak 4',
      () async {
        const goalId = 'goal-weekly-fail-last';
        final currentMonday = _mondayOnOrBefore(_today());
        final goalStart = currentMonday.subtract(const Duration(days: 35));
        store.goals.add(
          Goal(
            id: goalId,
            name: 'Gym',
            archived: false,
            startDate: formatDateOnly(goalStart),
          ),
        );
        store.versions.addAll([
          weeklyVersion(
            goalId: goalId,
            versionStartDate: formatDateOnly(goalStart),
          ),
          // Pauses the still-in-progress current week so its outcome is
          // deterministic regardless of which weekday the suite happens to
          // run on (an unlogged in-progress period is only Pending while
          // enough eligible days remain to still reach target — near a
          // period's own end it can already be a certain Fail instead).
          weeklyVersion(
            goalId: goalId,
            versionStartDate: formatDateOnly(currentMonday),
            isPaused: true,
          ),
        ]);

        // 4 consecutive successful weeks (Mon/Tue/Wed logged done), then 1
        // failed week (nothing logged — certain failure by week's end,
        // which is always in the past here, so always deterministic).
        for (final weeksAgo in [5, 4, 3, 2]) {
          final weekMonday = currentMonday.subtract(
            Duration(days: 7 * weeksAgo),
          );
          for (var offset = 0; offset < 3; offset++) {
            final date = formatDateOnly(
              weekMonday.add(Duration(days: offset)),
            );
            store.logs.add(_completedLog(goalId, date));
          }
        }
        // weeksAgo = 1's week is the most recent fully-elapsed week, left
        // entirely unlogged (certain failure by week's end).

        final walk = await statsService.goalStats(goalId);

        expect(walk.currentStreak, 0);
        expect(walk.longestStreak, 4);
      },
    );

    test(
      'AC 1/Subtask 4.1: the same fixture with the failed week NOT most '
      'recent — current streak continues correctly through the trailing '
      'successful run',
      () async {
        const goalId = 'goal-weekly-fail-first';
        final currentMonday = _mondayOnOrBefore(_today());
        final goalStart = currentMonday.subtract(const Duration(days: 35));
        store.goals.add(
          Goal(
            id: goalId,
            name: 'Gym',
            archived: false,
            startDate: formatDateOnly(goalStart),
          ),
        );
        store.versions.addAll([
          weeklyVersion(
            goalId: goalId,
            versionStartDate: formatDateOnly(goalStart),
          ),
          // See the sibling test above: pauses the current in-progress
          // week for a deterministic result regardless of test-run day.
          weeklyVersion(
            goalId: goalId,
            versionStartDate: formatDateOnly(currentMonday),
            isPaused: true,
          ),
        ]);

        // weeksAgo=5 (oldest fully-elapsed week): failed (unlogged).
        // weeksAgo=4,3,2,1: 4 consecutive successful weeks trailing right
        // up to the (now-paused, excluded) current week.
        for (final weeksAgo in [4, 3, 2, 1]) {
          final weekMonday = currentMonday.subtract(
            Duration(days: 7 * weeksAgo),
          );
          for (var offset = 0; offset < 3; offset++) {
            final date = formatDateOnly(
              weekMonday.add(Duration(days: offset)),
            );
            store.logs.add(_completedLog(goalId, date));
          }
        }

        final walk = await statsService.goalStats(goalId);

        expect(walk.currentStreak, 4);
        expect(walk.longestStreak, 4);
      },
    );

    test(
      'Subtask 4.3: a Rolling Window goal never returns a numeric streak — '
      'currentStreak() and goalStats() both report "not applicable" (null)',
      () async {
        const goalId = 'goal-rolling-window';
        final goalStart = _today().subtract(const Duration(days: 20));
        store.goals.add(
          Goal(
            id: goalId,
            name: 'Workout 10x in any 14 days',
            archived: false,
            startDate: formatDateOnly(goalStart),
          ),
        );
        store.versions.add(
          GoalVersion(
            id: 'version-rolling',
            goalId: goalId,
            versionStartDate: formatDateOnly(goalStart),
            evaluationPeriod: EvaluationPeriod.rollingWindow(14),
            eligibleDaysRule: EligibleDaysRule.everyDay,
            targetComparison: TargetComparison.atLeast,
            targetValue: '10',
            trackingType: TrackingType.counter,
          ),
        );
        // Plenty of logged progress — proves a null result isn't just an
        // artifact of an otherwise-empty goal.
        for (var daysAgo = 1; daysAgo <= 10; daysAgo++) {
          final date = formatDateOnly(
            _today().subtract(Duration(days: daysAgo)),
          );
          store.logs.add(
            GoalLog(
              id: 'log-rolling-$date',
              goalId: goalId,
              date: date,
              timestamp: '${date}T09:00:00',
              value: 1,
              completed: true,
            ),
          );
        }

        final direct = await statsService.currentStreak(goalId);
        final bundled = await statsService.goalStats(goalId);

        expect(direct, isNull);
        expect(bundled.currentStreak, isNull);
        expect(bundled.longestStreak, isNull);
      },
    );

    test(
      'Subtask 4.4: a goal edited mid-history from Weekly to Monthly does '
      'not concatenate the two runs into one streak — continuity breaks at '
      'the Evaluation Period type change',
      () async {
        const goalId = 'goal-weekly-to-monthly';
        final today = _today();
        final thisMonthStart = DateTime(today.year, today.month, 1);
        final prevMonthStart = DateTime(today.year, today.month - 1, 1);
        final currentMonday = _mondayOnOrBefore(
          prevMonthStart.subtract(const Duration(days: 1)),
        );
        // 3 fully-elapsed successful weeks under the original Weekly rule,
        // ending the week before the Version switch to Monthly.
        final goalStart = currentMonday.subtract(const Duration(days: 21));

        store.goals.add(
          Goal(
            id: goalId,
            name: 'Read',
            archived: false,
            startDate: formatDateOnly(goalStart),
          ),
        );
        store.versions.add(
          weeklyVersion(
            goalId: goalId,
            versionStartDate: formatDateOnly(goalStart),
          ),
        );
        store.versions.add(
          GoalVersion(
            id: 'version-monthly-$goalId',
            goalId: goalId,
            versionStartDate: formatDateOnly(prevMonthStart),
            evaluationPeriod: EvaluationPeriod.monthly,
            eligibleDaysRule: EligibleDaysRule.everyDay,
            targetComparison: TargetComparison.atLeast,
            targetValue: '3',
            trackingType: TrackingType.boolean,
          ),
        );
        // Pauses the still-in-progress current month so its outcome is
        // deterministic regardless of which day of the month the suite
        // happens to run on (same rationale as the weekly tests above).
        store.versions.add(
          GoalVersion(
            id: 'version-monthly-paused-$goalId',
            goalId: goalId,
            versionStartDate: formatDateOnly(thisMonthStart),
            evaluationPeriod: EvaluationPeriod.monthly,
            eligibleDaysRule: EligibleDaysRule.everyDay,
            targetComparison: TargetComparison.atLeast,
            targetValue: '3',
            trackingType: TrackingType.boolean,
            isPaused: true,
          ),
        );

        // 3 consecutive successful weeks (Weekly rule).
        for (final weeksAgo in [3, 2, 1]) {
          final weekMonday = currentMonday.subtract(
            Duration(days: 7 * weeksAgo),
          );
          for (var offset = 0; offset < 3; offset++) {
            final date = formatDateOnly(
              weekMonday.add(Duration(days: offset)),
            );
            store.logs.add(_completedLog(goalId, date));
          }
        }
        // 1 successful month (Monthly rule) — the whole previous month,
        // fully elapsed, logged done on its first 3 days (reaches "at
        // least 3" immediately, regardless of remaining days).
        for (var offset = 0; offset < 3; offset++) {
          final date = formatDateOnly(
            prevMonthStart.add(Duration(days: offset)),
          );
          store.logs.add(_completedLog(goalId, date));
        }
        // This month (Monthly rule, in progress) is left unresolved and
        // excluded, exactly like an unresolved "today" for a Daily goal.
        expect(thisMonthStart.isAfter(prevMonthStart), isTrue);

        final walk = await statsService.goalStats(goalId);

        // NOT 3 (weeks) + 1 (month) = 4 concatenated — the type change is a
        // hard break, so the longest run is the taller of the two
        // independent segments (3 weeks), and the current run reflects
        // only the still-active Monthly segment (1 month).
        expect(walk.longestStreak, 3);
        expect(walk.currentStreak, 1);
      },
    );

    test(
      'Subtask 4.5: a Paused segment spanning a whole period produces no '
      'evaluated period to break or extend the streak — pausing is not '
      'itself a failed period',
      () async {
        const goalId = 'goal-paused-week';
        final currentMonday = _mondayOnOrBefore(_today());
        final goalStart = currentMonday.subtract(const Duration(days: 28));

        store.goals.add(
          Goal(
            id: goalId,
            name: 'Read',
            archived: false,
            startDate: formatDateOnly(goalStart),
          ),
        );
        // Weeks 3 and 1 (weeks-ago) successful; week 2 fully paused via a
        // same-rule, isPaused Version covering exactly that week, then
        // resumed the following Monday.
        final week2Monday = currentMonday.subtract(const Duration(days: 14));
        final week1Monday = currentMonday.subtract(const Duration(days: 7));
        store.versions.addAll([
          weeklyVersion(
            goalId: goalId,
            versionStartDate: formatDateOnly(goalStart),
          ),
          weeklyVersion(
            goalId: goalId,
            versionStartDate: formatDateOnly(week2Monday),
            isPaused: true,
          ),
          weeklyVersion(
            goalId: goalId,
            versionStartDate: formatDateOnly(week1Monday),
          ),
          // Pauses the still-in-progress current week for a deterministic
          // result regardless of test-run day (see the earlier weekly
          // tests' rationale).
          weeklyVersion(
            goalId: goalId,
            versionStartDate: formatDateOnly(currentMonday),
            isPaused: true,
          ),
        ]);

        for (final weekMonday in [
          currentMonday.subtract(const Duration(days: 21)), // weeksAgo 3
          week1Monday, // weeksAgo 1
        ]) {
          for (var offset = 0; offset < 3; offset++) {
            final date = formatDateOnly(
              weekMonday.add(Duration(days: offset)),
            );
            store.logs.add(_completedLog(goalId, date));
          }
        }
        // Week 2 (fully paused): deliberately no logs at all — if pausing
        // were miscounted as a failed period, this would zero the streak.

        final walk = await statsService.goalStats(goalId);

        // The paused week is skipped, not counted as a break: the 2
        // successful weeks (weeksAgo 3 and 1) chain into one streak of 2.
        expect(walk.currentStreak, 2);
        expect(walk.longestStreak, 2);
      },
    );
  });

  group('Story 3.4: Full Statistics Panel (FR-28)', () {
    test(
      'Subtask 4.1: successful/failed period counts on a Daily goal with a '
      'mix of Success/Fail/Pending days — Pending (today, unlogged) is '
      'excluded from both counts until it resolves',
      () async {
        const goalId = 'goal-period-counts';
        final goalStart = _today().subtract(const Duration(days: 5));
        store.goals.add(
          Goal(
            id: goalId,
            name: 'Stretch',
            archived: false,
            startDate: formatDateOnly(goalStart),
          ),
        );
        store.versions.add(
          GoalVersion(
            id: 'version-period-counts',
            goalId: goalId,
            versionStartDate: formatDateOnly(goalStart),
            evaluationPeriod: EvaluationPeriod.daily,
            eligibleDaysRule: EligibleDaysRule.everyDay,
            targetComparison: TargetComparison.exactly,
            targetValue: '1',
            trackingType: TrackingType.boolean,
          ),
        );

        // 3 successes (daysAgo 5, 4, 3), 2 explicit fails (daysAgo 2, 1).
        // "Today" (daysAgo 0) is deliberately left unlogged — Pending.
        for (final daysAgo in [5, 4, 3]) {
          store.logs.add(_completedLog(goalId, formatDateOnly(
            _today().subtract(Duration(days: daysAgo)),
          )));
        }
        for (final daysAgo in [2, 1]) {
          final dateStr = formatDateOnly(
            _today().subtract(Duration(days: daysAgo)),
          );
          store.logs.add(
            GoalLog(
              id: 'log-fail-$dateStr',
              goalId: goalId,
              date: dateStr,
              timestamp: '${dateStr}T09:00:00',
              value: 0,
              completed: false,
            ),
          );
        }

        final stats = await statsService.goalStats(goalId);

        expect(stats.successfulPeriods, 3);
        expect(stats.failedPeriods, 2);
      },
    );

    test(
      'Subtask 4.2: completion percentage excludes a Paused week from both '
      'the numerator and the denominator, not just the numerator',
      () async {
        const goalId = 'goal-paused-completion';
        final currentMonday = _mondayOnOrBefore(_today());
        // The goal starts exactly at the successful week's Monday, so
        // there is only one non-paused, fully-elapsed week in its history
        // (plus the current, fully-paused week) — no extra unlogged week
        // to muddy the expected counts.
        final successfulWeekMonday = currentMonday.subtract(
          const Duration(days: 7),
        );
        final goalStart = successfulWeekMonday;
        final pausedWeekMonday = currentMonday;

        store.goals.add(
          Goal(
            id: goalId,
            name: 'Gym',
            archived: false,
            startDate: formatDateOnly(goalStart),
          ),
        );
        store.versions.addAll([
          GoalVersion(
            id: 'version-paused-completion',
            goalId: goalId,
            versionStartDate: formatDateOnly(goalStart),
            evaluationPeriod: EvaluationPeriod.weekly,
            eligibleDaysRule: EligibleDaysRule.everyDay,
            targetComparison: TargetComparison.atLeast,
            targetValue: '3',
            trackingType: TrackingType.boolean,
          ),
          // Pauses the current week only (fully paused, no other rule
          // change) — if a fully-Paused period were miscounted as a Fail
          // (via evaluate()'s zero-eligible-days rule), the denominator
          // would include it and completion % would drop to 50%.
          GoalVersion(
            id: 'version-paused-completion-pause',
            goalId: goalId,
            versionStartDate: formatDateOnly(pausedWeekMonday),
            evaluationPeriod: EvaluationPeriod.weekly,
            eligibleDaysRule: EligibleDaysRule.everyDay,
            targetComparison: TargetComparison.atLeast,
            targetValue: '3',
            trackingType: TrackingType.boolean,
            isPaused: true,
          ),
        ]);

        for (var offset = 0; offset < 3; offset++) {
          store.logs.add(
            _completedLog(
              goalId,
              formatDateOnly(successfulWeekMonday.add(Duration(days: offset))),
            ),
          );
        }
        // The paused week is deliberately left unlogged.

        final stats = await statsService.goalStats(goalId);

        expect(stats.successfulPeriods, 1);
        expect(stats.failedPeriods, 0);
        expect(stats.completionPercentage, closeTo(100.0, 0.001));
      },
    );

    test(
      'Subtask 4.1: Cheat Day count reflects every CheatDay record for the '
      'goal',
      () async {
        const goalId = 'goal-cheat-days';
        final goalStart = _today().subtract(const Duration(days: 10));
        store.goals.add(
          Goal(
            id: goalId,
            name: 'Read',
            archived: false,
            startDate: formatDateOnly(goalStart),
          ),
        );
        store.versions.add(
          GoalVersion(
            id: 'version-cheat-days',
            goalId: goalId,
            versionStartDate: formatDateOnly(goalStart),
            evaluationPeriod: EvaluationPeriod.daily,
            eligibleDaysRule: EligibleDaysRule.everyDay,
            targetComparison: TargetComparison.exactly,
            targetValue: '1',
            trackingType: TrackingType.boolean,
            cheatDayQuota: 5,
          ),
        );
        store.cheatDays.addAll([
          CheatDay(
            id: 'cheat-1',
            goalId: goalId,
            date: formatDateOnly(_today().subtract(const Duration(days: 5))),
          ),
          CheatDay(
            id: 'cheat-2',
            goalId: goalId,
            date: formatDateOnly(_today().subtract(const Duration(days: 3))),
          ),
        ]);

        final stats = await statsService.goalStats(goalId);

        expect(stats.cheatDayCount, 2);
      },
    );

    test(
      'Subtask 4.1: average/total value on a Counter-goal fixture sum/'
      "average the goal's logged values, excluding a Paused range",
      () async {
        const goalId = 'goal-counter-values';
        final goalStart = _today().subtract(const Duration(days: 6));
        store.goals.add(
          Goal(
            id: goalId,
            name: 'Push-ups',
            archived: false,
            startDate: formatDateOnly(goalStart),
          ),
        );
        store.versions.addAll([
          GoalVersion(
            id: 'version-counter-values',
            goalId: goalId,
            versionStartDate: formatDateOnly(goalStart),
            evaluationPeriod: EvaluationPeriod.daily,
            eligibleDaysRule: EligibleDaysRule.everyDay,
            targetComparison: TargetComparison.atLeast,
            targetValue: '10',
            trackingType: TrackingType.counter,
          ),
          // Pauses the most recent 2 days — their logged values (if any)
          // must not count toward the average/total.
          GoalVersion(
            id: 'version-counter-values-pause',
            goalId: goalId,
            versionStartDate: formatDateOnly(
              _today().subtract(const Duration(days: 1)),
            ),
            evaluationPeriod: EvaluationPeriod.daily,
            eligibleDaysRule: EligibleDaysRule.everyDay,
            targetComparison: TargetComparison.atLeast,
            targetValue: '10',
            trackingType: TrackingType.counter,
            isPaused: true,
          ),
        ]);

        // 3 non-paused logged days: 5, 10, 15 -> total 30, average 10.
        final values = {6: 5.0, 5: 10.0, 4: 15.0};
        values.forEach((daysAgo, value) {
          final dateStr = formatDateOnly(
            _today().subtract(Duration(days: daysAgo)),
          );
          store.logs.add(
            GoalLog(
              id: 'log-counter-$dateStr',
              goalId: goalId,
              date: dateStr,
              timestamp: '${dateStr}T09:00:00',
              value: value,
              completed: true,
            ),
          );
        });
        // One more log falls inside the paused range — excluded.
        final pausedDateStr = formatDateOnly(
          _today().subtract(const Duration(days: 1)),
        );
        store.logs.add(
          GoalLog(
            id: 'log-counter-paused',
            goalId: goalId,
            date: pausedDateStr,
            timestamp: '${pausedDateStr}T09:00:00',
            value: 999,
            completed: true,
          ),
        );

        final stats = await statsService.goalStats(goalId);

        expect(stats.totalValue, closeTo(30.0, 0.001));
        expect(stats.averageValue, closeTo(10.0, 0.001));
      },
    );

    test(
      'Subtask 4.3: a Boolean goal reports "not applicable" (null) '
      'average/total value rather than a fabricated 0',
      () async {
        final stats = await statsService.goalStats(goal.id);

        expect(stats.averageValue, isNull);
        expect(stats.totalValue, isNull);
      },
    );
  });
}
