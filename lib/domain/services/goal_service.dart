import 'dart:async';

import 'package:uuid/uuid.dart';

import '../entities/blackout_date.dart';
import '../entities/cheat_day.dart';
import '../entities/day_status.dart';
import '../entities/goal.dart';
import '../entities/goal_log.dart';
import '../entities/goal_version.dart';
import '../entities/goal_version_draft.dart';
import '../evaluator/date_format.dart';
import '../evaluator/evaluate.dart';
import '../evaluator/period_boundary.dart';
import 'blackout_date_repository.dart';
import 'cache_writer.dart';
import 'cheat_day_repository.dart';
import 'goal_log_repository.dart';
import 'goal_repository.dart';
import 'goal_service_result.dart';
import 'goal_version_repository.dart';
import 'reminder_settings_repository.dart';
import 'result.dart';
import 'transaction_runner.dart';
import 'week_start_settings_repository.dart';
import 'widget_bridge_writer.dart';

/// The sole writer of `Goal`/`GoalVersion`/`GoalLog`/`BlackoutDate` data
/// (AD-6). No screen, provider, or repository call in `presentation` writes
/// any of these directly — every write in this story routes through here.
///
/// **`Result<T>` vs. `GoalServiceResult<T>` (Story 2.1 decision):** Epic 1's
/// use cases (`createGoal`/`logBoolean`/`logCounter`/`markBlackoutDate`)
/// keep returning the plain `Result<T>` from `result.dart` unchanged — they
/// already ship a single string-message failure and nothing about this
/// story requires touching their tested behavior. `editGoalVersion` returns
/// the newer, richer `GoalServiceResult<T>` (`goal_service_result.dart`)
/// instead, because AC 4 / UX-DR19 need the caller to *match* on a specific,
/// named failure reason (`GoalServiceFailure.versionLocked`), not just
/// display a string. The two types coexist deliberately rather than one
/// replacing the other; a future story may migrate the older methods once
/// there's a second reason to.
class GoalService {
  GoalService({
    required GoalRepository goalRepository,
    required GoalVersionRepository goalVersionRepository,
    required GoalLogRepository goalLogRepository,
    required BlackoutDateRepository blackoutDateRepository,
    required CheatDayRepository cheatDayRepository,
    required TransactionRunner transactionRunner,
    required CacheWriter cacheWriter,
    required WidgetBridgeWriter widgetBridgeWriter,
    Uuid? uuid,
  }) : _goalRepository = goalRepository,
       _goalVersionRepository = goalVersionRepository,
       _goalLogRepository = goalLogRepository,
       _blackoutDateRepository = blackoutDateRepository,
       _cheatDayRepository = cheatDayRepository,
       _transactionRunner = transactionRunner,
       _cacheWriter = cacheWriter,
       _widgetBridgeWriter = widgetBridgeWriter,
       _uuid = uuid ?? const Uuid();

  final GoalRepository _goalRepository;
  final GoalVersionRepository _goalVersionRepository;
  final GoalLogRepository _goalLogRepository;
  final BlackoutDateRepository _blackoutDateRepository;
  final CheatDayRepository _cheatDayRepository;
  final TransactionRunner _transactionRunner;
  final CacheWriter _cacheWriter;
  final WidgetBridgeWriter _widgetBridgeWriter;
  final Uuid _uuid;

  /// Story 3.1 AC 4/Subtask 2.3: recomputes and caches the single affected
  /// `(goalId, date)` `DayStatus` via `evaluate()` (AD-4) — called at the end
  /// of every `GoalLog`/`GoalVersion` write path, always from inside that
  /// write's own `_transactionRunner.run` callback, so the cache write is
  /// never a separate step outside the transaction that produced it. This is
  /// also the entire extent of Story 1.11's midnight-rollover job's own
  /// cache-write obligation (Subtask 2.4): the rollover watcher's auto-commit
  /// is just a regular call to [logCounter], which already runs this.
  Future<void> _refreshCache({
    required String goalId,
    required String date,
  }) async {
    final goal = await _goalRepository.findById(goalId);
    if (goal == null) return;
    final versions = await _goalVersionRepository.findAllForGoal(goalId);
    final logs = await _goalLogRepository.findAllForGoal(goalId);
    final blackoutDates = await _blackoutDateRepository.findAllForGoal(
      goalId,
    );
    final cheatDays = await _cheatDayRepository.findAllForGoal(goalId);
    final now = DateTime.now();
    final dayStatus = evaluate(
      goal: goal,
      versions: versions,
      logs: logs,
      blackoutDates: blackoutDates,
      cheatDays: cheatDays,
      date: DateTime.parse(date),
      today: DateTime(now.year, now.month, now.day),
    );
    await _cacheWriter.writeStatus(dayStatus);
  }

  /// Story 5.1 Task 3: fires immediately after a `GoalLog`/`GoalVersion`
  /// commit's transaction has already returned (never from inside
  /// [_transactionRunner]'s callback) — the shared widget container is
  /// platform-native storage, not a Drift table, and cannot participate in
  /// the SQL transaction that produced the cache write it serializes (Dev
  /// Notes: "Not transactional with Drift"). Best-effort: a failure here
  /// must never surface to the caller of an already-committed domain write.
  ///
  /// Callers invoke this via `unawaited(...)` rather than `await`, since Dev
  /// Notes/Task 3.3 require the bridge write to never block the
  /// already-committed domain write it follows — every public `GoalService`
  /// method returns as soon as its own transaction commits, exactly like it
  /// did before this story, with the bridge sync racing alongside rather
  /// than gating the return.
  Future<void> _syncWidgetBridge() async {
    try {
      await _widgetBridgeWriter.writeAll(DateTime.now());
    } catch (_) {
      // Swallowed deliberately — see doc comment above.
    }
  }

  /// Constructs one [Goal] plus its first [GoalVersion] and persists both
  /// via the repository interfaces inside a single transaction (AD-6, AD-3,
  /// Transaction atomicity).
  Future<Result<Goal>> createGoal({
    required String name,
    String? description,
    String? category,
    required String startDate,
    String? endDate,
    required String evaluationPeriod,
    required String eligibleDaysRule,
    required String targetComparison,
    required String targetValue,
    required String trackingType,
    int cheatDayQuota = 0,
  }) async {
    if (name.trim().isEmpty) {
      return const Failure('Goal name must not be empty.');
    }

    final goal = Goal(
      id: _uuid.v4(),
      name: name,
      description: description,
      category: category,
      archived: false,
      startDate: startDate,
      endDate: endDate,
    );

    final version = GoalVersion(
      id: _uuid.v4(),
      goalId: goal.id,
      versionStartDate: startDate,
      evaluationPeriod: evaluationPeriod,
      eligibleDaysRule: eligibleDaysRule,
      targetComparison: targetComparison,
      targetValue: targetValue,
      trackingType: trackingType,
      cheatDayQuota: cheatDayQuota,
    );

    await _transactionRunner.run(() async {
      await _goalRepository.insertGoal(goal);
      await _goalVersionRepository.insertVersion(version);
      await _refreshCache(goalId: goal.id, date: startDate);
    });
    unawaited(_syncWidgetBridge());

    return Success(goal);
  }

  /// Writes one [GoalLog] for a Boolean goal's day inside a transaction —
  /// the only entry point presentation code may call to log a day.
  Future<Result<GoalLog>> logBoolean({
    required String goalId,
    required String date,
    required bool completed,
  }) async {
    final log = GoalLog(
      id: _uuid.v4(),
      goalId: goalId,
      date: date,
      timestamp: DateTime.now().toIso8601String(),
      value: completed ? 1 : 0,
      completed: completed,
    );

    await _transactionRunner.run(() async {
      await _goalLogRepository.insertLog(log);
      await _refreshCache(goalId: goalId, date: date);
    });
    unawaited(_syncWidgetBridge());

    return Success(log);
  }

  /// Retracts a single Boolean `GoalLog` by [logId] — the "undo a mistaken
  /// mark-done" counterpart to [logBoolean] (Bug 4). Deletes the row outright
  /// rather than appending an explicit not-done record, so the day falls
  /// back to whatever state preceded it (Pending, or an earlier log for the
  /// same date) instead of the evaluator's certain-Fail semantics for an
  /// explicit `completed: false` log.
  Future<Result<void>> undoBooleanLog({
    required String goalId,
    required String logId,
    required String date,
  }) async {
    await _transactionRunner.run(() async {
      await _goalLogRepository.deleteLog(logId);
      await _refreshCache(goalId: goalId, date: date);
    });
    unawaited(_syncWidgetBridge());

    return const Success(null);
  }

  /// Applies [delta] to a Counter goal's running total for [date], floored
  /// at 0 (FR-15) — never in the Drift repository or the evaluator, only
  /// here (AD-6). Upserts a single row per `(goalId, date)` in place (FR-14:
  /// no per-increment timestamp) rather than inserting a new row per call.
  Future<Result<GoalLog>> logCounter({
    required String goalId,
    required String date,
    required double delta,
    String? note,
  }) async {
    final log = await _transactionRunner.run(() async {
      final existing = await _goalLogRepository.getLogForDate(goalId, date);
      final rawTotal = (existing?.value ?? 0) + delta;
      final total = rawTotal < 0 ? 0.0 : rawTotal;

      final updated = GoalLog(
        id: existing?.id ?? _uuid.v4(),
        goalId: goalId,
        date: date,
        timestamp: DateTime.now().toIso8601String(),
        value: total,
        completed: total > 0,
        note: note ?? existing?.note,
      );

      await _goalLogRepository.upsertLog(updated);
      await _refreshCache(goalId: goalId, date: date);
      return updated;
    });
    unawaited(_syncWidgetBridge());

    return Success(log);
  }

  /// Marks [date] as exempt from failure for [goalId] (FR-10). Routed
  /// through `GoalService` for consistency with the app's single-writer
  /// discipline (AD-6) and so Epic 6's JSON import has one place to write
  /// Blackout Dates through later — not because a `BlackoutDate` is a
  /// `GoalVersion`/`GoalLog` in AD-6's strict original sense.
  Future<Result<BlackoutDate>> markBlackoutDate({
    required String goalId,
    required String date,
    String? reason,
  }) async {
    final blackoutDate = BlackoutDate(
      id: _uuid.v4(),
      goalId: goalId,
      date: date,
      reason: reason,
    );

    await _transactionRunner.run(() async {
      await _blackoutDateRepository.insertBlackoutDate(blackoutDate);
    });

    return Success(blackoutDate);
  }

  /// Story 2.4 AC 1/2/3/4: marks [date] as a Cheat Day for [goalId], gated
  /// by the `cheatDayQuota` of the `GoalVersion` active *on that date* (not
  /// necessarily the goal's latest Version — mirrors Story 2.1's per-date
  /// Version resolution principle) for the Evaluation Period window
  /// containing [date]. That window is computed by `periodBoundaryFor`
  /// (`domain/evaluator/period_boundary.dart`) — the exact same boundary
  /// function `evaluate()`'s own period aggregation calls — so the quota's
  /// reset window can never disagree with the evaluator's period boundary
  /// (AD-4 "no re-implementation anywhere" principle). The exemption math
  /// itself (does a Cheat Day reduce the required count) is entirely
  /// `evaluate()`'s concern; this method only gates the write.
  Future<GoalServiceResult<CheatDay>> markCheatDay({
    required String goalId,
    required String date,
    String? note,
    WeekStart weekStart = WeekStart.monday,
  }) {
    return _transactionRunner.run(() async {
      final governingVersion = await _goalVersionRepository
          .findGoverningVersion(goalId, date);
      if (governingVersion == null) {
        return GoalServiceResult<CheatDay>.failure(
          GoalServiceFailure.cheatDayQuotaExhausted,
        );
      }

      final goal = (await _goalRepository.findById(goalId))!;
      final window = periodBoundaryFor(
        evaluationPeriod: governingVersion.evaluationPeriod,
        date: DateTime.parse(date),
        goalStartDate: DateTime.parse(goal.startDate),
        weekStart: weekStart,
      );
      final usedThisPeriod = await _cheatDayRepository.findByGoalIdInRange(
        goalId,
        formatDateOnly(window.start),
        formatDateOnly(window.end),
      );

      if (usedThisPeriod.length >= governingVersion.cheatDayQuota) {
        return GoalServiceResult<CheatDay>.failure(
          GoalServiceFailure.cheatDayQuotaExhausted,
        );
      }

      final cheatDay = CheatDay(
        id: _uuid.v4(),
        goalId: goalId,
        date: date,
        note: note,
      );
      await _cheatDayRepository.insertCheatDay(cheatDay);
      return GoalServiceResult<CheatDay>.success(cheatDay);
    });
  }

  /// Story 2.5 AC 1/2/3: marks [date] as "did not finish" (FR-17) — a
  /// display-only placeholder on the `GoalLog`, never an `evaluate()` input
  /// (Task 3 / ARCHITECTURE-SPINE.md: "`GOAL_LOG.dnfMarked` is a
  /// display-only annotation, not an `evaluate()` input"). Rejected with
  /// `notEligibleOrAlreadyResolved` unless [date] currently resolves to
  /// `pending` for [goalId] — a DNF mark on a day that can never show it
  /// (already resolved, or never eligible) would be meaningless. The
  /// eligibility check calls the domain's single `evaluate()` entry point
  /// (AD-4) with this goal's full Versions/Logs/CheatDays/BlackoutDates,
  /// exactly the same inputs the live calendar screens already assemble.
  /// [today] mirrors `evaluate()`'s own `today` override (defaults to the
  /// real wall-clock date when omitted, which every production caller
  /// relies on) — tests pin it explicitly so a fixture date's Pending/
  /// resolved outcome never depends on when the test happens to run.
  Future<GoalServiceResult<GoalLog>> markDnf({
    required String goalId,
    required String date,
    DateTime? today,
  }) async {
    final result = await _transactionRunner.run(() async {
      final goal = (await _goalRepository.findById(goalId))!;
      final versions = await _goalVersionRepository.findAllForGoal(goalId);
      final logs = await _goalLogRepository.findAllForGoal(goalId);
      final blackoutDates = await _blackoutDateRepository.findAllForGoal(
        goalId,
      );
      final cheatDays = await _cheatDayRepository.findAllForGoal(goalId);

      final now = today ?? DateTime.now();
      final dayStatus = evaluate(
        goal: goal,
        versions: versions,
        logs: logs,
        blackoutDates: blackoutDates,
        cheatDays: cheatDays,
        date: DateTime.parse(date),
        today: DateTime(now.year, now.month, now.day),
      );
      if (dayStatus.status != DayStatusValue.pending) {
        return GoalServiceResult<GoalLog>.failure(
          GoalServiceFailure.notEligibleOrAlreadyResolved,
        );
      }

      final existing = await _goalLogRepository.getLogForDate(goalId, date);
      final updated =
          (existing ??
                  GoalLog(
                    id: _uuid.v4(),
                    goalId: goalId,
                    date: date,
                    timestamp: DateTime.now().toIso8601String(),
                    value: 0,
                    completed: false,
                  ))
              .copyWith(dnfMarked: true);
      await _goalLogRepository.upsertLog(updated);
      await _refreshCache(goalId: goalId, date: date);
      return GoalServiceResult<GoalLog>.success(updated);
    });
    if (result is GoalServiceSuccess<GoalLog>) unawaited(_syncWidgetBridge());
    return result;
  }

  /// Story 3.5 Subtask 1.2: assigns/clears [goalId]'s `category` — direct
  /// `GOAL` row metadata, never a `GoalVersion` write (AD-6 only mandates
  /// versioning for rule/schedule/target/lifecycle changes; `category` lives
  /// on `GOAL` itself, per the architecture ER diagram). [category] of
  /// `null` or empty clears the assignment back to "no category."
  Future<GoalServiceResult<Goal>> updateGoalCategory({
    required String goalId,
    String? category,
  }) {
    return _transactionRunner.run(() async {
      final goal = (await _goalRepository.findById(goalId))!;
      final trimmed = category?.trim();
      final updated = goal.copyWith(
        category: trimmed,
        clearCategory: trimmed == null || trimmed.isEmpty,
      );
      await _goalRepository.updateGoal(updated);
      return GoalServiceResult<Goal>.success(updated);
    });
  }

  /// Story 2.1 AC 1/2/3/4/5: edits a live goal's rules effective
  /// [effectiveDate], creating a new dated `GoalVersion` segment rather
  /// than mutating history — or, per the AD-6 collision algorithm, amending
  /// a still-log-free same-day Version in place, or rejecting the edit as
  /// `versionLocked` once a `GoalLog` already exists against it. The one
  /// entry point the edit wizard's Save handler is permitted to call
  /// (AD-6 — no repository call from presentation).
  Future<GoalServiceResult<GoalVersion>> editGoalVersion({
    required String goalId,
    required String effectiveDate,
    required GoalVersionDraft newRules,
  }) {
    return _writeVersionSegment(
      goalId: goalId,
      effectiveDate: effectiveDate,
      buildVersion: (existing, id) => GoalVersion(
        id: id,
        goalId: goalId,
        versionStartDate: effectiveDate,
        evaluationPeriod: newRules.evaluationPeriod,
        eligibleDaysRule: newRules.eligibleDaysRule,
        targetComparison: newRules.targetComparison,
        targetValue: newRules.targetValue,
        trackingType: newRules.trackingType,
        cheatDayQuota: newRules.cheatDayQuota,
        // Editing rules never itself pauses/resumes a Version (Story 2.2's
        // separate concern) — a same-day amend-in-place must preserve
        // whatever pause state the row already had; a brand-new segment
        // starts unpaused, matching GoalVersion's own default.
        isPaused: existing?.isPaused ?? false,
      ),
    );
  }

  /// Story 2.3 AC 1/4: archives [goalId] — flips `Goal.archived` to `true`
  /// and nothing else. Unlike pause/resume (Story 2.2), this is a direct,
  /// non-dated flag write, never a `GoalVersion` segment (AD-6's versioning
  /// write path doesn't apply here — archiving has no effective date and no
  /// collision to resolve), so `GoalVersion`/`GoalLog` rows are always left
  /// untouched (AC 4 is satisfied by construction). Idempotent: archiving an
  /// already-archived goal just re-writes `archived = true` and succeeds
  /// (Task 1.3) — the same `archiveGoal` call backs both a "Delete" and an
  /// "Archive" UI affordance (FR-35).
  Future<GoalServiceResult<Goal>> archiveGoal({required String goalId}) {
    return _transactionRunner.run(() async {
      // Precondition: goalId refers to an existing Goal — every caller
      // (Goal Detail) already holds the Goal it's archiving.
      final goal = (await _goalRepository.findById(goalId))!;
      final archived = goal.copyWith(archived: true);
      await _goalRepository.updateGoal(archived);
      return GoalServiceResult<Goal>.success(archived);
    });
  }

  /// Story 2.2 AC 1/2/3/4: pauses [goalId] effective [effectiveDate] — a
  /// new/amended `GoalVersion` segment with `isPaused = true`, its other
  /// rule fields copied forward unchanged from whichever Version currently
  /// governs [effectiveDate] (pausing never itself changes rules). Reuses
  /// the exact same `_writeVersionSegment` collision algorithm
  /// [editGoalVersion] uses (AC 4) — not a second, parallel version-write
  /// path.
  Future<GoalServiceResult<GoalVersion>> pauseGoal({
    required String goalId,
    required String effectiveDate,
  }) {
    return _writePauseState(
      goalId: goalId,
      effectiveDate: effectiveDate,
      isPaused: true,
    );
  }

  /// Story 2.2 AC 1/2/3/4: resumes [goalId] effective [effectiveDate] — a
  /// new/amended `GoalVersion` segment with `isPaused = false`, its other
  /// rule fields copied forward unchanged from the paused Version being
  /// resumed. Resuming does not re-open rule editing; Panda uses
  /// [editGoalVersion] separately for that.
  Future<GoalServiceResult<GoalVersion>> resumeGoal({
    required String goalId,
    required String effectiveDate,
  }) {
    return _writePauseState(
      goalId: goalId,
      effectiveDate: effectiveDate,
      isPaused: false,
    );
  }

  /// Shared by [pauseGoal]/[resumeGoal]: looks up the Version currently
  /// governing [effectiveDate] to source the rule fields the new/amended
  /// segment carries forward unchanged, then delegates the actual write to
  /// [_writeVersionSegment] — the same collision algorithm [editGoalVersion]
  /// uses. The governing-Version lookup happens once, ahead of the write
  /// transaction, since [_writeVersionSegment]'s `buildVersion` callback is
  /// synchronous; inside the transaction, a same-day collision's own
  /// `existing` row (guaranteed to equal this same governing Version, since
  /// its `versionStartDate` is the latest one `<= effectiveDate`) is
  /// preferred when present, for a read taken inside the transaction rather
  /// than before it.
  Future<GoalServiceResult<GoalVersion>> _writePauseState({
    required String goalId,
    required String effectiveDate,
    required bool isPaused,
  }) async {
    final governing = await _goalVersionRepository.findGoverningVersion(
      goalId,
      effectiveDate,
    );

    return _writeVersionSegment(
      goalId: goalId,
      effectiveDate: effectiveDate,
      buildVersion: (existing, id) {
        final rulesSource = existing ?? governing!;
        return GoalVersion(
          id: id,
          goalId: goalId,
          versionStartDate: effectiveDate,
          evaluationPeriod: rulesSource.evaluationPeriod,
          eligibleDaysRule: rulesSource.eligibleDaysRule,
          targetComparison: rulesSource.targetComparison,
          targetValue: rulesSource.targetValue,
          trackingType: rulesSource.trackingType,
          cheatDayQuota: rulesSource.cheatDayQuota,
          isPaused: isPaused,
        );
      },
    );
  }

  /// Story 6.2 Task 5: writes [goal] via an upsert keyed on its own `id` —
  /// the exact `id` the JSON import file carries, never a freshly minted one
  /// the way [createGoal] mints for its caller. This is a deliberate
  /// addition to `GoalService` rather than a repository bypass (AD-6): import
  /// must preserve a backup's original entity ids (Task 3's conflict
  /// detection is id-based — a re-imported backup only matches its own prior
  /// writes if the ids agree), which none of the five existing write methods
  /// can do, since none of them accept a caller-supplied id. Does not itself
  /// refresh the status cache or widget bridge — a bulk import touches many
  /// goals/dates at once, so [finalizeImport] does one wholesale
  /// `CacheWriter.rebuildAll()` after every entity in the batch is written,
  /// rather than this method recomputing one `(goalId, date)` at a time.
  Future<void> importGoal(Goal goal) {
    return _transactionRunner.run(() => _goalRepository.upsertGoal(goal));
  }

  /// Story 6.2 Task 5: writes [version] via an upsert keyed on its own `id`
  /// — see [importGoal]'s doc comment for why this is a new `GoalService`
  /// method rather than reusing [editGoalVersion]/[pauseGoal]/[resumeGoal]:
  /// those all run the AD-6 collision algorithm
  /// (`_writeVersionSegment`), which mints a fresh id and can reject with
  /// `versionLocked` — behavior appropriate for a live edit, not for
  /// faithfully restoring a backup's exact historical Version rows.
  Future<void> importVersion(GoalVersion version) {
    return _transactionRunner.run(
      () => _goalVersionRepository.upsertVersion(version),
    );
  }

  /// Story 6.2 Task 5: writes [log] via [GoalLogRepository.upsertLog], which
  /// already upserts by `id` (Story 1.11) — the one existing repository
  /// method structurally fit for import's needs unchanged. Not routed
  /// through [logBoolean]/[logCounter]: both mint a fresh id and timestamp,
  /// and [logCounter] is delta-based (adds to the existing total) rather
  /// than "write this exact value," so neither can faithfully restore a
  /// backup's original log row.
  Future<void> importLog(GoalLog log) {
    return _transactionRunner.run(() => _goalLogRepository.upsertLog(log));
  }

  /// Story 6.2 Task 5: writes [cheatDay] via an upsert keyed on its own `id`
  /// — see [importGoal]'s doc comment. Not routed through [markCheatDay]:
  /// that mints a fresh id and re-enforces the live `cheatDayQuota` gate,
  /// which could spuriously reject a historical Cheat Day that was validly
  /// recorded under a quota that has since changed.
  Future<void> importCheatDay(CheatDay cheatDay) {
    return _transactionRunner.run(
      () => _cheatDayRepository.upsertCheatDay(cheatDay),
    );
  }

  /// Story 6.2 Task 5: writes [blackoutDate] via an upsert keyed on its own
  /// `id` — see [importGoal]'s doc comment. Not routed through
  /// [markBlackoutDate], which mints a fresh id.
  Future<void> importBlackoutDate(BlackoutDate blackoutDate) {
    return _transactionRunner.run(
      () => _blackoutDateRepository.upsertBlackoutDate(blackoutDate),
    );
  }

  /// Story 6.2 Task 5/6: called once after every entity in an import batch
  /// has been written — wholesale-recomputes the status cache
  /// (`CacheWriter.rebuildAll()`, AD-7's recovery/proof entry point) rather
  /// than this story's `importX` methods each recomputing their own
  /// `(goalId, date)` the way every other write path does, since a single
  /// import can touch many goals and many dates at once. Mirrors every other
  /// write path's widget-bridge-sync-races-alongside-the-return convention
  /// (see [_syncWidgetBridge]'s doc comment) rather than gating on it.
  Future<void> finalizeImport() async {
    await _cacheWriter.rebuildAll();
    unawaited(_syncWidgetBridge());
  }

  /// Story 6.3 (FR-36, AD-6): Reset/Erase-All. Wipes every domain table
  /// inside one Drift transaction — children first
  /// (`GoalLog`/`GoalVersion`/`CheatDay`/`BlackoutDate`/the status cache),
  /// `Goal` last, since every other table references `Goals` by id — then
  /// clears the settings-store values via the two repositories the caller
  /// resolved for it (Subtask 1.3: `shared_preferences` isn't Drift, so this
  /// can't literally share the SQL transaction, but it still happens inside
  /// this same logical use-case call, never left to a separate
  /// presentation-layer step). Finally syncs the widget bridge via the
  /// ordinary [_syncWidgetBridge] race-alongside convention: with every Goal
  /// gone, [WidgetBridgeWriter.writeAll] overwrites whatever stale payload
  /// the home-screen widgets held with empty envelopes.
  ///
  /// Takes [reminderSettingsRepository]/[weekStartSettingsRepository] as
  /// call-time parameters rather than constructor dependencies: both sit
  /// behind `shared_preferences`, whose composition-root providers are
  /// `Future`-returning (unlike every other `GoalService` dependency), so
  /// resolving them is left to this method's caller — the same
  /// resolve-then-call shape `ReminderTimeController`/`WeekStartController`
  /// already use for their own settings-repo access.
  Future<void> resetAll({
    required ReminderSettingsRepository reminderSettingsRepository,
    required WeekStartSettingsRepository weekStartSettingsRepository,
  }) async {
    await _transactionRunner.run(() async {
      await _goalLogRepository.deleteAll();
      await _goalVersionRepository.deleteAll();
      await _cheatDayRepository.deleteAll();
      await _blackoutDateRepository.deleteAll();
      await _cacheWriter.clearAll();
      await _goalRepository.deleteAll();
    });

    await reminderSettingsRepository.clear();
    await weekStartSettingsRepository.clear();

    unawaited(_syncWidgetBridge());
  }

  /// The single implementation of AD-6's version-write collision algorithm,
  /// shared by this story's [editGoalVersion] and Story 2.2's pause/resume
  /// (see that story's Dev Notes: "the version-write helper you build here
  /// is one that both this story and Story 2.2's pause/resume call"). Given
  /// `(goalId, effectiveDate)`:
  ///
  /// 1. Look up any existing `GoalVersion` at that exact
  ///    `(goalId, versionStartDate)`.
  /// 2. None exists → INSERT a new row: [buildVersion] is called with
  ///    `existing: null` and a fresh UUIDv4 `id`.
  /// 3. One exists and no `GoalLog` for this goal has `date >= effectiveDate`
  ///    → UPDATE that row in place: [buildVersion] is called with the
  ///    existing row and its own `id`, so a caller can carry forward any
  ///    field it isn't changing.
  /// 4. One exists and at least one such `GoalLog` exists → reject with
  ///    `GoalServiceFailure.versionLocked`; nothing is written.
  ///
  /// The existence-check read and the INSERT/UPDATE write happen inside one
  /// Drift transaction (AC 5) — a kill mid-write can never leave a
  /// half-written Version.
  Future<GoalServiceResult<GoalVersion>> _writeVersionSegment({
    required String goalId,
    required String effectiveDate,
    required GoalVersion Function(GoalVersion? existing, String id)
    buildVersion,
  }) async {
    final result = await _transactionRunner.run(() async {
      final existing = await _goalVersionRepository.findByGoalIdAndStartDate(
        goalId,
        effectiveDate,
      );

      if (existing == null) {
        final version = buildVersion(null, _uuid.v4());
        await _goalVersionRepository.insertVersion(version);
        await _refreshCache(goalId: goalId, date: effectiveDate);
        return GoalServiceResult<GoalVersion>.success(version);
      }

      final hasLogsAgainstIt = await _goalLogRepository.existsOnOrAfter(
        goalId,
        effectiveDate,
      );
      if (hasLogsAgainstIt) {
        return GoalServiceResult<GoalVersion>.failure(
          GoalServiceFailure.versionLocked,
        );
      }

      final updated = buildVersion(existing, existing.id);
      await _goalVersionRepository.updateVersion(updated);
      await _refreshCache(goalId: goalId, date: effectiveDate);
      return GoalServiceResult<GoalVersion>.success(updated);
    });
    if (result is GoalServiceSuccess<GoalVersion>) {
      unawaited(_syncWidgetBridge());
    }
    return result;
  }
}
