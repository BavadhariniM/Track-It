import '../../../../domain/entities/rule_values.dart';

/// Subtask 2.7 (AC #7): confirms each GoalVersion's rule combination is
/// valid per FR-11/FR-12 — `targetComparison` must be one of the three
/// supported values (Exactly/At Least/At Most; this app deliberately has no
/// `Range(min, max)` variant, `rule_values.dart`'s `TargetComparison` doc
/// comment), and a legacy Range-shaped record (`min`/`max` fields) is
/// rejected outright rather than silently reinterpreted. Names the specific
/// contradiction on failure (UX-DR19).
class RuleContradictionCheck {
  const RuleContradictionCheck();

  static const validTargetComparisons = {
    TargetComparison.exactly,
    TargetComparison.atLeast,
    TargetComparison.atMost,
  };

  static const validTrackingTypes = {
    TrackingType.boolean,
    TrackingType.counter,
    TrackingType.counterDoneCount,
  };

  String? check(Map<String, dynamic> json) {
    for (final version in (json['goalVersions'] as List? ?? const [])) {
      if (version is! Map) continue;
      final id = version['id'];
      if (version.containsKey('min') || version.containsKey('max')) {
        return 'GoalVersion "$id" uses an unsupported Range-shaped rule '
            '(min/max) — this app only supports Exactly/At Least/At Most.';
      }
      final targetComparison = version['targetComparison'];
      if (!validTargetComparisons.contains(targetComparison)) {
        return 'GoalVersion "$id" has an unsupported targetComparison: '
            '"$targetComparison".';
      }
      final trackingType = version['trackingType'];
      if (!validTrackingTypes.contains(trackingType)) {
        return 'GoalVersion "$id" has an unsupported trackingType: '
            '"$trackingType".';
      }
    }
    return null;
  }
}
