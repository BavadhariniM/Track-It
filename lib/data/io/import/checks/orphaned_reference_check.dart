/// Subtask 2.5 (AC #6): for every `goalId` referenced by a `goalVersions`/
/// `goalLogs`/`cheatDays`/`blackoutDates` record, confirms a matching Goal
/// exists either in the file itself or in [existingLocalGoalIds] — on
/// failure, names the missing Goal reference (UX-DR19), e.g. "This file
/// references a Goal that no longer exists."
class OrphanedReferenceCheck {
  const OrphanedReferenceCheck();

  static const childArrayLabels = {
    'goalVersions': 'GoalVersion',
    'goalLogs': 'GoalLog',
    'cheatDays': 'CheatDay',
    'blackoutDates': 'BlackoutDate',
  };

  String? check(Map<String, dynamic> json, Set<String> existingLocalGoalIds) {
    final fileGoalIds = <String>{
      for (final goal in (json['goals'] as List? ?? const []))
        if (goal is Map && goal['id'] is String) goal['id'] as String,
    };
    final knownGoalIds = {...fileGoalIds, ...existingLocalGoalIds};

    for (final entry in childArrayLabels.entries) {
      final list = json[entry.key];
      if (list is! List) continue;
      for (final item in list) {
        if (item is! Map) continue;
        final goalId = item['goalId'];
        if (goalId is! String || !knownGoalIds.contains(goalId)) {
          return 'This file references a Goal that no longer exists — '
              '${entry.value} "${item['id']}" points to a goalId that is '
              'absent from both the file and this device\'s existing data.';
        }
      }
    }
    return null;
  }
}
