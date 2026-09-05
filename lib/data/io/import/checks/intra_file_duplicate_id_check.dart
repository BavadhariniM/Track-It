/// Subtask 2.4 (AC #5): scans each entity array for an `id` that appears
/// more than once *within the file itself* — always a hard rejection,
/// distinct from Task 3's conflict detection (an id that exists in both the
/// file and local data is a legitimate merge conflict, never a duplicate-id
/// rejection; see `conflict_detector.dart`'s doc comment for the full
/// distinction). Names the specific duplicate id and entity type (UX-DR19).
class IntraFileDuplicateIdCheck {
  const IntraFileDuplicateIdCheck();

  static const entityArrayLabels = {
    'goals': 'Goal',
    'goalVersions': 'GoalVersion',
    'goalLogs': 'GoalLog',
    'cheatDays': 'CheatDay',
    'blackoutDates': 'BlackoutDate',
  };

  String? check(Map<String, dynamic> json) {
    for (final entry in entityArrayLabels.entries) {
      final list = json[entry.key];
      if (list is! List) continue;
      final seenIds = <String>{};
      for (final item in list) {
        if (item is! Map) continue;
        final id = item['id'];
        if (id is! String) continue;
        if (!seenIds.add(id)) {
          return 'This file contains a duplicate ${entry.value} id: "$id".';
        }
      }
    }
    return null;
  }
}
