import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/cache/cache_writer_impl.dart';
import '../../data/repositories/drift_blackout_date_repository.dart';
import '../../data/repositories/drift_cheat_day_repository.dart';
import '../../data/repositories/drift_goal_log_repository.dart';
import '../../data/repositories/drift_goal_repository.dart';
import '../../data/repositories/drift_goal_version_repository.dart';
import '../../data/repositories/drift_status_cache_repository.dart';
import '../../data/repositories/drift_transaction_runner.dart';
import '../../domain/services/blackout_date_repository.dart';
import '../../domain/services/cache_writer.dart';
import '../../domain/services/cheat_day_repository.dart';
import '../../domain/services/goal_log_repository.dart';
import '../../domain/services/goal_repository.dart';
import '../../domain/services/goal_version_repository.dart';
import '../../domain/services/status_cache_repository.dart';
import '../../domain/services/transaction_runner.dart';
import 'database_provider.dart';

part 'repository_providers.g.dart';

/// This is the composition root (AD-1): the only place that binds a
/// domain-defined interface to its concrete `data`-layer implementation.

@Riverpod(keepAlive: true)
GoalRepository goalRepository(Ref ref) {
  return DriftGoalRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
GoalVersionRepository goalVersionRepository(Ref ref) {
  return DriftGoalVersionRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
GoalLogRepository goalLogRepository(Ref ref) {
  return DriftGoalLogRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
BlackoutDateRepository blackoutDateRepository(Ref ref) {
  return DriftBlackoutDateRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
CheatDayRepository cheatDayRepository(Ref ref) {
  return DriftCheatDayRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
TransactionRunner transactionRunner(Ref ref) {
  return DriftTransactionRunner(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
StatusCacheRepository statusCacheRepository(Ref ref) {
  return DriftStatusCacheRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
CacheWriter cacheWriter(Ref ref) {
  return DriftCacheWriter(
    goalRepository: ref.watch(goalRepositoryProvider),
    goalVersionRepository: ref.watch(goalVersionRepositoryProvider),
    goalLogRepository: ref.watch(goalLogRepositoryProvider),
    blackoutDateRepository: ref.watch(blackoutDateRepositoryProvider),
    cheatDayRepository: ref.watch(cheatDayRepositoryProvider),
    statusCacheRepository: ref.watch(statusCacheRepositoryProvider),
  );
}
