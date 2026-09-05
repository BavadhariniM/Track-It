/// The editable subset of a [GoalVersion]'s rule fields — everything Panda
/// can change from the edit wizard (Story 2.1 Subtask 1.1). Deliberately
/// excludes `id`, `goalId`, and `versionStartDate` (the collision algorithm
/// in `GoalService._writeVersionSegment` owns those) and `isPaused` (Story
/// 2.2's Pause/Resume concern, not a rule Panda edits from this wizard) —
/// this is a plain data-carrier, not a `GoalVersion` itself, so a caller can
/// never accidentally smuggle an id/date/pause-state through the edit path.
class GoalVersionDraft {
  const GoalVersionDraft({
    required this.evaluationPeriod,
    required this.eligibleDaysRule,
    required this.targetComparison,
    required this.targetValue,
    required this.trackingType,
    this.cheatDayQuota = 0,
  });

  final String evaluationPeriod;
  final String eligibleDaysRule;
  final String targetComparison;
  final String targetValue;
  final String trackingType;
  final int cheatDayQuota;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalVersionDraft &&
          runtimeType == other.runtimeType &&
          evaluationPeriod == other.evaluationPeriod &&
          eligibleDaysRule == other.eligibleDaysRule &&
          targetComparison == other.targetComparison &&
          targetValue == other.targetValue &&
          trackingType == other.trackingType &&
          cheatDayQuota == other.cheatDayQuota;

  @override
  int get hashCode => Object.hash(
    evaluationPeriod,
    eligibleDaysRule,
    targetComparison,
    targetValue,
    trackingType,
    cheatDayQuota,
  );

  @override
  String toString() =>
      'GoalVersionDraft(evaluationPeriod: $evaluationPeriod, '
      'eligibleDaysRule: $eligibleDaysRule, targetComparison: $targetComparison, '
      'targetValue: $targetValue, trackingType: $trackingType, '
      'cheatDayQuota: $cheatDayQuota)';
}
