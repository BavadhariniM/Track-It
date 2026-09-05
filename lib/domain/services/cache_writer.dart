import '../entities/day_status.dart';

/// Domain-defined, Drift-agnostic abstraction for the read-optimization
/// status cache (AD-7): a single writer, fully re-derivable from `evaluate()`
/// at any time. Implemented by `DriftCacheWriter` in `data/cache/` (AD-1) —
/// no concrete Drift code lives here.
///
/// [GoalService] is the only caller of [writeStatus] (Story 3.1 Subtask 2.3/
/// 2.4): after any `GoalLog`/`GoalVersion` commit, it calls `evaluate()`
/// itself and hands the resulting [DayStatus] here to be persisted, inside
/// the same transaction as the write that produced it.
abstract interface class CacheWriter {
  /// Upserts [status] into the cache by `(goalId, date)`.
  Future<void> writeStatus(DayStatus status);

  /// Wholesale-recomputes the entire cache from scratch by calling
  /// `evaluate()` fresh for every Goal/date combination — the concrete proof
  /// of AD-7's "fully re-derivable" guarantee, and the recovery path if the
  /// cache is ever found empty or corrupted (AC 5).
  Future<void> rebuildAll();

  /// Story 6.3's Reset/Erase-All (FR-36): wipes every cached row outright,
  /// called only by `GoalService.resetAll()`. Distinct from [rebuildAll] —
  /// that recomputes every row from existing Goal/Version/Log data, which
  /// after a full wipe would just be a no-op loop over zero Goals and leave
  /// every stale cached row behind.
  Future<void> clearAll();
}
