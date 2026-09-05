import 'goal.dart';
import 'goal_version.dart';

/// Goal-level lifecycle state (Story 2.2 Subtask 3.1) — distinct from
/// `evaluate()`'s per-day `DayStatus` (Story 1.1/1.3). Used by presentation
/// for UI concerns like the Pause/Resume button label and whether to render
/// a goal-row at all; never added to or confused with the `evaluate()`
/// contract.
enum GoalLifecycleStatus { active, paused, archived, expired }

/// Resolves [goal]'s lifecycle state as of [today] from its `archived`
/// flag, `endDate`, and Version history. Precedence (most to least
/// specific, Story 2.3 Subtask 2.2): `archived` (an explicitly archived
/// goal is archived, full stop, even if also past its end date or
/// mid-pause) → `expired` (`endDate` set and strictly before [today], not
/// on it) → `paused` (Story 2.2's Version-level check) → `active` (default).
GoalLifecycleStatus resolveLifecycleStatus({
  required Goal goal,
  required List<GoalVersion> versions,
  required String today,
}) {
  if (goal.archived) return GoalLifecycleStatus.archived;

  final endDate = goal.endDate;
  if (endDate != null && today.compareTo(endDate) > 0) {
    return GoalLifecycleStatus.expired;
  }

  final governing = _latestVersionOnOrBefore(versions, today);
  if (governing != null && governing.isPaused) {
    return GoalLifecycleStatus.paused;
  }
  return GoalLifecycleStatus.active;
}

/// The latest [GoalVersion] whose `versionStartDate` is on or before
/// [date], or `null` if [date] precedes every Version — mirrors the
/// evaluator's own governing-Version selection (`evaluate.dart`'s
/// `_findGoverningVersion`), duplicated here as a small pure lookup rather
/// than exported cross-module.
GoalVersion? _latestVersionOnOrBefore(List<GoalVersion> versions, String date) {
  GoalVersion? governing;
  final sorted = [...versions]
    ..sort((a, b) => a.versionStartDate.compareTo(b.versionStartDate));
  for (final version in sorted) {
    if (version.versionStartDate.compareTo(date) <= 0) {
      governing = version;
    } else {
      break;
    }
  }
  return governing;
}
