import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/blackout_date.dart';
import '../../domain/entities/cheat_day.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_log.dart';
import '../../domain/entities/goal_version.dart';
import '../../domain/services/goal_filter.dart';
import 'goal_filter_provider.dart';
import 'repository_providers.dart';

part 'goal_data_providers.g.dart';

/// The reactive data `evaluate()` needs. Day View watches [allGoals], and
/// for each goal watches [goalVersions]/[goalLogs] to call the domain's
/// pure `evaluate()` function itself — this story does not introduce a
/// second evaluation path, only the data plumbing evaluate() consumes.

@riverpod
Stream<List<Goal>> allGoals(Ref ref) {
  return ref.watch(goalRepositoryProvider).watchAllGoals();
}

/// Story 3.5 Subtask 2.1/2.3: [allGoals] scoped by the Calendar's current
/// [GoalFilter] — the exact list of goals the Day/Week/Month calendar's
/// existing `evaluate()` loop iterates over. Filtering only changes which
/// goals are in this list; it is never a second read path, never a cache
/// lookup (AD-7 stays untouched), and [allGoals]'s own loading/error states
/// pass straight through.
@riverpod
AsyncValue<List<Goal>> filteredGoals(Ref ref) {
  final filter = ref.watch(selectedGoalFilterProvider);
  return ref.watch(allGoalsProvider).whenData(
    (goals) => filterGoals(goals, filter),
  );
}

@riverpod
Stream<List<GoalVersion>> goalVersions(Ref ref, String goalId) {
  return ref.watch(goalVersionRepositoryProvider).watchVersionsForGoal(goalId);
}

@riverpod
Stream<List<GoalLog>> goalLogs(Ref ref, String goalId) {
  return ref.watch(goalLogRepositoryProvider).watchLogsForGoal(goalId);
}

@riverpod
Stream<List<BlackoutDate>> blackoutDates(Ref ref, String goalId) {
  return ref
      .watch(blackoutDateRepositoryProvider)
      .watchBlackoutDatesForGoal(goalId);
}

@riverpod
Stream<List<CheatDay>> cheatDays(Ref ref, String goalId) {
  return ref.watch(cheatDayRepositoryProvider).watchCheatDaysForGoal(goalId);
}
