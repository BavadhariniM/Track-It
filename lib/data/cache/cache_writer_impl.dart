import '../../domain/entities/day_status.dart';
import '../../domain/evaluator/evaluate.dart';
import '../../domain/services/blackout_date_repository.dart';
import '../../domain/services/cache_writer.dart';
import '../../domain/services/cheat_day_repository.dart';
import '../../domain/services/goal_log_repository.dart';
import '../../domain/services/goal_repository.dart';
import '../../domain/services/goal_version_repository.dart';
import '../../domain/services/status_cache_repository.dart';

/// The single [CacheWriter] implementation (AD-7 mandates exactly one writer)
/// — a thin Drift-backed adapter over [StatusCacheRepository] for
/// [writeStatus], plus the recovery/proof entry point [rebuildAll] that
/// re-derives every cached row from scratch by calling `evaluate()` (AD-4).
class DriftCacheWriter implements CacheWriter {
  DriftCacheWriter({
    required GoalRepository goalRepository,
    required GoalVersionRepository goalVersionRepository,
    required GoalLogRepository goalLogRepository,
    required BlackoutDateRepository blackoutDateRepository,
    required CheatDayRepository cheatDayRepository,
    required StatusCacheRepository statusCacheRepository,
  }) : _goalRepository = goalRepository,
       _goalVersionRepository = goalVersionRepository,
       _goalLogRepository = goalLogRepository,
       _blackoutDateRepository = blackoutDateRepository,
       _cheatDayRepository = cheatDayRepository,
       _statusCacheRepository = statusCacheRepository;

  final GoalRepository _goalRepository;
  final GoalVersionRepository _goalVersionRepository;
  final GoalLogRepository _goalLogRepository;
  final BlackoutDateRepository _blackoutDateRepository;
  final CheatDayRepository _cheatDayRepository;
  final StatusCacheRepository _statusCacheRepository;

  @override
  Future<void> writeStatus(DayStatus status) {
    return _statusCacheRepository.upsertStatus(status);
  }

  @override
  Future<void> rebuildAll() async {
    final goals = await _goalRepository.watchAllGoals().first;
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    for (final goal in goals) {
      final versions = await _goalVersionRepository.findAllForGoal(goal.id);
      final logs = await _goalLogRepository.findAllForGoal(goal.id);
      final blackoutDates = await _blackoutDateRepository.findAllForGoal(
        goal.id,
      );
      final cheatDays = await _cheatDayRepository.findAllForGoal(goal.id);

      var cursor = DateTime.parse(goal.startDate);
      while (!cursor.isAfter(todayDateOnly)) {
        final status = evaluate(
          goal: goal,
          versions: versions,
          logs: logs,
          blackoutDates: blackoutDates,
          cheatDays: cheatDays,
          date: cursor,
          today: todayDateOnly,
        );
        await _statusCacheRepository.upsertStatus(status);
        cursor = cursor.add(const Duration(days: 1));
      }
    }
  }

  @override
  Future<void> clearAll() => _statusCacheRepository.deleteAll();
}
