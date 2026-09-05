import '../entities/day_status.dart';

/// Domain-defined, Drift-agnostic interface over the `status_cache` table
/// (AD-7). Implemented by `DriftStatusCacheRepository` in
/// `data/repositories/` (AD-1). [CacheWriter] is the only class permitted to
/// call [upsertStatus] (AD-7's single-writer rule) — `StatsService` only
/// ever calls [getStatus].
abstract interface class StatusCacheRepository {
  /// The cached `DayStatus` for `(goalId, date)`, or `null` on a cache miss
  /// (AD-8: the goal/date combination has never been written, or the cache
  /// was cleared/corrupted) — callers fall back to `evaluate()` in that case.
  Future<DayStatus?> getStatus(String goalId, String date);

  /// Upserts [status] by `(goalId, date)` — the sole write path onto the
  /// cache table, called only by [CacheWriter] implementations.
  Future<void> upsertStatus(DayStatus status);

  /// Deletes every cached row outright — Story 6.3's Reset/Erase-All
  /// (FR-36), called only by [CacheWriter.clearAll]. Unlike [upsertStatus],
  /// this is a deliberate wipe rather than a re-derivable write: with every
  /// Goal gone, there is nothing left to recompute from (AD-7).
  Future<void> deleteAll();
}
