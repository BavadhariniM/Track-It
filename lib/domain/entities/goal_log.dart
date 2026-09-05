/// A single day's recorded entry against a [Goal]. Deliberately carries no
/// `versionId`/`goalVersionId` field — which `GoalVersion` governs a log is
/// resolved at evaluation time by matching `date` against Version windows,
/// never stored (architecture ER notes), so it can never go stale when a
/// Version is added retroactively.
class GoalLog {
  const GoalLog({
    required this.id,
    required this.goalId,
    required this.date,
    required this.timestamp,
    required this.value,
    required this.completed,
    this.dnfMarked = false,
    this.note,
  });

  /// UUIDv4 string.
  final String id;

  /// FK to [Goal.id].
  final String goalId;

  /// Naive ISO-8601 date-only string (`YYYY-MM-DD`) — the day this log
  /// applies to.
  final String date;

  /// Naive ISO-8601 timestamp string of when the entry was recorded.
  final String timestamp;

  final double value;

  final bool completed;

  /// Display-only annotation (FR-17); not an `evaluate()` input. Marking UI
  /// is Epic 2 Story 2.5, but the field exists from Story 1.1 onward.
  final bool dnfMarked;

  final String? note;

  GoalLog copyWith({
    String? id,
    String? goalId,
    String? date,
    String? timestamp,
    double? value,
    bool? completed,
    bool? dnfMarked,
    String? note,
  }) {
    return GoalLog(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      value: value ?? this.value,
      completed: completed ?? this.completed,
      dnfMarked: dnfMarked ?? this.dnfMarked,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          goalId == other.goalId &&
          date == other.date &&
          timestamp == other.timestamp &&
          value == other.value &&
          completed == other.completed &&
          dnfMarked == other.dnfMarked &&
          note == other.note;

  @override
  int get hashCode => Object.hash(
    id,
    goalId,
    date,
    timestamp,
    value,
    completed,
    dnfMarked,
    note,
  );

  @override
  String toString() =>
      'GoalLog(id: $id, goalId: $goalId, date: $date, timestamp: $timestamp, '
      'value: $value, completed: $completed, dnfMarked: $dnfMarked, note: $note)';
}
