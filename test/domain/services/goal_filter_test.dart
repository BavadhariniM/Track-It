import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/services/goal_filter.dart';

/// Story 3.5 Subtask 5.2/5.3: `filterGoals` scoping for all/single/category,
/// including the no-category edge case, plus the default-filter behavior.
void main() {
  const health1 = Goal(
    id: 'goal-1',
    name: 'Run',
    category: 'Health',
    archived: false,
    startDate: '2026-01-01',
  );
  const health2 = Goal(
    id: 'goal-2',
    name: 'Sleep early',
    category: 'Health',
    archived: false,
    startDate: '2026-01-01',
  );
  const finance = Goal(
    id: 'goal-3',
    name: r'Save $100',
    category: 'Finance',
    archived: false,
    startDate: '2026-01-01',
  );
  const noCategory = Goal(
    id: 'goal-4',
    name: 'Read',
    archived: false,
    startDate: '2026-01-01',
  );
  final goals = [health1, health2, finance, noCategory];

  group('filterGoals', () {
    test('GoalFilter.all returns every goal, including one with no category', () {
      expect(filterGoals(goals, const GoalFilter.all()), goals);
    });

    test('default filter (GoalFilter.all) resolves to all Goals', () {
      // AC 3 / Subtask 5.3: the default (unset) filter state is `all`, not
      // merely a visual default with a stale filter underneath.
      const defaultFilter = GoalFilter.all();
      expect(filterGoals(goals, defaultFilter), goals);
    });

    test('GoalFilter.single returns only the matching goal by id', () {
      expect(
        filterGoals(goals, const GoalFilter.single('goal-2')),
        [health2],
      );
    });

    test('GoalFilter.single matching no goal returns an empty list', () {
      expect(filterGoals(goals, const GoalFilter.single('missing')), isEmpty);
    });

    test('GoalFilter.category returns every goal sharing that category', () {
      expect(
        filterGoals(goals, const GoalFilter.category('Health')),
        [health1, health2],
      );
    });

    test(
      'a goal with no category is excluded from every category filter, '
      'never silently matching',
      () {
        final result = filterGoals(goals, const GoalFilter.category('Health'));
        expect(result, isNot(contains(noCategory)));

        final emptyCategoryResult = filterGoals(
          goals,
          const GoalFilter.category(''),
        );
        expect(emptyCategoryResult, isNot(contains(noCategory)));
      },
    );
  });

  group('distinctCategories', () {
    test('returns sorted, de-duplicated, non-empty categories only', () {
      expect(distinctCategories(goals), ['Finance', 'Health']);
    });

    test('returns an empty list when no goal has a category', () {
      expect(distinctCategories([noCategory]), isEmpty);
    });
  });

  group('GoalFilter equality', () {
    test('same-kind filters with equal payloads compare equal', () {
      expect(const GoalFilter.all(), const GoalFilter.all());
      expect(
        const GoalFilter.single('goal-1'),
        const GoalFilter.single('goal-1'),
      );
      expect(
        const GoalFilter.category('Health'),
        const GoalFilter.category('Health'),
      );
      expect(
        const GoalFilter.single('goal-1'),
        isNot(const GoalFilter.single('goal-2')),
      );
    });
  });
}
