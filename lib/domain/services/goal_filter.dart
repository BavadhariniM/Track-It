import '../entities/goal.dart';

/// Story 3.5 AC 1/3: which goals the Calendar (Day/Week/Month) evaluates and
/// displays — "all Goals," a single Goal, or an entire category. A pure
/// scoping value, never persisted; [GoalFilter.all] is the default (AC 3).
/// Filtering never changes *how* a goal is evaluated (AD-7's live
/// calendar/cache split is untouched) — only which goals from the
/// already-loaded list are passed into the existing `evaluate()` loop.
sealed class GoalFilter {
  const GoalFilter();

  const factory GoalFilter.all() = GoalFilterAll;

  const factory GoalFilter.single(String goalId) = GoalFilterSingle;

  const factory GoalFilter.category(String category) = GoalFilterCategory;
}

final class GoalFilterAll extends GoalFilter {
  const GoalFilterAll();

  @override
  bool operator ==(Object other) => other is GoalFilterAll;

  @override
  int get hashCode => (GoalFilterAll).hashCode;
}

final class GoalFilterSingle extends GoalFilter {
  const GoalFilterSingle(this.goalId);

  final String goalId;

  @override
  bool operator ==(Object other) =>
      other is GoalFilterSingle && other.goalId == goalId;

  @override
  int get hashCode => Object.hash(GoalFilterSingle, goalId);
}

final class GoalFilterCategory extends GoalFilter {
  const GoalFilterCategory(this.category);

  final String category;

  @override
  bool operator ==(Object other) =>
      other is GoalFilterCategory && other.category == category;

  @override
  int get hashCode => Object.hash(GoalFilterCategory, category);
}

/// Applies [filter] to [goals]. A goal with no category (`null`/empty)
/// always appears under [GoalFilter.all] and is never matched by any
/// [GoalFilterCategory] — a common edge case that must not silently match
/// every category filter (Dev Notes: "testing standards").
List<Goal> filterGoals(List<Goal> goals, GoalFilter filter) {
  return switch (filter) {
    GoalFilterAll() => goals,
    GoalFilterSingle(:final goalId) =>
      goals.where((goal) => goal.id == goalId).toList(),
    GoalFilterCategory(:final category) =>
      goals.where((goal) => goal.category == category).toList(),
  };
}

/// The distinct, non-empty categories in use across [goals], sorted
/// alphabetically (case-insensitive) — sourced from data already in use
/// rather than a separate categories table (Dev Notes: "keep it minimal").
List<String> distinctCategories(List<Goal> goals) {
  final categories = <String>{
    for (final goal in goals)
      if (goal.category != null && goal.category!.trim().isNotEmpty)
        goal.category!.trim(),
  }.toList();
  categories.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return categories;
}
