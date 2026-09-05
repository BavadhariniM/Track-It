/// A dated rule segment for a [Goal]. Editing a goal's rules never mutates
/// history — it creates a new `GoalVersion` with a later `versionStartDate`
/// (AD-5/AD-6). Which Version governs a given date is resolved at evaluation
/// time; it is never stored on a `GoalLog`.
///
/// `evaluationPeriod`, `eligibleDaysRule`, `targetComparison`, and
/// `targetValue` are strings (not enums) per the architecture ER diagram —
/// later stories (1.3 period types, 1.4 eligible-days presets/arbitrary
/// selection, 1.5 custom recurrence, 1.7 free-combination target
/// comparisons) widen what these strings can encode without a schema change.
class GoalVersion {
  const GoalVersion({
    required this.id,
    required this.goalId,
    required this.versionStartDate,
    required this.evaluationPeriod,
    required this.eligibleDaysRule,
    required this.targetComparison,
    required this.targetValue,
    required this.trackingType,
    this.cheatDayQuota = 0,
    this.isPaused = false,
  });

  /// UUIDv4 string.
  final String id;

  /// FK to [Goal.id].
  final String goalId;

  /// Naive ISO-8601 date-only string (`YYYY-MM-DD`).
  final String versionStartDate;

  final String evaluationPeriod;

  final String eligibleDaysRule;

  final String targetComparison;

  final String targetValue;

  final String trackingType;

  /// Cheat Day *usage* is Epic 2 Story 2.4; the quota field exists from
  /// Story 1.1 onward.
  final int cheatDayQuota;

  /// Pause/resume *UI and writing* is Epic 2 Story 2.2; `evaluate()` reads
  /// this field from Story 1.1 onward (AD-4's pause-awareness rule).
  final bool isPaused;

  GoalVersion copyWith({
    String? id,
    String? goalId,
    String? versionStartDate,
    String? evaluationPeriod,
    String? eligibleDaysRule,
    String? targetComparison,
    String? targetValue,
    String? trackingType,
    int? cheatDayQuota,
    bool? isPaused,
  }) {
    return GoalVersion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      versionStartDate: versionStartDate ?? this.versionStartDate,
      evaluationPeriod: evaluationPeriod ?? this.evaluationPeriod,
      eligibleDaysRule: eligibleDaysRule ?? this.eligibleDaysRule,
      targetComparison: targetComparison ?? this.targetComparison,
      targetValue: targetValue ?? this.targetValue,
      trackingType: trackingType ?? this.trackingType,
      cheatDayQuota: cheatDayQuota ?? this.cheatDayQuota,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalVersion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          goalId == other.goalId &&
          versionStartDate == other.versionStartDate &&
          evaluationPeriod == other.evaluationPeriod &&
          eligibleDaysRule == other.eligibleDaysRule &&
          targetComparison == other.targetComparison &&
          targetValue == other.targetValue &&
          trackingType == other.trackingType &&
          cheatDayQuota == other.cheatDayQuota &&
          isPaused == other.isPaused;

  @override
  int get hashCode => Object.hash(
    id,
    goalId,
    versionStartDate,
    evaluationPeriod,
    eligibleDaysRule,
    targetComparison,
    targetValue,
    trackingType,
    cheatDayQuota,
    isPaused,
  );

  @override
  String toString() =>
      'GoalVersion(id: $id, goalId: $goalId, versionStartDate: $versionStartDate, '
      'evaluationPeriod: $evaluationPeriod, eligibleDaysRule: $eligibleDaysRule, '
      'targetComparison: $targetComparison, targetValue: $targetValue, '
      'trackingType: $trackingType, cheatDayQuota: $cheatDayQuota, isPaused: $isPaused)';
}
