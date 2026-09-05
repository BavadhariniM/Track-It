import '../entities/blackout_date.dart';
import '../entities/cheat_day.dart';
import '../entities/day_status.dart';
import '../entities/eligible_days_rule.dart';
import '../entities/goal.dart';
import '../entities/goal_log.dart';
import '../entities/goal_version.dart';
import '../entities/rule_values.dart';
import 'date_format.dart';
import 'period_boundary.dart';

/// The single evaluator entry point (AD-4). Every caller — the live
/// calendar, `CacheWriter`, `StatsService`, widget precompute — calls this
/// same function; none re-implements evaluation logic.
///
/// This is the full AD-4 contract, finalized in Story 1.3 — `goal`,
/// `versions`, `logs`, `cheatDays`, `blackoutDates`, and `date`.
/// `cheatDays`/`blackoutDates` default to empty lists when a caller has
/// none to pass. `weekStart` is plain data a caller resolves from
/// `shared_preferences` itself (FR-24) — the evaluator stays pure, never
/// reading it via I/O.
///
/// `today` (Bug 9) is the real wall-clock "as of" date, distinct from
/// `date` — `date` only selects which period window is being asked about
/// and which row is returned, it never doubles as "now." Defaults to
/// `date` when omitted, so every caller that only ever queries the current
/// date (StatsService, CacheWriter, GoalService, every pre-Bug-9 test) is
/// unaffected; live-calendar callers that render other dates (Day/Week/
/// Month View) must pass the real current date explicitly or a
/// still-future period could be evaluated as if it had already elapsed —
/// and, since a Daily period's own certain-failure resolution now also
/// depends on `today` (a Daily day only resolves to Success/Fail once it
/// has fully elapsed; it stays Pending while `date` is today-or-future), a
/// caller that queries a *past* Daily-period date without passing the real
/// `today` will see that day evaluated as if it were still open, the same
/// stale-"now" trap that already applied to period-type goals.
///
/// No I/O, no Flutter, no Drift imports — fully deterministic. `versions`,
/// `logs`, `cheatDays`, `blackoutDates` may arrive in any order; all are
/// sorted internally before use so determinism never depends on
/// caller-supplied ordering (AC #4).
DayStatus evaluate({
  required Goal goal,
  required List<GoalVersion> versions,
  required List<GoalLog> logs,
  List<CheatDay> cheatDays = const [],
  List<BlackoutDate> blackoutDates = const [],
  required DateTime date,
  DateTime? today,
  WeekStart weekStart = WeekStart.monday,
}) {
  final dateStr = formatDateOnly(date);

  final sortedVersions = [...versions]
    ..sort((a, b) => a.versionStartDate.compareTo(b.versionStartDate));
  final sortedLogs = [...logs]..sort((a, b) => a.date.compareTo(b.date));
  final sortedBlackoutDates = [...blackoutDates]
    ..sort((a, b) => a.date.compareTo(b.date));
  final sortedCheatDays = [...cheatDays]
    ..sort((a, b) => a.date.compareTo(b.date));

  final goalStartDate = DateTime.parse(goal.startDate);

  final governingVersion = _findGoverningVersion(sortedVersions, dateStr);
  if (governingVersion == null) {
    return DayStatus(
      goalId: goal.id,
      date: dateStr,
      status: DayStatusValue.empty,
    );
  }

  final targetValue = double.tryParse(governingVersion.targetValue);

  // Daily is the Story 1.1/1.2 single-day case, kept exactly as before —
  // it is simply the Daily period's [date, date] window, not a special case
  // that duplicates the period-aggregation path below. Pause-awareness and
  // eligibility are checked here, not above, because for a period-type goal
  // they must gate individual dates *within* the period (already done
  // per-date inside `_evaluatePeriod`'s loop), never the query date alone —
  // a Weekly "workdays only" goal queried on a Saturday must still return
  // the week's aggregate progress, not short-circuit to Empty just because
  // Saturday itself isn't a workday.
  if (governingVersion.evaluationPeriod == EvaluationPeriod.daily) {
    // Pause-awareness (AD-4): a date governed by a paused Version
    // contributes zero eligible days, the same way a date excluded by
    // eligibleDaysRule does.
    if (governingVersion.isPaused) {
      return DayStatus(
        goalId: goal.id,
        date: dateStr,
        status: DayStatusValue.empty,
      );
    }
    if (!_isEligibleDay(
      governingVersion.eligibleDaysRule,
      date,
      goalStartDate,
    )) {
      return DayStatus(
        goalId: goal.id,
        date: dateStr,
        status: DayStatusValue.empty,
      );
    }
    return _evaluateDay(
      goal: goal,
      dateStr: dateStr,
      governingVersion: governingVersion,
      sortedLogs: sortedLogs,
      sortedBlackoutDates: sortedBlackoutDates,
      sortedCheatDays: sortedCheatDays,
      targetValue: targetValue,
      // A Daily period is only "still open" while it IS today or a future
      // date — once a later real-world date exists, this day can never
      // receive another log, so its outcome must be treated as final rather
      // than staying Pending forever. `today ?? date` mirrors the
      // `_evaluatePeriod` branch below (Bug 9's "as of" convention) so a
      // caller that only ever queries the current date (every pre-this-fix
      // caller) sees no behavior change: `date == today` is never elapsed.
      isElapsed: dateStr.compareTo(formatDateOnly(today ?? date)) < 0,
    );
  }

  return _evaluatePeriod(
    goal: goal,
    date: date,
    today: today ?? date,
    dateStr: dateStr,
    goalStartDate: goalStartDate,
    sortedVersions: sortedVersions,
    governingVersion: governingVersion,
    sortedLogs: sortedLogs,
    sortedBlackoutDates: sortedBlackoutDates,
    sortedCheatDays: sortedCheatDays,
    targetValue: targetValue,
    weekStart: weekStart,
  );
}

/// A second, narrower question than [evaluate()]'s (AD-4's single entry
/// point for "is this goal on track for its period"): "did [date] itself,
/// in isolation, get logged done" — regardless of whether the goal's
/// governing Version is Daily or a multi-day period (Weekly/Monthly/etc).
/// For a period-type goal, [evaluate()] deliberately returns the SAME
/// period-aggregate status for every date inside that period (e.g. a
/// Weekly "at least 2x/week" goal shows Pending on every day of the week
/// until the week resolves, even on the specific day you logged it) — that
/// is correct for "is the goal on track," but it hides "did today happen."
/// [evaluateDayOnly] answers that second question instead, reusing
/// `_evaluateDay`'s existing single-day logic (already exactly right: a
/// completed log for that exact date is Success, an explicit not-done log
/// is Fail, an elapsed unlogged date is Fail, blackout/cheat exemptions and
/// pause/pre-start/ineligibility all apply identically) for ANY period
/// type, not just Daily.
///
/// Only meaningful for [TrackingType.boolean]/[TrackingType.counterDoneCount]
/// — a summed [TrackingType.counter] goal's target is a whole-period total
/// (e.g. "2 per week" could be split across days), so it has no per-day
/// pass/fail of its own; for that tracking type this simply delegates to
/// the real period-aware [evaluate()] for [date] instead of fabricating a
/// misleading single-day verdict.
///
/// No `weekStart` parameter — day-only evaluation never resolves a period
/// boundary, so there is no ambiguity for it to disambiguate.
DayStatus evaluateDayOnly({
  required Goal goal,
  required List<GoalVersion> versions,
  required List<GoalLog> logs,
  List<CheatDay> cheatDays = const [],
  List<BlackoutDate> blackoutDates = const [],
  required DateTime date,
  DateTime? today,
}) {
  final dateStr = formatDateOnly(date);

  final sortedVersions = [...versions]
    ..sort((a, b) => a.versionStartDate.compareTo(b.versionStartDate));

  final governingVersion = _findGoverningVersion(sortedVersions, dateStr);
  if (governingVersion == null) {
    return DayStatus(goalId: goal.id, date: dateStr, status: DayStatusValue.empty);
  }

  if (governingVersion.trackingType == TrackingType.counter) {
    // No per-day pass/fail exists for a summed Counter's whole-period
    // target — defer entirely to the real period-aware evaluate() for
    // [date], including its own per-day-within-the-period eligibility
    // handling (a "workdays only" Weekly Counter goal queried on a
    // Saturday still shows the week's aggregate, never a premature Empty
    // short-circuit here).
    return evaluate(
      goal: goal,
      versions: versions,
      logs: logs,
      cheatDays: cheatDays,
      blackoutDates: blackoutDates,
      date: date,
      today: today,
    );
  }

  // boolean / counterDoneCount: the same pause/eligibility guards
  // evaluate()'s own Daily branch applies to its query date, applied here
  // regardless of the goal's actual period type — a date this goal's own
  // rule doesn't schedule, or that falls under a paused Version, renders
  // Empty rather than attempting a same-day verdict.
  final goalStartDate = DateTime.parse(goal.startDate);
  if (governingVersion.isPaused) {
    return DayStatus(goalId: goal.id, date: dateStr, status: DayStatusValue.empty);
  }
  if (!_isEligibleDay(governingVersion.eligibleDaysRule, date, goalStartDate)) {
    return DayStatus(goalId: goal.id, date: dateStr, status: DayStatusValue.empty);
  }

  final sortedLogs = [...logs]..sort((a, b) => a.date.compareTo(b.date));
  final sortedBlackoutDates = [...blackoutDates]
    ..sort((a, b) => a.date.compareTo(b.date));
  final sortedCheatDays = [...cheatDays]
    ..sort((a, b) => a.date.compareTo(b.date));
  final targetValue = double.tryParse(governingVersion.targetValue);
  return _evaluateDay(
    goal: goal,
    dateStr: dateStr,
    governingVersion: governingVersion,
    sortedLogs: sortedLogs,
    sortedBlackoutDates: sortedBlackoutDates,
    sortedCheatDays: sortedCheatDays,
    targetValue: targetValue,
    isElapsed: dateStr.compareTo(formatDateOnly(today ?? date)) < 0,
  );
}

DayStatus _evaluateDay({
  required Goal goal,
  required String dateStr,
  required GoalVersion governingVersion,
  required List<GoalLog> sortedLogs,
  required List<BlackoutDate> sortedBlackoutDates,
  required List<CheatDay> sortedCheatDays,
  required double? targetValue,
  /// Whether [dateStr] is strictly before the real "as of" date — i.e. this
  /// day has fully elapsed and can never receive another log. `false` for
  /// today (still in progress) and for any future date.
  required bool isElapsed,
}) {
  final logsForDate = sortedLogs.where(
    (log) => log.goalId == goal.id && log.date == dateStr,
  );

  final isBlackedOut = _isBlackedOut(goal.id, dateStr, sortedBlackoutDates);
  final isCheatDay = _isCheatDay(goal.id, dateStr, sortedCheatDays);

  if (governingVersion.trackingType == TrackingType.counter) {
    // Sums defensively over every matching row even though the write path
    // (GoalService.logCounter) upserts a single row per (goalId, date) —
    // see Story 1.2 Subtask 1.2/2.2.
    final total = logsForDate.fold<double>(0, (sum, log) => sum + log.value);
    final met = _meetsTarget(
      governingVersion.targetComparison,
      total,
      targetValue ?? 0,
    );
    // FR-10 applies uniformly to every Tracking Type, not just Boolean: a
    // blacked-out day that hasn't hit its Counter target is a non-event,
    // never counted as a miss. FR-16: a used Cheat Day is the same
    // exemption, just rendered with its own token (AC 1) rather than
    // Blackout's `empty`.
    if (!met && isBlackedOut) {
      return DayStatus(
        goalId: goal.id,
        date: dateStr,
        status: DayStatusValue.empty,
      );
    }
    if (!met && isCheatDay) {
      return DayStatus(
        goalId: goal.id,
        date: dateStr,
        status: DayStatusValue.cheat,
      );
    }
    // Story 1.8: a Daily period IS the single day being evaluated, so while
    // it's still open (not yet elapsed) it always has exactly one
    // remaining/open eligible day (this same day) — a later log that same
    // day could still push the total past/up to the target (Story 1.2),
    // which is what gives the shared certain-failure function its
    // overshoot-Fail behavior (At Most/Exactly) for free, matching Pattern
    // 3/13's corrected expectations. Once [isElapsed] (no further log is
    // possible), zero eligible days remain, letting this same function
    // resolve the day to its final Success/Fail instead of leaving it
    // Pending forever.
    final status = _determineStatus(
      comparison: governingVersion.targetComparison,
      trackingType: TrackingType.counter,
      actual: total,
      target: targetValue ?? 0,
      remainingEligibleDays: isElapsed ? 0 : 1,
    );
    return DayStatus(
      goalId: goal.id,
      date: dateStr,
      status: status,
      currentValue: total,
      targetValue: targetValue,
    );
  }

  final logForDate = logsForDate.isEmpty ? null : logsForDate.last;

  if (logForDate == null || !logForDate.completed) {
    // FR-10: a Blackout Date exempts the date from failure — it is a
    // non-event for pass/fail accounting, never a Fail (nor a misrepresented
    // Success). This is the seam Story 1.8's certain-failure math consumes:
    // a blacked-out eligible day must never be counted as a miss.
    if (isBlackedOut) {
      return DayStatus(
        goalId: goal.id,
        date: dateStr,
        status: DayStatusValue.empty,
      );
    }
    // FR-16: a used Cheat Day exempts the date from failure the same way —
    // an occasional planned skip within quota renders `cheat` (AC 1)
    // instead of `fail`/`pending`.
    if (isCheatDay) {
      return DayStatus(
        goalId: goal.id,
        date: dateStr,
        status: DayStatusValue.cheat,
      );
    }
    // Not yet logged (or explicitly logged not-done): certain-failure/red
    // semantics are Story 1.8's concern. An unlogged eligible day must not
    // be misrepresented as Success, so while the day is still open it stays
    // Pending — a log recording an explicit failure is always Fail
    // regardless, and once the day has elapsed with no completed log at
    // all, it can never resolve to Success either, so it becomes a certain
    // Fail instead of staying Pending forever.
    return DayStatus(
      goalId: goal.id,
      date: dateStr,
      status: logForDate == null
          ? (isElapsed ? DayStatusValue.fail : DayStatusValue.pending)
          : DayStatusValue.fail,
      currentValue: logForDate?.value,
      targetValue: targetValue,
    );
  }

  return DayStatus(
    goalId: goal.id,
    date: dateStr,
    status: DayStatusValue.success,
    currentValue: logForDate.value,
    targetValue: targetValue,
  );
}

/// FR-10 consequence: Blackout Dates are a wholly separate mechanism from
/// (the not-yet-existing) Cheat Days — kept as a distinct evaluator input
/// and a distinct check, never merged into one "exemption" list/boolean.
bool _isBlackedOut(
  String goalId,
  String dateStr,
  List<BlackoutDate> sortedBlackoutDates,
) {
  return sortedBlackoutDates.any(
    (blackoutDate) =>
        blackoutDate.goalId == goalId && blackoutDate.date == dateStr,
  );
}

/// FR-16: a real, `GoalService`-persisted Cheat Day exempts [dateStr] from
/// failure — a wholly separate mechanism from Blackout Dates (Story 1.6
/// AC 3: a Blackout Date consumes no Cheat Day quota), kept as its own
/// distinct evaluator input and check, never merged into one shared
/// exemption list/boolean.
bool _isCheatDay(
  String goalId,
  String dateStr,
  List<CheatDay> sortedCheatDays,
) {
  return sortedCheatDays.any(
    (cheatDay) => cheatDay.goalId == goalId && cheatDay.date == dateStr,
  );
}

/// Generalizes Story 1.1/1.2's per-day aggregation to an arbitrary
/// `[periodStart, periodEnd]` range — Weekly/Biweekly/Monthly/Quarterly/
/// Yearly/Rolling-Window/Custom all funnel through this one path, never a
/// second evaluation code path per period type.
///
/// Story 1.8 consumes Blackout Dates here (FR-10): a blacked-out eligible
/// day never counts as a miss, but per this story's certain-failure math it
/// also must not silently vanish from the pool — it becomes still-open
/// "remaining capacity" instead, exactly like an unresolved today-or-future
/// day, so it can never itself push a period toward certain failure.
DayStatus _evaluatePeriod({
  required Goal goal,
  required DateTime date,
  required DateTime today,
  required String dateStr,
  required DateTime goalStartDate,
  required List<GoalVersion> sortedVersions,
  required GoalVersion governingVersion,
  required List<GoalLog> sortedLogs,
  required List<BlackoutDate> sortedBlackoutDates,
  required List<CheatDay> sortedCheatDays,
  required double? targetValue,
  required WeekStart weekStart,
}) {
  final rawBoundary = periodBoundaryFor(
    evaluationPeriod: governingVersion.evaluationPeriod,
    date: date,
    goalStartDate: goalStartDate,
    weekStart: weekStart,
  );

  // AD-5: intersect the calendar boundary with the governing rule-window —
  // consecutive Versions differing ONLY by isPaused are treated as one
  // continuous rule-window (AD-5's pause carve-out), not a truncation
  // boundary; a genuine rule-field change still truncates the period.
  final ruleWindow = _ruleWindowFor(sortedVersions, governingVersion);
  var periodStart = rawBoundary.start;
  if (periodStart.isBefore(ruleWindow.start)) periodStart = ruleWindow.start;
  var periodEnd = rawBoundary.end;
  if (ruleWindow.endExclusive != null) {
    final lastRuleDay = ruleWindow.endExclusive!.subtract(
      const Duration(days: 1),
    );
    if (periodEnd.isAfter(lastRuleDay)) periodEnd = lastRuleDay;
  }

  double booleanSuccessCount = 0;
  double counterTotal = 0;
  var totalEligibleDays = 0;
  var remainingEligibleDays = 0;
  final isSummedCounter = governingVersion.trackingType == TrackingType.counter;

  for (
    var cursor = periodStart;
    !cursor.isAfter(periodEnd);
    cursor = cursor.add(const Duration(days: 1))
  ) {
    final cursorStr = formatDateOnly(cursor);
    final cursorVersion = _findGoverningVersion(sortedVersions, cursorStr);
    if (cursorVersion == null || cursorVersion.isPaused) continue;
    if (!_isEligibleDay(
      cursorVersion.eligibleDaysRule,
      cursor,
      goalStartDate,
    )) {
      continue;
    }
    totalEligibleDays += 1;

    final logsThatDate = sortedLogs.where(
      (log) => log.goalId == goal.id && log.date == cursorStr,
    );
    final isBlackedOutThatDate = _isBlackedOut(
      goal.id,
      cursorStr,
      sortedBlackoutDates,
    );
    final isCheatDayThatDate = _isCheatDay(goal.id, cursorStr, sortedCheatDays);

    // Bug 9: `!cursor.isBefore(today)` (i.e. `cursor >= today`, NOT
    // `cursor > today`) is deliberate — today itself always counts as
    // still-open/remaining when unlogged, so a mid-day Pending can't flip
    // to Fail/Success before today's own outcome could possibly be
    // settled. This compares against `today` (the real "as of" date), NOT
    // `date` (which day's row is being queried) — a day that has already
    // happened in the real world is never "still open" just because some
    // other cell's `date` is earlier than it.
    final isTodayOrFuture = !cursor.isBefore(today);

    if (isSummedCounter) {
      counterTotal += logsThatDate.fold<double>(
        0,
        (sum, log) => sum + log.value,
      );
      // A summed Counter has no per-day cap — a still-open remaining day
      // could always contribute enough to close any gap, so this is just a
      // count of open days, not a capped "amount"; the "unbounded" cap is
      // applied in `_determineStatus`, not here.
      if (isTodayOrFuture) remainingEligibleDays += 1;
    } else {
      // boolean or counterDoneCount: day-counting modes share this logic.
      final hasCompletedLog =
          logsThatDate.isNotEmpty && logsThatDate.last.completed;
      if (hasCompletedLog) {
        // Already resolved as a success, regardless of past/future — a
        // resolved eligible day never un-resolves.
        booleanSuccessCount += 1;
      } else if (isBlackedOutThatDate || isCheatDayThatDate) {
        // FR-10/FR-16: exempt — doesn't count against you, treated as
        // still-open capacity rather than a miss. AC 3: this is exactly how
        // the required count stays unreduced for a used Cheat Day across
        // every Target Comparison (At Least/At Most/Exactly) — it's the
        // same "still open" branch every unresolved eligible day already
        // funnels through, not a comparison-specific carve-out.
        remainingEligibleDays += 1;
      } else if (isTodayOrFuture) {
        // Today or future, unlogged: still has a chance.
        remainingEligibleDays += 1;
      }
      // else: cursor < date, unlogged, not blacked out — a genuinely
      // missed/used-up slot. Contributes to neither actual nor
      // remainingEligibleDays.
    }
  }

  // FR-5 (Task 2): a period whose ENTIRE eligible-day pool is zero is a
  // deliberate exception to the normal "no eligible days = Empty" default
  // (Story 1.4's per-day Empty stays Empty when only a single day within an
  // otherwise-populated period is non-eligible) — this is the whole
  // period's eligible-day pool being empty, a misconfiguration signal, and
  // it must short-circuit before the certain-failure math below (which
  // would otherwise degenerate ambiguously with zero remaining days and a
  // vacuous "no days missed yet").
  if (totalEligibleDays == 0) {
    return DayStatus(
      goalId: goal.id,
      date: dateStr,
      status: DayStatusValue.fail,
    );
  }

  final actual = isSummedCounter ? counterTotal : booleanSuccessCount;

  final status = _determineStatus(
    comparison: governingVersion.targetComparison,
    trackingType: governingVersion.trackingType,
    actual: actual,
    target: targetValue ?? 0,
    remainingEligibleDays: remainingEligibleDays,
  );

  return DayStatus(
    goalId: goal.id,
    date: dateStr,
    status: status,
    currentValue: actual,
    targetValue: targetValue,
  );
}

/// The complete Target Comparison predicate (FR-11): At Least, At Most,
/// Exactly — deliberately no `Range`. One shared function regardless of
/// which period type or Tracking Type produced [actual] (FR-12 axis
/// independence) — it never inspects anything beyond the two numbers.
bool _meetsTarget(String comparison, double actual, double target) {
  return switch (comparison) {
    TargetComparison.atLeast => actual >= target,
    TargetComparison.atMost => actual <= target,
    TargetComparison.exactly => actual == target,
    _ => actual >= target,
  };
}

/// Story 1.8's certain-failure/status-determination stage — the final stage
/// of `evaluate()`'s pipeline (Story 1.7's boundary → eligibility →
/// aggregation → comparison, now followed by this stage). Pure arithmetic
/// over already-computed values (AD-4): given the Target Comparison, the
/// current aggregated [actual], the [target], and the count of eligible
/// days that are still open ([remainingEligibleDays] — today-or-future,
/// unresolved, or blacked-out days within the period; see
/// `_evaluatePeriod`'s per-date loop), decides whether the best-possible
/// remaining outcome can still change the result. FR-18: a day/period only
/// turns red once failure is mathematically certain, never merely because
/// the target isn't hit yet — before certain, the status is Pending.
///
/// One shared function for both `_evaluateDay`'s Counter branch and
/// `_evaluatePeriod`, regardless of period type (FR-12 axis independence).
DayStatusValue _determineStatus({
  required String comparison,
  required String trackingType,
  required double actual,
  required double target,
  required int remainingEligibleDays,
}) {
  switch (comparison) {
    case TargetComparison.atMost:
      if (actual > target) return DayStatusValue.fail; // exceeded: certain, immediate, no remaining-day math needed
      if (remainingEligibleDays <= 0) return DayStatusValue.success; // closed, never exceeded
      return DayStatusValue.pending; // still open — could still be exceeded later, so not yet certain success

    case TargetComparison.exactly:
      if (actual > target) return DayStatusValue.fail; // overshoot: can never come back down within the period
      if (remainingEligibleDays <= 0) {
        return actual == target ? DayStatusValue.success : DayStatusValue.fail;
      }
      final unboundedPerRemainingDay = trackingType == TrackingType.counter;
      if (!unboundedPerRemainingDay && actual + remainingEligibleDays < target) {
        return DayStatusValue.fail; // can no longer reach it even with every remaining day succeeding
      }
      return DayStatusValue.pending; // on-target or reachable, but remaining days could still overshoot it or are still needed — not yet certain

    case TargetComparison.atLeast:
    default:
      if (actual >= target) return DayStatusValue.success; // already reached — once-resolved eligible days never un-resolve, so this can't be undone
      if (remainingEligibleDays <= 0) return DayStatusValue.fail; // period closed, still short
      final unboundedPerRemainingDay = trackingType == TrackingType.counter;
      if (!unboundedPerRemainingDay && actual + remainingEligibleDays < target) {
        return DayStatusValue.fail;
      }
      return DayStatusValue.pending;
  }
}

/// The latest Version whose `versionStartDate` is on or before [dateStr],
/// or `null` if [dateStr] precedes every Version (the goal has no rule
/// active yet on that date).
GoalVersion? _findGoverningVersion(
  List<GoalVersion> sortedVersions,
  String dateStr,
) {
  GoalVersion? governing;
  for (final version in sortedVersions) {
    if (version.versionStartDate.compareTo(dateStr) <= 0) {
      governing = version;
    } else {
      break;
    }
  }
  return governing;
}

/// The AD-5 rule-window containing [governingVersion]: walks outward while
/// adjacent Versions share every rule field except `isPaused` (AD-5's pause
/// carve-out), so a pause-only boundary never truncates the period. Epic 1
/// never constructs more than one Version, so this always degenerates to
/// `[governingVersion.versionStartDate, null)` — but the general logic must
/// exist now so Epic 2 doesn't have to rewrite this function.
({DateTime start, DateTime? endExclusive}) _ruleWindowFor(
  List<GoalVersion> sortedVersions,
  GoalVersion governingVersion,
) {
  final index = sortedVersions.indexOf(governingVersion);

  var startIndex = index;
  while (startIndex > 0 &&
      _sameRuleExceptPause(sortedVersions[startIndex - 1], governingVersion)) {
    startIndex--;
  }

  var endIndex = index;
  while (endIndex + 1 < sortedVersions.length &&
      _sameRuleExceptPause(sortedVersions[endIndex + 1], governingVersion)) {
    endIndex++;
  }

  final start = DateTime.parse(sortedVersions[startIndex].versionStartDate);
  final endExclusive = endIndex + 1 < sortedVersions.length
      ? DateTime.parse(sortedVersions[endIndex + 1].versionStartDate)
      : null;
  return (start: start, endExclusive: endExclusive);
}

bool _sameRuleExceptPause(GoalVersion a, GoalVersion b) {
  return a.evaluationPeriod == b.evaluationPeriod &&
      a.eligibleDaysRule == b.eligibleDaysRule &&
      a.targetComparison == b.targetComparison &&
      a.targetValue == b.targetValue &&
      a.trackingType == b.trackingType &&
      a.cheatDayQuota == b.cheatDayQuota;
}

/// Gates whether [date] counts toward a period's eligible-day pool at all
/// (consumed by Story 1.3's period aggregation and Story 1.8's
/// certain-failure math) — one shared predicate, not duplicated per period
/// type or per recurrence variant (Story 1.4's plain weekday set and Story
/// 1.5's custom recurrence patterns are all cases of [EligibleDaysPattern]).
bool _isEligibleDay(
  String eligibleDaysRule,
  DateTime date,
  DateTime goalStartDate,
) {
  return EligibleDaysPattern.decode(eligibleDaysRule)
      .isEligible(date: date, goalStartDate: goalStartDate);
}
