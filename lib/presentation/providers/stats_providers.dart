import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/day_status.dart';
import '../../domain/services/stats_service.dart';
import 'current_date_provider.dart';
import 'goal_data_providers.dart';
import 'repository_providers.dart';
import 'week_start_provider.dart';

part 'stats_providers.g.dart';

@Riverpod(keepAlive: true)
StatsService statsService(Ref ref) {
  return StatsService(
    goalRepository: ref.watch(goalRepositoryProvider),
    goalVersionRepository: ref.watch(goalVersionRepositoryProvider),
    goalLogRepository: ref.watch(goalLogRepositoryProvider),
    blackoutDateRepository: ref.watch(blackoutDateRepositoryProvider),
    cheatDayRepository: ref.watch(cheatDayRepositoryProvider),
    statusCacheRepository: ref.watch(statusCacheRepositoryProvider),
    weekStart: ref.watch(weekStartSettingProvider),
  );
}

/// Watches every goal's Version/Log streams so this provider (and the
/// widgets watching it) rebuild whenever a write changes them, without the
/// widget layer ever calling `evaluate()` itself (AD-7) — the actual status
/// computation always goes through [StatsService], which is cache-first with
/// an `evaluate()` fallback (AD-8).
Future<void> _watchAllGoalData(Ref ref) async {
  final goals = await ref.watch(allGoalsProvider.future);
  for (final goal in goals) {
    ref.watch(goalVersionsProvider(goal.id));
    ref.watch(goalLogsProvider(goal.id));
  }
}

@riverpod
Future<List<GoalStatus>> todayProgress(Ref ref) async {
  await _watchAllGoalData(ref);
  final today = ref.watch(currentDateProvider).value ?? DateTime.now();
  return ref.watch(statsServiceProvider).todayProgress(today);
}

@riverpod
Future<List<GoalStatus>> weekRollup(Ref ref) async {
  await _watchAllGoalData(ref);
  final today = ref.watch(currentDateProvider).value ?? DateTime.now();
  return ref.watch(statsServiceProvider).weekRollup(today);
}

@riverpod
Future<List<GoalStatus>> monthRollup(Ref ref) async {
  await _watchAllGoalData(ref);
  final today = ref.watch(currentDateProvider).value ?? DateTime.now();
  return ref.watch(statsServiceProvider).monthRollup(today);
}

@riverpod
Future<int?> currentStreak(Ref ref, String goalId) async {
  ref.watch(goalVersionsProvider(goalId));
  ref.watch(goalLogsProvider(goalId));
  return ref.watch(statsServiceProvider).currentStreak(goalId);
}

/// Story 3.2 AC 1: Goal Detail's bundled current/longest streak + completion
/// percentage — always the same [StatsService.goalStats] call, never a
/// second computation (AD-8).
@riverpod
Future<GoalStats> goalStats(Ref ref, String goalId) async {
  ref.watch(goalVersionsProvider(goalId));
  ref.watch(goalLogsProvider(goalId));
  return ref.watch(statsServiceProvider).goalStats(goalId);
}

/// Story 3.2 Subtask 2.1: the Goal Detail historical calendar's data source.
@riverpod
Future<List<DayStatus>> historicalStatuses(Ref ref, String goalId) async {
  ref.watch(goalVersionsProvider(goalId));
  ref.watch(goalLogsProvider(goalId));
  return ref.watch(statsServiceProvider).historicalStatuses(goalId);
}
