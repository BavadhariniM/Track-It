import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/services/goal_list_sort.dart';

/// Story 3.5 AC 4/Subtask 5.4: the Goals list's computed sort — grouped by
/// Evaluation Period frequency (Daily...Yearly, then Rolling Window/Custom
/// last), alphabetical by name within each group — covering every
/// Evaluation Period type Epic 1 Story 1.3 built, not just Daily/Weekly.
void main() {
  Goal goalNamed(String id, String name) =>
      Goal(id: id, name: name, archived: false, startDate: '2026-01-01');

  test(
    'produces the exact documented group order with a mixed fixture set '
    'covering every Evaluation Period type',
    () {
      final zebra = goalNamed('daily-z', 'Zebra Daily');
      final apple = goalNamed('daily-a', 'Apple Daily');
      final weekly = goalNamed('weekly', 'Weekly Goal');
      final biweekly = goalNamed('biweekly', 'Biweekly Goal');
      final monthly = goalNamed('monthly', 'Monthly Goal');
      final quarterly = goalNamed('quarterly', 'Quarterly Goal');
      final yearly = goalNamed('yearly', 'Yearly Goal');
      final rolling = goalNamed('rolling', 'Rolling Goal');
      final custom = goalNamed('custom', 'Custom Goal');

      final goals = [
        rolling,
        yearly,
        zebra,
        custom,
        quarterly,
        apple,
        monthly,
        biweekly,
        weekly,
      ];

      final periods = {
        zebra.id: EvaluationPeriod.daily,
        apple.id: EvaluationPeriod.daily,
        weekly.id: EvaluationPeriod.weekly,
        biweekly.id: EvaluationPeriod.biweekly,
        monthly.id: EvaluationPeriod.monthly,
        quarterly.id: EvaluationPeriod.quarterly,
        yearly.id: EvaluationPeriod.yearly,
        rolling.id: EvaluationPeriod.rollingWindow(14),
        custom.id: EvaluationPeriod.custom,
      };

      final sorted = sortGoalsByEvaluationPeriod(
        goals,
        (goalId) => periods[goalId]!,
      );

      expect(sorted, [
        apple,
        zebra,
        weekly,
        biweekly,
        monthly,
        quarterly,
        yearly,
        custom,
        rolling,
      ]);
    },
  );

  test('sorts alphabetically case-insensitively within a group', () {
    final lower = goalNamed('a', 'banana');
    final upper = goalNamed('b', 'Apple');
    final sorted = sortGoalsByEvaluationPeriod(
      [lower, upper],
      (_) => EvaluationPeriod.daily,
    );
    expect(sorted, [upper, lower]);
  });

  test(
    'a goal with no resolvable Version (empty period string) sorts into '
    'the same final group as Rolling Window/Custom',
    () {
      final unresolved = goalNamed('none', 'Mystery Goal');
      final daily = goalNamed('daily', 'Daily Goal');
      final sorted = sortGoalsByEvaluationPeriod(
        [unresolved, daily],
        (goalId) => goalId == 'daily' ? EvaluationPeriod.daily : '',
      );
      expect(sorted, [daily, unresolved]);
    },
  );
}
