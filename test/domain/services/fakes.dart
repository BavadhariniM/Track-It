import 'dart:async';

import 'package:tracker/domain/entities/blackout_date.dart';
import 'package:tracker/domain/entities/cheat_day.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/evaluator/evaluate.dart';
import 'package:tracker/domain/services/blackout_date_repository.dart';
import 'package:tracker/domain/services/cache_writer.dart';
import 'package:tracker/domain/services/cheat_day_repository.dart';
import 'package:tracker/domain/services/goal_log_repository.dart';
import 'package:tracker/domain/services/goal_repository.dart';
import 'package:tracker/domain/services/goal_version_repository.dart';
import 'package:tracker/domain/services/status_cache_repository.dart';
import 'package:tracker/domain/services/transaction_runner.dart';
import 'package:tracker/domain/services/widget_bridge_writer.dart';

/// In-memory store shared by the fake repositories below, so a single
/// [SnapshotTransactionRunner] can snapshot/restore all three tables
/// together — modeling the same all-or-nothing guarantee a real Drift
/// transaction provides, without needing a real database in unit tests.
///
/// Every mutation notifies [_changes] so `watch*` streams below stay live —
/// unlike a plain `Stream.value(...)`, which only emits once and would
/// never reflect a later insert, real Drift `.watch()` streams re-emit on
/// every change to the watched table, so the fakes must too.
class InMemoryStore {
  final List<Goal> goals = [];
  final List<GoalVersion> versions = [];
  final List<GoalLog> logs = [];
  final List<BlackoutDate> blackoutDates = [];
  final List<CheatDay> cheatDays = [];

  /// Keyed by `'goalId|date'` — Story 3.1's `status_cache` table analogue.
  final Map<String, DayStatus> statusCache = {};

  final _changes = StreamController<void>.broadcast();

  void _notify() => _changes.add(null);

  Stream<List<Goal>> watchGoals() async* {
    yield List.of(goals);
    yield* _changes.stream.map((_) => List.of(goals));
  }

  Stream<List<GoalVersion>> watchVersions(String goalId) async* {
    yield versions.where((v) => v.goalId == goalId).toList();
    yield* _changes.stream.map(
      (_) => versions.where((v) => v.goalId == goalId).toList(),
    );
  }

  Stream<List<GoalLog>> watchLogs(String goalId) async* {
    yield logs.where((l) => l.goalId == goalId).toList();
    yield* _changes.stream.map(
      (_) => logs.where((l) => l.goalId == goalId).toList(),
    );
  }

  Stream<List<BlackoutDate>> watchBlackoutDates(String goalId) async* {
    yield blackoutDates.where((b) => b.goalId == goalId).toList();
    yield* _changes.stream.map(
      (_) => blackoutDates.where((b) => b.goalId == goalId).toList(),
    );
  }

  Stream<List<CheatDay>> watchCheatDays(String goalId) async* {
    yield cheatDays.where((c) => c.goalId == goalId).toList();
    yield* _changes.stream.map(
      (_) => cheatDays.where((c) => c.goalId == goalId).toList(),
    );
  }

  ({
    List<Goal> goals,
    List<GoalVersion> versions,
    List<GoalLog> logs,
    List<BlackoutDate> blackoutDates,
    List<CheatDay> cheatDays,
    Map<String, DayStatus> statusCache,
  })
  snapshot() {
    return (
      goals: List.of(goals),
      versions: List.of(versions),
      logs: List.of(logs),
      blackoutDates: List.of(blackoutDates),
      cheatDays: List.of(cheatDays),
      statusCache: Map.of(statusCache),
    );
  }

  void restore(
    ({
      List<Goal> goals,
      List<GoalVersion> versions,
      List<GoalLog> logs,
      List<BlackoutDate> blackoutDates,
      List<CheatDay> cheatDays,
      Map<String, DayStatus> statusCache,
    })
    snapshot,
  ) {
    goals
      ..clear()
      ..addAll(snapshot.goals);
    versions
      ..clear()
      ..addAll(snapshot.versions);
    logs
      ..clear()
      ..addAll(snapshot.logs);
    blackoutDates
      ..clear()
      ..addAll(snapshot.blackoutDates);
    cheatDays
      ..clear()
      ..addAll(snapshot.cheatDays);
    statusCache
      ..clear()
      ..addAll(snapshot.statusCache);
    _notify();
  }
}

/// Rolls back the in-memory store to its pre-transaction snapshot if
/// [action] throws, otherwise keeps the mutations — the same
/// all-or-nothing behavior FR-19/NFR-7 require from a real Drift
/// transaction (a kill mid-save loses at most the in-flight write).
class SnapshotTransactionRunner implements TransactionRunner {
  SnapshotTransactionRunner(this._store);

  final InMemoryStore _store;

  @override
  Future<T> run<T>(Future<T> Function() action) async {
    final snapshot = _store.snapshot();
    try {
      return await action();
    } catch (_) {
      _store.restore(snapshot);
      rethrow;
    }
  }
}

class InMemoryGoalRepository implements GoalRepository {
  InMemoryGoalRepository(this._store);

  final InMemoryStore _store;

  /// When set, [updateGoal] throws instead of writing — simulates a
  /// process kill partway through `GoalService.archiveGoal`'s transaction
  /// (Story 2.3).
  bool shouldFailOnUpdate = false;

  /// When set, [deleteAll] throws instead of writing — simulates a process
  /// kill on the very last step of `GoalService.resetAll`'s transaction
  /// (Story 6.3 Subtask 4.3), so a test can confirm every other table's
  /// deletion was rolled back too, not just this one.
  bool shouldFailOnDeleteAll = false;

  @override
  Future<void> insertGoal(Goal goal) async {
    _store.goals.add(goal);
    _store._notify();
  }

  @override
  Future<void> upsertGoal(Goal goal) async {
    final index = _store.goals.indexWhere((g) => g.id == goal.id);
    if (index == -1) {
      _store.goals.add(goal);
    } else {
      _store.goals[index] = goal;
    }
    _store._notify();
  }

  @override
  Future<Goal?> findById(String goalId) async {
    for (final goal in _store.goals) {
      if (goal.id == goalId) return goal;
    }
    return null;
  }

  @override
  Future<void> updateGoal(Goal goal) async {
    if (shouldFailOnUpdate) {
      throw StateError('simulated crash before commit');
    }
    final index = _store.goals.indexWhere((g) => g.id == goal.id);
    if (index == -1) {
      throw StateError('updateGoal: no existing row with id ${goal.id}');
    }
    _store.goals[index] = goal;
    _store._notify();
  }

  @override
  Stream<List<Goal>> watchAllGoals() => _store.watchGoals();

  @override
  Future<void> deleteAll() async {
    if (shouldFailOnDeleteAll) {
      throw StateError('simulated crash before commit');
    }
    _store.goals.clear();
    _store._notify();
  }
}

class InMemoryGoalVersionRepository implements GoalVersionRepository {
  InMemoryGoalVersionRepository(this._store);

  final InMemoryStore _store;

  /// When set, [insertVersion] throws instead of writing — simulates a
  /// process kill partway through a multi-statement transaction.
  bool shouldFailOnInsert = false;

  /// When set, [updateVersion] throws instead of writing — simulates a
  /// process kill partway through Story 2.1's UPDATE-in-place branch.
  bool shouldFailOnUpdate = false;

  @override
  Future<void> insertVersion(GoalVersion version) async {
    if (shouldFailOnInsert) {
      throw StateError('simulated crash before commit');
    }
    _store.versions.add(version);
    _store._notify();
  }

  @override
  Future<void> updateVersion(GoalVersion version) async {
    if (shouldFailOnUpdate) {
      throw StateError('simulated crash before commit');
    }
    final index = _store.versions.indexWhere((v) => v.id == version.id);
    if (index == -1) {
      throw StateError('updateVersion: no existing row with id ${version.id}');
    }
    _store.versions[index] = version;
    _store._notify();
  }

  @override
  Future<void> upsertVersion(GoalVersion version) async {
    final index = _store.versions.indexWhere((v) => v.id == version.id);
    if (index == -1) {
      _store.versions.add(version);
    } else {
      _store.versions[index] = version;
    }
    _store._notify();
  }

  @override
  Future<GoalVersion?> findByGoalIdAndStartDate(
    String goalId,
    String versionStartDate,
  ) async {
    for (final version in _store.versions) {
      if (version.goalId == goalId &&
          version.versionStartDate == versionStartDate) {
        return version;
      }
    }
    return null;
  }

  @override
  Future<GoalVersion?> findGoverningVersion(String goalId, String date) async {
    GoalVersion? governing;
    for (final version in _store.versions.where((v) => v.goalId == goalId)) {
      if (version.versionStartDate.compareTo(date) > 0) continue;
      if (governing == null ||
          version.versionStartDate.compareTo(governing.versionStartDate) > 0) {
        governing = version;
      }
    }
    return governing;
  }

  @override
  Future<List<GoalVersion>> findAllForGoal(String goalId) async {
    return _store.versions.where((v) => v.goalId == goalId).toList();
  }

  @override
  Stream<List<GoalVersion>> watchVersionsForGoal(String goalId) {
    return _store.watchVersions(goalId);
  }

  @override
  Future<void> deleteAll() async {
    _store.versions.clear();
    _store._notify();
  }
}

class InMemoryGoalLogRepository implements GoalLogRepository {
  InMemoryGoalLogRepository(this._store);

  final InMemoryStore _store;

  /// When set, [upsertLog] throws instead of writing — simulates a process
  /// kill partway through `GoalService.logCounter`'s read-modify-upsert
  /// transaction (Story 1.11 Subtask 5.3).
  bool shouldFailOnUpsert = false;

  @override
  Future<void> insertLog(GoalLog log) async {
    _store.logs.add(log);
    _store._notify();
  }

  @override
  Future<void> upsertLog(GoalLog log) async {
    if (shouldFailOnUpsert) {
      throw StateError('simulated crash before commit');
    }
    final index = _store.logs.indexWhere((l) => l.id == log.id);
    if (index == -1) {
      _store.logs.add(log);
    } else {
      _store.logs[index] = log;
    }
    _store._notify();
  }

  @override
  Future<GoalLog?> getLogForDate(String goalId, String date) async {
    for (final log in _store.logs) {
      if (log.goalId == goalId && log.date == date) return log;
    }
    return null;
  }

  @override
  Future<bool> existsOnOrAfter(String goalId, String date) async {
    return _store.logs.any(
      (log) => log.goalId == goalId && log.date.compareTo(date) >= 0,
    );
  }

  @override
  Future<List<GoalLog>> findAllForGoal(String goalId) async {
    return _store.logs.where((l) => l.goalId == goalId).toList();
  }

  @override
  Stream<List<GoalLog>> watchLogsForGoal(String goalId) {
    return _store.watchLogs(goalId);
  }

  @override
  Future<void> deleteAll() async {
    _store.logs.clear();
    _store._notify();
  }

  @override
  Future<void> deleteLog(String id) async {
    _store.logs.removeWhere((l) => l.id == id);
    _store._notify();
  }
}

class InMemoryBlackoutDateRepository implements BlackoutDateRepository {
  InMemoryBlackoutDateRepository(this._store);

  final InMemoryStore _store;

  /// When set, [insertBlackoutDate] throws instead of writing — simulates
  /// a process kill partway through `GoalService.markBlackoutDate`'s
  /// transaction (Story 1.11 Subtask 5.3).
  bool shouldFailOnInsert = false;

  @override
  Future<void> insertBlackoutDate(BlackoutDate blackoutDate) async {
    if (shouldFailOnInsert) {
      throw StateError('simulated crash before commit');
    }
    _store.blackoutDates.add(blackoutDate);
    _store._notify();
  }

  @override
  Future<void> upsertBlackoutDate(BlackoutDate blackoutDate) async {
    final index = _store.blackoutDates.indexWhere(
      (b) => b.id == blackoutDate.id,
    );
    if (index == -1) {
      _store.blackoutDates.add(blackoutDate);
    } else {
      _store.blackoutDates[index] = blackoutDate;
    }
    _store._notify();
  }

  @override
  Future<List<BlackoutDate>> findAllForGoal(String goalId) async {
    return _store.blackoutDates.where((b) => b.goalId == goalId).toList();
  }

  @override
  Stream<List<BlackoutDate>> watchBlackoutDatesForGoal(String goalId) {
    return _store.watchBlackoutDates(goalId);
  }

  @override
  Future<void> deleteAll() async {
    _store.blackoutDates.clear();
    _store._notify();
  }
}

class InMemoryCheatDayRepository implements CheatDayRepository {
  InMemoryCheatDayRepository(this._store);

  final InMemoryStore _store;

  /// When set, [insertCheatDay] throws instead of writing — simulates a
  /// process kill partway through `GoalService.markCheatDay`'s transaction
  /// (Story 2.4).
  bool shouldFailOnInsert = false;

  @override
  Future<void> insertCheatDay(CheatDay cheatDay) async {
    if (shouldFailOnInsert) {
      throw StateError('simulated crash before commit');
    }
    _store.cheatDays.add(cheatDay);
    _store._notify();
  }

  @override
  Future<void> upsertCheatDay(CheatDay cheatDay) async {
    final index = _store.cheatDays.indexWhere((c) => c.id == cheatDay.id);
    if (index == -1) {
      _store.cheatDays.add(cheatDay);
    } else {
      _store.cheatDays[index] = cheatDay;
    }
    _store._notify();
  }

  @override
  Future<List<CheatDay>> findByGoalIdInRange(
    String goalId,
    String startDate,
    String endDate,
  ) async {
    return _store.cheatDays
        .where(
          (c) =>
              c.goalId == goalId &&
              c.date.compareTo(startDate) >= 0 &&
              c.date.compareTo(endDate) <= 0,
        )
        .toList();
  }

  @override
  Future<List<CheatDay>> findAllForGoal(String goalId) async {
    return _store.cheatDays.where((c) => c.goalId == goalId).toList();
  }

  @override
  Stream<List<CheatDay>> watchCheatDaysForGoal(String goalId) {
    return _store.watchCheatDays(goalId);
  }

  @override
  Future<void> deleteAll() async {
    _store.cheatDays.clear();
    _store._notify();
  }
}

String _cacheKey(String goalId, String date) => '$goalId|$date';

class InMemoryStatusCacheRepository implements StatusCacheRepository {
  InMemoryStatusCacheRepository(this._store);

  final InMemoryStore _store;

  @override
  Future<DayStatus?> getStatus(String goalId, String date) async {
    return _store.statusCache[_cacheKey(goalId, date)];
  }

  @override
  Future<void> upsertStatus(DayStatus status) async {
    _store.statusCache[_cacheKey(status.goalId, status.date)] = status;
  }

  @override
  Future<void> deleteAll() async {
    _store.statusCache.clear();
  }
}

/// Story 3.1 Subtask 5.2's `CacheWriter`/`DriftCacheWriter` fake — mirrors
/// `DriftCacheWriter`'s behavior over the in-memory store instead of Drift.
class InMemoryCacheWriter implements CacheWriter {
  InMemoryCacheWriter(this._store);

  final InMemoryStore _store;

  @override
  Future<void> writeStatus(DayStatus status) async {
    _store.statusCache[_cacheKey(status.goalId, status.date)] = status;
  }

  @override
  Future<void> rebuildAll() async {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    for (final goal in _store.goals) {
      final versions = _store.versions
          .where((v) => v.goalId == goal.id)
          .toList();
      final logs = _store.logs.where((l) => l.goalId == goal.id).toList();
      final blackoutDates = _store.blackoutDates
          .where((b) => b.goalId == goal.id)
          .toList();
      final cheatDays = _store.cheatDays
          .where((c) => c.goalId == goal.id)
          .toList();

      var cursor = DateTime.parse(goal.startDate);
      while (!cursor.isAfter(todayDateOnly)) {
        final status = evaluate(
          goal: goal,
          versions: versions,
          logs: logs,
          blackoutDates: blackoutDates,
          cheatDays: cheatDays,
          date: cursor,
        );
        _store.statusCache[_cacheKey(status.goalId, status.date)] = status;
        cursor = cursor.add(const Duration(days: 1));
      }
    }
  }

  @override
  Future<void> clearAll() async {
    _store.statusCache.clear();
  }
}

/// Story 5.1's [WidgetBridgeWriter] fake for `GoalService`-level tests that
/// don't care about the widget bridge itself (every suite predating Story
/// 5.1) — records each call rather than touching a real `home_widget`
/// platform channel, which isn't mocked in these suites.
class InMemoryWidgetBridgeWriter implements WidgetBridgeWriter {
  final List<DateTime> writeAllCalls = [];

  @override
  Future<void> writeAll(DateTime today) async {
    writeAllCalls.add(today);
  }
}
