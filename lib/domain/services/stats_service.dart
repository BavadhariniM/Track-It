import '../entities/day_status.dart';
import '../entities/goal.dart';
import '../entities/goal_lifecycle_status.dart';
import '../entities/goal_version.dart';
import '../entities/rule_values.dart';
import '../evaluator/date_format.dart';
import '../evaluator/evaluate.dart';
import '../evaluator/period_boundary.dart';
import 'blackout_date_repository.dart';
import 'cheat_day_repository.dart';
import 'goal_log_repository.dart';
import 'goal_repository.dart';
import 'goal_version_repository.dart';
import 'paused_range_helper.dart';
import 'status_cache_repository.dart';

/// One pass over a goal's Evaluation-Period history (Story 3.3 Subtask
/// 2.1, extended by Story 3.4 Subtask 1.3): the count of consecutive
/// successful periods ending at the most recently *resolved* period
/// ([current]), the longest such run anywhere in the goal's history
/// ([longest]), and the total count of successful ([successCount]) and
/// failed ([failCount]) resolved periods across the whole walk — one pass
/// producing every period-based rollup number, never divergent walks
/// (AD-8).
typedef _StreakWalkResult = ({
  int current,
  int longest,
  int successCount,
  int failCount,
});

/// One [Goal] paired with its resolved [DayStatus] for whatever date a
/// [StatsService] method was asked about — the shape every Dashboard rollup
/// method below returns, since a goal-row needs both the goal's display
/// fields (name) and its status/progress fields.
class GoalStatus {
  const GoalStatus({required this.goal, required this.dayStatus});

  final Goal goal;
  final DayStatus dayStatus;
}

/// Goal Detail's (Story 3.2 AC 1) bundled numeric stats for one goal —
/// current streak, longest streak, and completion percentage together, so
/// callers never assemble the three from separate calls (AD-8: a single
/// computer for every rollup number).
class GoalStats {
  const GoalStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.completionPercentage,
    required this.successfulPeriods,
    required this.failedPeriods,
    required this.cheatDayCount,
    required this.averageValue,
    required this.totalValue,
  });

  /// `null` for a Rolling Window goal (FR-29 consequence): no Streak stat
  /// applies to a sliding window with no discrete period cycle. Callers
  /// must branch on this and render current pace/status instead — never a
  /// fabricated 0 (Story 3.3 Subtask 1.3).
  final int? currentStreak;
  final int? longestStreak;

  /// 0-100. `0` when the goal has no resolved (non-empty, non-pending) day
  /// yet. For every non-Rolling-Window goal this is `successfulPeriods /
  /// (successfulPeriods + failedPeriods)`, so it automatically inherits the
  /// same Paused-period exclusion (Story 3.4 AC 2) as those two counts —
  /// never a second, divergent percentage computation. Rolling Window goals
  /// have no discrete period to count, so this falls back to a day-by-day
  /// resolution instead (still excluding Paused days).
  final double completionPercentage;

  /// Count of resolved Evaluation Periods whose outcome was Success/Cheat,
  /// and Fail, respectively (Story 3.4 AC 1) — from the same single period
  /// walk [currentStreak]/[longestStreak] come from (AD-8). `null` for a
  /// Rolling Window goal, matching the streak fields' "not applicable"
  /// convention (Story 3.3 Subtask 1.3): a sliding window has no discrete
  /// period to count as successful or failed either.
  final int? successfulPeriods;
  final int? failedPeriods;

  /// Total `CheatDay` records logged against the goal (Story 3.4 Subtask
  /// 1.1).
  final int cheatDayCount;

  /// Average/total of `GoalLog.value` across the goal's history, excluding
  /// any date covered by a Paused `GoalVersion` segment (Story 3.4 Subtask
  /// 1.4's same exclusion as [completionPercentage]). `null` when the
  /// goal's current rules are not a Counter Tracking Type — Boolean goals
  /// have no numeric value to average, and callers must not render a
  /// fabricated 0 for them (Story 3.4 Subtask 4.3).
  final double? averageValue;
  final double? totalValue;
}

/// The sole streak/rollup computer for the entire app (AD-8), starting with
/// this story. Every method reads the `status_cache` table
/// ([StatusCacheRepository]) first; a cache miss for a given goal/date falls
/// back to calling the domain's single `evaluate()` entry point (AD-4)
/// directly for that one date — never a second evaluation implementation
/// (AC 5). Callers (Dashboard, Story 3.2's Goal Detail) never call
/// `evaluate()` themselves; they only ever call through here.
///
/// [currentStreak]'s calling contract (goalId in, streak count out) is
/// permanent — Story 3.3 finished the implementation behind this same
/// signature: rule-aware for every non-Rolling-Window Evaluation Period
/// (FR-29), returning `null` for Rolling Window goals (no Streak stat
/// applies, AC 3).
class StatsService {
  StatsService({
    required GoalRepository goalRepository,
    required GoalVersionRepository goalVersionRepository,
    required GoalLogRepository goalLogRepository,
    required BlackoutDateRepository blackoutDateRepository,
    required CheatDayRepository cheatDayRepository,
    required StatusCacheRepository statusCacheRepository,
    WeekStart weekStart = WeekStart.monday,
  }) : _goalRepository = goalRepository,
       _goalVersionRepository = goalVersionRepository,
       _goalLogRepository = goalLogRepository,
       _blackoutDateRepository = blackoutDateRepository,
       _cheatDayRepository = cheatDayRepository,
       _statusCacheRepository = statusCacheRepository,
       _weekStart = weekStart;

  final GoalRepository _goalRepository;
  final GoalVersionRepository _goalVersionRepository;
  final GoalLogRepository _goalLogRepository;
  final BlackoutDateRepository _blackoutDateRepository;
  final CheatDayRepository _cheatDayRepository;
  final StatusCacheRepository _statusCacheRepository;
  final WeekStart _weekStart;

  /// [goal]'s status on [date]: the cached row if one exists, otherwise a
  /// fresh `evaluate()` call (AD-8 consequence — no error, no data loss on a
  /// cache miss). [today] is the real wall-clock "as of" date (mirrors
  /// `evaluate()`'s own `today`/`date` distinction) — required, not
  /// defaulted, because every caller here genuinely has access to the real
  /// system clock, unlike `evaluate()`'s unit tests; a caller evaluating a
  /// past [date] must not silently let `today` collapse to `date` again,
  /// which is exactly the bug that left Daily/period goals Pending forever
  /// on elapsed days throughout this cache-backed surface.
  Future<DayStatus> statusFor({
    required Goal goal,
    required DateTime date,
    required DateTime today,
  }) async {
    final dateStr = formatDateOnly(date);
    final cached = await _statusCacheRepository.getStatus(goal.id, dateStr);
    if (cached != null) return cached;
    return _evaluateLive(goal, date, today);
  }

  /// Every currently-active Goal eligible on [today] (AC 1) — a Goal whose
  /// `evaluate()`/cached status for [today] is anything other than `empty`.
  /// Archived/Expired/Paused goals never appear here (lifecycle-gated below,
  /// same grouping `goals_list_screen.dart` already applies).
  Future<List<GoalStatus>> todayProgress(DateTime today) async {
    final todayStr = formatDateOnly(today);
    final result = <GoalStatus>[];
    for (final goal in await _activeGoals(todayStr)) {
      final status = await statusFor(goal: goal, date: today, today: today);
      if (status.status != DayStatusValue.empty) {
        result.add(GoalStatus(goal: goal, dayStatus: status));
      }
    }
    return result;
  }

  /// AC 2's "this week's ... in-progress goals" rollup: every active,
  /// currently-Pending Weekly-period Goal, evaluated for the week containing
  /// [today].
  Future<List<GoalStatus>> weekRollup(DateTime today) =>
      _periodRollup(today, EvaluationPeriod.weekly);

  /// AC 2's "this month's ... in-progress goals" rollup: every active,
  /// currently-Pending Monthly-period Goal, evaluated for the month
  /// containing [today].
  Future<List<GoalStatus>> monthRollup(DateTime today) =>
      _periodRollup(today, EvaluationPeriod.monthly);

  Future<List<GoalStatus>> _periodRollup(DateTime today, String period) async {
    final todayStr = formatDateOnly(today);
    final result = <GoalStatus>[];
    for (final goal in await _activeGoals(todayStr)) {
      final versions = await _goalVersionRepository.findAllForGoal(goal.id);
      final governing = _governingVersion(versions, todayStr);
      if (governing == null || governing.evaluationPeriod != period) continue;

      final status = await statusFor(goal: goal, date: today, today: today);
      if (status.status == DayStatusValue.pending) {
        result.add(GoalStatus(goal: goal, dayStatus: status));
      }
    }
    return result;
  }

  /// Consecutive successful Evaluation Periods ending at the most recently
  /// *resolved* period (FR-29) — `null` for a Rolling Window goal, which has
  /// no Streak stat at all (AC 3). Daily goals degenerate to counting
  /// consecutive successful days, since a Daily "period" is one day (Story
  /// 3.3 Subtask 1.2) — the exact same [_streakWalk] code path, not a
  /// separate branch.
  Future<int?> currentStreak(String goalId) async {
    final goal = await _goalRepository.findById(goalId);
    if (goal == null) return 0;
    final versions = await _goalVersionRepository.findAllForGoal(goal.id);
    final walk = await _streakWalk(goal, versions, _dateOnly(DateTime.now()));
    return walk?.current;
  }

  /// AC 1's bundled Goal Detail stats: [currentStreak] unchanged (its own
  /// contract is permanent, see class doc), plus the longest historical run
  /// of consecutive successful periods and the completion percentage across
  /// every resolved day from [Goal.startDate] through the most recently
  /// *resolved* day. [currentStreak]/[GoalStats.longestStreak] both come
  /// from the same single [_streakWalk] pass (Story 3.3 Subtask 2.1) — never
  /// two divergent walks; completion percentage keeps its own pre-existing
  /// day-by-day resolution (unaffected by period-aware streak counting).
  Future<GoalStats> goalStats(String goalId) async {
    final goal = await _goalRepository.findById(goalId);
    if (goal == null) {
      return const GoalStats(
        currentStreak: 0,
        longestStreak: 0,
        completionPercentage: 0,
        successfulPeriods: 0,
        failedPeriods: 0,
        cheatDayCount: 0,
        averageValue: null,
        totalValue: null,
      );
    }

    final versions = await _goalVersionRepository.findAllForGoal(goal.id);
    final today = _dateOnly(DateTime.now());
    final walk = await _streakWalk(goal, versions, today);

    final int? successfulPeriods;
    final int? failedPeriods;
    final double completionPercentage;
    if (walk != null) {
      successfulPeriods = walk.successCount;
      failedPeriods = walk.failCount;
      final totalResolved = walk.successCount + walk.failCount;
      completionPercentage = totalResolved == 0
          ? 0.0
          : (walk.successCount / totalResolved) * 100;
    } else {
      // Rolling Window (Story 3.3 AC 3): no discrete period to count as
      // successful/failed, so this stat is "not applicable" the same way
      // the streak fields are. Completion % still means something for a
      // Rolling Window goal, so it falls back to the day-by-day
      // resolution below rather than going unset (Story 3.4 Dev Notes).
      successfulPeriods = null;
      failedPeriods = null;
      completionPercentage = await _dayBasedCompletionPercentage(
        goal,
        versions,
        today,
      );
    }

    final sortedVersions = [...versions]
      ..sort((a, b) => a.versionStartDate.compareTo(b.versionStartDate));
    final isCounterGoal =
        sortedVersions.isNotEmpty &&
        sortedVersions.last.trackingType == TrackingType.counter;

    double? averageValue;
    double? totalValue;
    if (isCounterGoal) {
      final logs = await _goalLogRepository.findAllForGoal(goal.id);
      final eligibleValues = [
        for (final log in logs)
          if (!isPausedOn(versions, log.date)) log.value,
      ];
      final total = eligibleValues.fold<double>(0, (sum, v) => sum + v);
      totalValue = total;
      averageValue = eligibleValues.isEmpty
          ? 0.0
          : total / eligibleValues.length;
    }

    final cheatDays = await _cheatDayRepository.findAllForGoal(goal.id);

    return GoalStats(
      currentStreak: walk?.current,
      longestStreak: walk?.longest,
      completionPercentage: completionPercentage,
      successfulPeriods: successfulPeriods,
      failedPeriods: failedPeriods,
      cheatDayCount: cheatDays.length,
      averageValue: averageValue,
      totalValue: totalValue,
    );
  }

  /// The pre-period-aware completion-percentage computation (Story 3.2):
  /// walks day by day from [Goal.startDate] through the most recently
  /// resolved day, counting successful vs. resolved days directly.
  /// [goalStats] now only calls this for Rolling Window goals, which have
  /// no discrete period for [_streakWalk]'s success/fail counts to derive a
  /// percentage from — every other goal shape derives its percentage from
  /// those period counts instead (single source of truth, AD-8). Paused
  /// days are excluded from both sides of the ratio via [isPausedOn]
  /// (Story 3.4 Subtask 1.2), the same exclusion [averageValue]/[totalValue]
  /// apply to logged values.
  Future<double> _dayBasedCompletionPercentage(
    Goal goal,
    List<GoalVersion> versions,
    DateTime today,
  ) async {
    final goalStart = _dateOnly(DateTime.parse(goal.startDate));
    final lastResolvedDay = await _lastResolvedDay(goal, today);

    var resolvedDays = 0;
    var successDays = 0;
    var day = goalStart;
    while (!day.isAfter(lastResolvedDay)) {
      if (!isPausedOn(versions, formatDateOnly(day))) {
        final status = await statusFor(goal: goal, date: day, today: today);
        switch (status.status) {
          case DayStatusValue.success:
          case DayStatusValue.cheat:
            resolvedDays++;
            successDays++;
          case DayStatusValue.fail:
            resolvedDays++;
          case DayStatusValue.pending:
          case DayStatusValue.empty:
          // Not resolved / not eligible: excluded from the denominator.
        }
      }
      day = day.add(const Duration(days: 1));
    }

    return resolvedDays == 0 ? 0.0 : (successDays / resolvedDays) * 100;
  }

  /// Every day's [DayStatus] from [goalId]'s start date through today
  /// (inclusive) — the Goal Detail historical calendar's data source (Story
  /// 3.2 Subtask 2.1). Cache-first via [statusFor], falling back to
  /// `evaluate()` per uncached date; this is a historical review surface
  /// that can span a goal's entire lifetime, distinct from the live Day/
  /// Week/Month calendar, which never reads the cache (AD-7).
  Future<List<DayStatus>> historicalStatuses(String goalId) async {
    final goal = await _goalRepository.findById(goalId);
    if (goal == null) return [];

    final start = _dateOnly(DateTime.parse(goal.startDate));
    final today = _dateOnly(DateTime.now());
    final statuses = <DayStatus>[];
    var day = start;
    while (!day.isAfter(today)) {
      statuses.add(await statusFor(goal: goal, date: day, today: today));
      day = day.add(const Duration(days: 1));
    }
    return statuses;
  }

  /// Today, unless today's own status is still unresolved (Pending/Empty),
  /// in which case yesterday — the same "most recently resolved day" cursor
  /// rule [currentStreak] establishes, extracted here so [goalStats] walks
  /// the identical window rather than redefining it.
  Future<DateTime> _lastResolvedDay(Goal goal, DateTime today) async {
    var cursor = today;
    final todayStatus = await statusFor(goal: goal, date: cursor, today: today);
    if (todayStatus.status == DayStatusValue.pending ||
        todayStatus.status == DayStatusValue.empty) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return cursor;
  }

  /// FR-29's rule-aware streak walk (Story 3.3 Task 1/2): a single forward
  /// pass over [goal]'s Evaluation Periods from [Goal.startDate] through
  /// today, producing both the current streak (the run ending at the most
  /// recently *resolved* period) and the longest historical run, in one
  /// pass (Subtask 2.1) — never two divergent walks. Returns `null` when
  /// [goal] is currently a Rolling Window goal (AC 3): a sliding window has
  /// no discrete period cycle for a Streak stat to mean anything.
  ///
  /// Each period's pass/fail outcome is read from [statusFor] (cache-first,
  /// `evaluate()` fallback) — this method only counts consecutive Success
  /// outcomes `evaluate()` already produced, never re-deciding pass/fail
  /// itself (Dev Notes: "no new evaluation logic — only counting logic").
  /// Period boundaries reuse the exact same [periodBoundaryFor] calendar
  /// math `evaluate()` calls internally for the same query date, so the
  /// two never drift apart (AD-5's version-boundary period splitting).
  Future<_StreakWalkResult?> _streakWalk(
    Goal goal,
    List<GoalVersion> versions,
    DateTime today,
  ) async {
    if (versions.isEmpty) {
      return (current: 0, longest: 0, successCount: 0, failCount: 0);
    }
    final sorted = [...versions]
      ..sort((a, b) => a.versionStartDate.compareTo(b.versionStartDate));

    final goalStart = _dateOnly(DateTime.parse(goal.startDate));

    final currentGoverning =
        _governingVersion(sorted, formatDateOnly(today)) ?? sorted.last;
    if (EvaluationPeriod.isRollingWindow(currentGoverning.evaluationPeriod)) {
      return null;
    }

    var running = 0;
    var longest = 0;
    var successCount = 0;
    var failCount = 0;
    String? previousType;
    var cursor = goalStart;

    while (!cursor.isAfter(today)) {
      final cursorStr = formatDateOnly(cursor);
      final governing = _governingVersion(sorted, cursorStr);
      if (governing == null) {
        cursor = cursor.add(const Duration(days: 1));
        continue;
      }

      // A Rolling Window span has no discrete period to count as a
      // pass/fail streak unit (AC 3 consequence) — skip day by day without
      // affecting the run or the type-continuity tracking below, since
      // there is no comparable "period type" for a boundaryless window.
      if (EvaluationPeriod.isRollingWindow(governing.evaluationPeriod)) {
        cursor = cursor.add(const Duration(days: 1));
        continue;
      }

      final boundary = periodBoundaryFor(
        evaluationPeriod: governing.evaluationPeriod,
        date: cursor,
        goalStartDate: goalStart,
        weekStart: _weekStart,
      );
      // Clip the raw calendar boundary so it never crosses into a later
      // Version with a *different* Evaluation Period type — `evaluate()`
      // picks its period type from whichever Version governs the query
      // date, so querying past a type-changing boundary would silently ask
      // about the wrong period type entirely (Subtask 1.4).
      final periodEnd = _clipToTypeWindow(sorted, governing, boundary.end);
      final isCurrentPeriod = !periodEnd.isBefore(today);
      final queryDate = periodEnd.isAfter(today) ? today : periodEnd;

      // Subtask 1.4: a Version change that alters the Evaluation Period
      // *type* itself is a hard continuity break — "3 weeks" and "2
      // months" cannot concatenate into one count.
      if (previousType != null && previousType != governing.evaluationPeriod) {
        running = 0;
      }
      previousType = governing.evaluationPeriod;

      final periodStart = boundary.start.isBefore(goalStart)
          ? goalStart
          : boundary.start;
      final fullyPausedOrUngoverned = _isFullyPausedOrUngoverned(
        sorted,
        periodStart,
        queryDate,
      );

      if (!fullyPausedOrUngoverned) {
        final status = await statusFor(
          goal: goal,
          date: queryDate,
          today: today,
        );
        if (isCurrentPeriod && status.status == DayStatusValue.pending) {
          // Mirrors the Daily-goal rule: an unresolved current period is
          // excluded entirely, the same way an unresolved "today" steps
          // back to yesterday for [_lastResolvedDay].
        } else {
          switch (status.status) {
            case DayStatusValue.success:
            case DayStatusValue.cheat:
              running++;
              successCount++;
              if (running > longest) longest = running;
            case DayStatusValue.fail:
              running = 0;
              failCount++;
            case DayStatusValue.pending:
              // Story 3.4 Subtask 1.3: a Pending period is excluded from
              // both counts until it resolves — not reachable here for a
              // historical (non-current) period, since a fully-elapsed
              // period's `evaluate()` call always resolves to Success/Fail,
              // but guarded explicitly rather than assumed.
              running = 0;
            case DayStatusValue.empty:
            // Not reachable here (governing != null was already
            // confirmed above), kept for exhaustiveness only.
          }
        }
      }
      // A fully paused/ungoverned period (Subtask 4.5): a genuine non-event,
      // skipped without affecting the run — Evaluation Period *type*
      // continuity was already recorded above so a same-type pause never
      // breaks streak continuity either.

      if (periodEnd.isAfter(today)) break;
      cursor = periodEnd.add(const Duration(days: 1));
    }

    return (
      current: running,
      longest: longest,
      successCount: successCount,
      failCount: failCount,
    );
  }

  /// The latest date on/before [rawEnd] still governed by [governing]'s own
  /// Evaluation Period *type* — i.e. [rawEnd] clipped to the day before the
  /// next later Version whose `evaluationPeriod` differs from [governing]'s
  /// (a pause-only Version change is not a type change and does not clip).
  DateTime _clipToTypeWindow(
    List<GoalVersion> sortedVersions,
    GoalVersion governing,
    DateTime rawEnd,
  ) {
    final index = sortedVersions.indexOf(governing);
    for (var i = index + 1; i < sortedVersions.length; i++) {
      if (sortedVersions[i].evaluationPeriod != governing.evaluationPeriod) {
        final clippedEnd = DateTime.parse(
          sortedVersions[i].versionStartDate,
        ).subtract(const Duration(days: 1));
        return clippedEnd.isBefore(rawEnd) ? clippedEnd : rawEnd;
      }
    }
    return rawEnd;
  }

  /// Whether every calendar day in `[periodStart, periodEnd]` is either
  /// ungoverned (before any Version existed) or governed by a Paused
  /// Version — i.e. the period has zero non-paused eligible-day candidates
  /// purely because it was paused, the "Paused produces no Eligible Days"
  /// case this streak walk must treat as a skip (Subtask 4.5), not ask
  /// `evaluate()` about at all. `evaluate()`'s own zero-eligible-days rule
  /// (FR-5) returns Fail for *any* zero-eligible period, including a
  /// misconfigured rule with no eligible weekdays — this check is
  /// deliberately narrower (Pause/ungoverned only) so a genuine
  /// misconfiguration still surfaces as `evaluate()`'s real Fail, per this
  /// story's "no new evaluation logic" rule.
  bool _isFullyPausedOrUngoverned(
    List<GoalVersion> sortedVersions,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    for (
      var day = periodStart;
      !day.isAfter(periodEnd);
      day = day.add(const Duration(days: 1))
    ) {
      final governing = _governingVersion(sortedVersions, formatDateOnly(day));
      if (governing != null && !governing.isPaused) return false;
    }
    return true;
  }

  Future<DayStatus> _evaluateLive(Goal goal, DateTime date, DateTime today) async {
    final versions = await _goalVersionRepository.findAllForGoal(goal.id);
    final logs = await _goalLogRepository.findAllForGoal(goal.id);
    final blackoutDates = await _blackoutDateRepository.findAllForGoal(
      goal.id,
    );
    final cheatDays = await _cheatDayRepository.findAllForGoal(goal.id);
    return evaluate(
      goal: goal,
      versions: versions,
      logs: logs,
      blackoutDates: blackoutDates,
      cheatDays: cheatDays,
      date: date,
      today: today,
      weekStart: _weekStart,
    );
  }

  Future<List<Goal>> _activeGoals(String todayStr) async {
    final goals = await _goalRepository.watchAllGoals().first;
    final active = <Goal>[];
    for (final goal in goals) {
      final versions = await _goalVersionRepository.findAllForGoal(goal.id);
      final status = resolveLifecycleStatus(
        goal: goal,
        versions: versions,
        today: todayStr,
      );
      if (status == GoalLifecycleStatus.active) active.add(goal);
    }
    return active;
  }

  /// Mirrors `evaluate.dart`'s private `_findGoverningVersion` on the read
  /// side — duplicated as a small pure lookup rather than exported
  /// cross-module, the same choice `goal_lifecycle_status.dart` already
  /// made.
  GoalVersion? _governingVersion(List<GoalVersion> versions, String dateStr) {
    GoalVersion? governing;
    final sorted = [...versions]
      ..sort((a, b) => a.versionStartDate.compareTo(b.versionStartDate));
    for (final version in sorted) {
      if (version.versionStartDate.compareTo(dateStr) <= 0) {
        governing = version;
      } else {
        break;
      }
    }
    return governing;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
