/// Subtask 2.8 (AC #7): confirms `cheatDayQuota` is a non-negative integer
/// on every GoalVersion, and that every CheatDay record carries a
/// well-formed `goalId`. Names the specific invalid Cheat Day configuration
/// on failure (UX-DR19).
class CheatDayConfigCheck {
  const CheatDayConfigCheck();

  String? check(Map<String, dynamic> json) {
    for (final version in (json['goalVersions'] as List? ?? const [])) {
      if (version is! Map) continue;
      final quota = version['cheatDayQuota'];
      if (quota != null && (quota is! int || quota < 0)) {
        return 'GoalVersion "${version['id']}" has an invalid '
            'cheatDayQuota: "$quota" — it must be a non-negative integer.';
      }
    }
    for (final cheatDay in (json['cheatDays'] as List? ?? const [])) {
      if (cheatDay is! Map) continue;
      final goalId = cheatDay['goalId'];
      if (goalId is! String || goalId.isEmpty) {
        return 'CheatDay "${cheatDay['id']}" is missing a valid goalId.';
      }
    }
    return null;
  }
}
