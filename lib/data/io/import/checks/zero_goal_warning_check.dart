/// Subtask 2.9 (AC #8): flags a warning (never a rejection) when `goals` is
/// an empty array on an otherwise structurally valid file — distinct from
/// AC #3, where the `goals` *key* is absent entirely (a [RequiredStructureCheck]
/// rejection). Do not conflate "empty array" with "missing key."
class ZeroGoalWarningCheck {
  const ZeroGoalWarningCheck();

  bool appliesTo(Map<String, dynamic> json) {
    final goals = json['goals'];
    return goals is List && goals.isEmpty;
  }
}
