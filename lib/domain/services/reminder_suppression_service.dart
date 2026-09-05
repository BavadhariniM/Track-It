import '../entities/blackout_date.dart';
import '../entities/cheat_day.dart';
import '../entities/day_status.dart';
import '../entities/goal.dart';
import '../entities/goal_lifecycle_status.dart';
import '../entities/goal_log.dart';
import '../entities/goal_version.dart';
import '../entities/rule_values.dart';
import '../evaluator/date_format.dart';
import '../evaluator/evaluate.dart';
import '../evaluator/period_boundary.dart';

/// One goal's `evaluate()` inputs, bundled so [filterRemindableGoals] can
/// accept every tracked goal in a single call — the same per-goal shape
/// `evaluate()` itself takes (AD-4), just grouped for convenience at the
/// reminder call site.
class GoalReminderInput {
  const GoalReminderInput({
    required this.goal,
    required this.versions,
    required this.logs,
    this.cheatDays = const [],
    this.blackoutDates = const [],
  });

  final Goal goal;
  final List<GoalVersion> versions;
  final List<GoalLog> logs;
  final List<CheatDay> cheatDays;
  final List<BlackoutDate> blackoutDates;
}

/// FR-30's suppression rules (Story 4.2): given every tracked goal's
/// `evaluate()` inputs for [date], returns the subset that deserve a mention
/// in today's reminder.
///
/// A goal is excluded when it is Paused or Archived (AC #2, read directly
/// from the Goal/Version lifecycle state via [resolveLifecycleStatus] —
/// Epic 2's own model, not re-derived here), or when it is not Eligible
/// today per `evaluate()`'s output (AC #1). Otherwise, a goal whose At Most
/// or Exactly target for the current period is already met (or exceeded) is
/// suppressed (AC #3); an At Least goal is never suppressed on target-met
/// grounds, since additional logging beyond the minimum may still be wanted
/// (AC #4).
///
/// This is a pure filter over `evaluate()`'s own output (AD-4): it calls
/// `evaluate()` once per goal and never re-implements eligibility,
/// target-met, or pause/archive-state logic itself. Returns an empty list
/// when nothing qualifies (AC #5 — the caller must not fire an empty
/// reminder).
List<Goal> filterRemindableGoals({
  required List<GoalReminderInput> goals,
  required DateTime date,
  WeekStart weekStart = WeekStart.monday,
}) {
  final dateStr = formatDateOnly(date);
  final remindable = <Goal>[];

  for (final input in goals) {
    final lifecycle = resolveLifecycleStatus(
      goal: input.goal,
      versions: input.versions,
      today: dateStr,
    );
    if (lifecycle == GoalLifecycleStatus.paused ||
        lifecycle == GoalLifecycleStatus.archived) {
      continue;
    }

    final status = evaluate(
      goal: input.goal,
      versions: input.versions,
      logs: input.logs,
      cheatDays: input.cheatDays,
      blackoutDates: input.blackoutDates,
      date: date,
      weekStart: weekStart,
    );
    if (status.status == DayStatusValue.empty) continue;

    final governingVersion = _governingVersion(input.versions, dateStr);
    if (governingVersion == null) continue;

    if (governingVersion.targetComparison != TargetComparison.atLeast) {
      final actual = status.currentValue ?? 0;
      final target = status.targetValue ?? 0;
      // Met-or-exceeded: an At Most/Exactly goal has nothing left to
      // usefully log once its ceiling/exact value is reached, whether
      // `evaluate()` currently reports that as `success` (period fully
      // closed) or still `pending` (e.g. a Daily goal, which `evaluate()`
      // always treats as still-open until the next calendar date — see
      // `evaluate.dart`'s `_evaluateDay` comment).
      if (actual >= target) continue;
    }

    remindable.add(input.goal);
  }

  return remindable;
}

/// The latest [GoalVersion] on or before [dateStr] — the same narrow,
/// already-established local lookup `goal_lifecycle_status.dart` duplicates
/// for its own use (see that file's doc comment), not a new re-implementation
/// of `evaluate.dart`'s private version-boundary logic.
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
