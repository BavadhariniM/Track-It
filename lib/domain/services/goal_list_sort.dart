import '../entities/goal.dart';
import '../entities/rule_values.dart';

/// Story 3.5 AC 4: the Goals list's group order — Daily, Weekly, Biweekly,
/// Monthly, Quarterly, Yearly, then Rolling Window and Custom last as one
/// combined final group. No `Priority` field is stored anywhere (explicitly
/// ruled out by AC 4) — [_periodRank] and [sortGoalsByEvaluationPeriod] are
/// the entire mechanism, a presentation-layer computed sort over
/// already-loaded goal data.
const _periodOrder = [
  EvaluationPeriod.daily,
  EvaluationPeriod.weekly,
  EvaluationPeriod.biweekly,
  EvaluationPeriod.monthly,
  EvaluationPeriod.quarterly,
  EvaluationPeriod.yearly,
];

/// Rolling Window (`EvaluationPeriod.isRollingWindow`) and `custom` both
/// fall through to this shared final rank (AC 4: "treat them as a combined
/// final group").
int _periodRank(String evaluationPeriod) {
  final index = _periodOrder.indexOf(evaluationPeriod);
  return index == -1 ? _periodOrder.length : index;
}

/// Sorts [goals] by [evaluationPeriodOf]'s Evaluation Period group (AC 4's
/// fixed order), then alphabetically (case-insensitive) by name within each
/// group (Subtask 4.2). [evaluationPeriodOf] should read each goal's
/// current/active `GoalVersion.evaluationPeriod` (Subtask 4.4) — a goal with
/// no resolvable Version (an empty/unrecognized string) sorts into the same
/// final group as Rolling Window/Custom.
List<Goal> sortGoalsByEvaluationPeriod(
  List<Goal> goals,
  String Function(String goalId) evaluationPeriodOf,
) {
  final sorted = [...goals];
  sorted.sort((a, b) {
    final rankA = _periodRank(evaluationPeriodOf(a.id));
    final rankB = _periodRank(evaluationPeriodOf(b.id));
    if (rankA != rankB) return rankA.compareTo(rankB);
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return sorted;
}
