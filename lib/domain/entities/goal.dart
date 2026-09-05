/// A single logical goal. The rules governing how it is evaluated live on
/// its [GoalVersion]s, not here — see `goal_version.dart`.
class Goal {
  const Goal({
    required this.id,
    required this.name,
    this.description,
    this.category,
    required this.archived,
    required this.startDate,
    this.endDate,
  });

  /// UUIDv4 string.
  final String id;

  final String name;

  final String? description;

  /// Full category *filtering* is Epic 3 Story 3.5; the field exists on the
  /// entity from Story 1.1 onward per the ER diagram.
  final String? category;

  final bool archived;

  /// Naive ISO-8601 date-only string (`YYYY-MM-DD`), no timezone.
  final String startDate;

  /// Naive ISO-8601 date-only string (`YYYY-MM-DD`), no timezone. `null`
  /// means indefinite (no end date), per FR-1. Added by Story 1.9 to close
  /// a documented gap between the architecture's ER diagram and FR-1's
  /// "an optional end date (or 'no end date')" requirement — purely
  /// additive, nothing in `evaluate()` reads this yet (no AD-5 goal-end-date
  /// clipping has been wired up).
  final String? endDate;

  Goal copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    bool clearCategory = false,
    bool? archived,
    String? startDate,
    String? endDate,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: clearCategory ? null : (category ?? this.category),
      archived: archived ?? this.archived,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Goal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          category == other.category &&
          archived == other.archived &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    category,
    archived,
    startDate,
    endDate,
  );

  @override
  String toString() =>
      'Goal(id: $id, name: $name, category: $category, archived: $archived, startDate: $startDate, endDate: $endDate)';
}
