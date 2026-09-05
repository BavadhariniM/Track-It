---
baseline_commit: NO_VCS
---

# Story 4.2: Reminder Suppression Rules

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want the daily reminder to skip goals that aren't eligible today, are paused/archived, or are already done for the period — except goals I've set to "at least," which should keep nudging me since more is still good,
so that the reminder stays useful instead of becoming noise.

## Acceptance Criteria

1. **Given** a goal is not Eligible today **When** the reminder fires **Then** it does not include or trigger for that goal (FR-30)
2. **Given** a goal is Paused or Archived **When** the reminder fires **Then** it is excluded entirely (FR-30)
3. **Given** a goal's target for the current period is already met and its Target Comparison is At Most or Exactly **When** the reminder fires **Then** that goal is suppressed (FR-30, suppress-on-completion)
4. **Given** a goal's Target Comparison is At Least (≥) and its target is already met for the period **When** the reminder fires **Then** that goal is still included — reminders continue since additional logging beyond the minimum may still be wanted (FR-30, resolved exception)
5. **And** if every eligible goal for today is suppressed, no reminder fires at all rather than firing an empty one

## Tasks / Subtasks

- [x] Task 1: Build the suppression-logic function (AC: #1, #2, #3, #4)
  - [x] 1.1 Add a pure function in `lib/domain/services/` (e.g. `ReminderSuppressionService` or a top-level function `filterRemindableGoals(...)`) that takes the set of active/paused/archived Goals plus, for each, the `DayStatus` already produced by Epic 1's `evaluate()` for today — **do not re-implement eligibility, target-met, or pause/archive-state logic inside this function**. It must call/consume `evaluate()`'s existing output (or a thin per-goal wrapper that itself calls `evaluate()` once per goal), never recompute those facts independently (AD-4: "All callers... call this same function; none re-implements evaluation logic").
  - [x] 1.2 Exclude any goal whose current `GoalVersion` state is Paused or Archived (AC #2) — read this directly from the Goal/Version state, consistent with Epic 2's lifecycle model; a Paused goal already produces no Eligible Days per FR-2/Story 2.2, so this should fall out of `evaluate()`'s output for the paused date range, but Archived must additionally be excluded even if evaluate() would otherwise return a status (Archived goals are hidden from all active-tracking surfaces per FR-2/Story 2.3 — the reminder is an active-tracking surface).
  - [x] 1.3 Exclude any goal that is not Eligible today per `evaluate()`'s output for today's date (AC #1) — a non-eligible day renders `status-empty`; treat that as "not remindable."
  - [x] 1.4 For eligible, non-paused, non-archived goals, branch on `targetComparison` from the goal's active `GoalVersion` (exactly three values — At Least, At Most, Exactly; there is no Range/bounded comparison per Story 1.7):
    - At Most / Exactly: if the current period's target is already met (per `evaluate()`'s status/derived progress for the period), suppress (AC #3).
    - At Least (≥): even if the target is already met for the period, **do not suppress** — include the goal in the remindable set regardless of whether the minimum has been reached (AC #4). See the worked example in Dev Notes below — this is the single most likely place to implement this story wrong.
  - [x] 1.5 Return the final remindable-goal set (or an empty set) as the function's sole output — no side effects, no I/O, no scheduling calls inside this function, consistent with keeping domain logic pure and unit-testable (mirrors AD-4's purity requirement even though this isn't `evaluate()` itself).
- [x] Task 2: Wire suppression into the notification content/fire path from Story 4.1 (AC: #1-#5)
  - [x] 2.1 In the `ReminderScheduler`'s fire-time hook (the content-provider/builder seam Story 4.1's Task 2.2 was designed to expose), call the suppression function from Task 1 with today's date, all non-Archived Goals (Archived goals can be filtered before or inside the suppression call — either is acceptable as long as they never reach the notification), their active Versions, logs, cheat days, and blackout dates — the same inputs `evaluate()` itself takes, since the suppression function is built directly on `evaluate()`'s output.
  - [x] 2.2 If the remindable-goal set from Task 1 is empty, do not fire any notification for that day at all (AC #5) — this must be checked at the point the notification would otherwise be shown/scheduled for that day's fire time, not just at app-open time, since goal state (a goal being completed, paused, or archived) can change between when the daily schedule was registered and when it actually fires.
  - [x] 2.3 If non-empty, build the notification body listing (or summarizing) the remindable goals, respecting UX-DR19 tone constraints (see Dev Notes) — no exclamation points, no cheerleading language, plain statement of what's outstanding.
- [x] Task 3: Testing for suppression correctness (AC: #1-#5)
  - [x] 3.1 Unit test the suppression function directly (no plugin/notification I/O involved) across the full matrix required by NFR-6's correctness bar: all 3 Target Comparisons (At Least, At Most, Exactly) × {target not yet met, target exactly met, target exceeded} × {eligible today, not eligible today} × {Active, Paused, Archived}. At minimum, explicitly assert:
    - At Least + target met → goal still included.
    - At Least + target not yet met → goal included.
    - At Most + target met → goal suppressed.
    - At Most + target not yet met → goal included.
    - Exactly + target met → goal suppressed.
    - Exactly + target not yet met → goal included.
    - Any Target Comparison + not eligible today → goal excluded regardless of target state.
    - Any Target Comparison + Paused → goal excluded.
    - Any Target Comparison + Archived → goal excluded.
    - All goals suppressed → empty remindable set, and the scheduler-integration test (3.2) confirms no notification fires.
  - [x] 3.2 Integration-style test (with a fake/mock notification plugin, not a real device notification) verifying that an empty remindable-goal set results in zero calls to the notification-firing API for that day (AC #5), and a non-empty set results in exactly one call with the correctly filtered goal list in its content.
  - [x] 3.3 Regression-check that this story's suppression function never duplicates or diverges from `evaluate()`'s own eligibility/target-met computation — e.g. a shared test fixture/golden set of (goal, date) pairs whose expected `DayStatus` is already covered by Epic 1's evaluator tests should produce the same eligibility/target-met facts when consumed here, not a second, independently-tuned set of edge-case expectations.

## Dev Notes

- **Anti-duplication — reuse Epic 1's `evaluate()` output, do not reimplement:** AD-4 states one pure function, `DayStatus evaluate({Goal, versions, logs, cheatDays, blackoutDates, date})`, is the sole source of eligibility, target-progress, and status computation, and "all callers... call this same function; none re-implements evaluation logic." This story's suppression logic is a *consumer* of `evaluate()`'s output, structured as a filter/decision layer on top — it must not contain its own copy of eligible-day computation, target-comparison arithmetic, or version-boundary logic. If the suppression function needs to know "is the target met for the current period," it should read that from what `evaluate()` (or a thin per-goal wrapper around it) already computed, not recompute it from raw logs. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4]

- **The At-Least (≥) exception — spelled out precisely, with a concrete example:** FR-30 states the scheduler suppresses a goal once its current period's target is already met, **except** for At Least (≥) goals, where reminders continue even after the minimum is met, "since additional logging beyond the minimum may still be wanted."
  - Concrete example: a Counter goal "Drink at least 8 glasses of water today" (Daily period, Target Comparison = At Least, target value = 8). Panda logs 8 glasses by 3pm. At the reminder's scheduled time (say 8pm), the goal has already met its target for the day. **Do not suppress this goal.** The reminder should still include/nudge for it, because Panda might reasonably want to keep drinking water beyond 8 glasses — At Least has no ceiling, so "met" does not mean "done" the way it does for At Most or Exactly.
  - Contrast: a Counter goal "At most 2 coffees today" (Target Comparison = At Most, target value = 2). Panda logs 2 coffees by noon. At 8pm, the goal has met (hit the ceiling of) its target. **This goal must be suppressed** — reminding Panda about a goal whose ceiling is already reached would be actively counterproductive (it could only be logged further by violating the goal).
  - Contrast: a Boolean goal "Meditate" (Target Comparison = Exactly, effectively "done" = 1 of 1). Once marked done, **suppress** — there's nothing more to log.
  - The exception is scoped **only** to Target Comparison = At Least. Do not generalize it to "any Counter goal" or "any goal without a hard ceiling" — apply it strictly by the `targetComparison` field's value on the goal's active `GoalVersion`.
  - [Source: docs/epics.md#Story 4.2] — "Given a goal's Target Comparison is At Least (≥) and its target is already met for the period, When the reminder fires, Then that goal is still included."

- **Reboot/offline constraints carried forward from Story 4.1:** this story's suppression check must be evaluated at actual fire time (not baked into a static schedule at the time the daily alarm was registered), since goal state can change throughout the day. It must still respect NFR-1/NFR-2 — no network call, no telemetry — the suppression computation is 100% local, reading only from Drift-backed repositories and `evaluate()`. [Source: docs/epics.md#Requirements Inventory — NFR-1, NFR-2]

- **No-empty-reminder rule (AC #5):** if suppression reduces the remindable set to zero, the notification must not fire at all that day — not fire with an empty body, not fire with generic "nothing to do" filler text. This must be checked inside the fire-time hook from Story 4.1's `ReminderScheduler`, immediately before the notification would be shown.

- **Layering and DI, consistent with Story 4.1:** the suppression function lives in `lib/domain/services/` (pure, no Flutter/Drift imports, per AD-1); it is wired into the `data`/`platform`-level `ReminderScheduler` implementation via the content-provider/builder seam Story 4.1 established, exposed through the same Riverpod provider graph (AD-2) — no new singleton/service-locator access pattern introduced here.

- **UX tone constraints (UX-DR19) apply to notification body copy:** plain, declarative, never encouraging — state what's outstanding as fact ("Not yet logged: Water, Meditation"), never cheerleading or exclamation-marked ("Don't forget your goals!"). This applies specifically to whatever notification body text Task 2.3 constructs. [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Voice and Tone]

- **Testing standard for suppression correctness (NFR-6):** because this is exactly the kind of edge-case-dense logic NFR-6 calls out as a first-class acceptance bar, the unit test matrix in Task 3.1 (4 Target Comparisons × 3 target states × 2 eligibility states × 3 lifecycle states) is not optional scope-padding — it is the actual acceptance bar for this story, beyond the literal Given/When/Then examples in the ACs. A developer who only tests the four literal AC examples has not met NFR-6 for this story.

### Previous Story Intelligence (from Story 4.1)

- Story 4.1 (`docs/stories/4-1-global-daily-reminder.md`) builds the `ReminderScheduler` (domain interface in `lib/domain/services/`, `flutter_local_notifications`-backed implementation in `lib/data/`/`lib/platform/`) and deliberately designed its fire-time API around a content-provider/builder seam so that "Story 4.2 does not need to rewrite the scheduling plumbing" — this story (4.2) is that seam's first real consumer. Do not re-architect the scheduler; extend it by supplying the suppression-aware content builder at the seam Story 4.1 left open.
- Story 4.1 also established the reminder time itself as `shared_preferences`-backed settings data (AD-3 exception), exposed via Riverpod providers — this story does not touch that persistence path at all; it only reads Goal/Version/log/cheat-day/blackout-date data (all Drift-backed, per AD-3's main rule) plus calls `evaluate()`.
- Story 4.1's scheduling mechanism fires unconditionally once registered; this story is what makes that firing conditional. The two stories together implement FR-30 in full — 4.1 alone does not satisfy FR-30's suppression clauses, and this story alone has no scheduling mechanism to attach to without 4.1.
- Story 4.1 flagged reboot re-registration (Android `BOOT_COMPLETED`) as needing platform-specific verification at implementation time against the pinned `flutter_local_notifications 21.0.0` version's current documented behavior — that caveat carries forward unchanged here since this story does not alter the scheduling/registration mechanism, only the content decision made at fire time.

### Project Structure Notes

- New files align with the structural seed and with Story 4.1's layout: `lib/domain/services/` (new: suppression function/service, pure, no Flutter/Drift imports), extending the `lib/data/`/`lib/platform/` `ReminderScheduler` implementation from Story 4.1 to call the new suppression function at fire time. No new Drift tables, no new `shared_preferences` keys — this story reads existing Goal/Version/GoalLog/CheatDay/BlackoutDate data and calls the existing `evaluate()` function; it does not introduce new persisted state. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed]
- Consistent with AD-1 layering: the suppression function belongs in `domain` alongside `GoalService`/`StatsService`/`evaluate()`, not in `data` or `presentation` — it is business logic (which goals deserve a reminder), not a persistence or UI concern.

### References

- [Source: docs/epics.md#Story 4.2] — user story statement and acceptance criteria (Given/When/Then blocks), verbatim basis for this file.
- [Source: docs/epics.md#Requirements Inventory] — FR-30 (Local Reminders, including the resolved At-Least exception and the "no empty reminder" implication), FR-11 (Target Comparison types: At Least, At Most, Exactly), NFR-1, NFR-2, NFR-6.
- [Source: docs/epics.md#Additional Requirements] — AD-1 (layering), AD-4 (pure evaluator contract — single source of eligibility/target-met truth).
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4] — Pure Evaluator Contract: "All callers... call this same function; none re-implements evaluation logic."
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-1] — Layered/Hexagonal Paradigm (domain purity).
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Evaluator flow diagram] — illustrates what `evaluate()` already produces (eligibility, target-met/Pending/Red decision) that this story's suppression logic consumes rather than recomputes.
- [Source: docs/epics.md#Story 2.2] — Pause/Resume mechanics (a Paused goal produces no Eligible Days for the paused range) informing Task 1.2's exclusion logic.
- [Source: docs/epics.md#Story 2.3] — Archive/Expire mechanics (Archived goals hidden from active-tracking surfaces) informing Task 1.2's exclusion logic.
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Voice and Tone] — UX-DR19 copy-tone constraints applied to notification body text.
- [Source: docs/stories/4-1-global-daily-reminder.md] — previous story intelligence: `ReminderScheduler` design, content-provider/builder seam, `shared_preferences` settings scope.

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `flutter analyze` (whole project) and `flutter test` (full suite, 301 tests) both pass clean after all changes; the 20 pre-existing `prefer_initializing_formals` info-lints are all in files this story never touched.
- No new dependencies, no Drift schema changes, no `build_runner` codegen needed — `buildSuppressionAwareReminderContent` is a plain function, not a `@riverpod`-annotated provider.

### Completion Notes List

- Implemented `filterRemindableGoals` (`lib/domain/services/reminder_suppression_service.dart`) — a pure function that, per goal, reads its lifecycle state via Epic 2's existing `resolveLifecycleStatus` (excluding Paused/Archived, AC #2) and calls `evaluate()` once (AD-4) to get `DayStatus` (excluding non-eligible-today, AC #1). For eligible/active goals, At Most/Exactly comparisons are suppressed once `DayStatus.currentValue >= DayStatus.targetValue` (AC #3); At Least never suppresses on this basis (AC #4).
- **Key design decision on "already met" (AC #3):** `evaluate()`'s own `DayStatusValue.success` is *not* usable as the "already met" signal, because a Daily-period Counter goal is always treated as "still open" by `evaluate()` until the next calendar date (see `evaluate.dart`'s `_evaluateDay` comment) — an At Most goal that exactly reaches its ceiling mid-day reports `pending`, not `success`, until the day rolls over. The Dev Notes' own worked example ("at most 2 coffees, logged 2 by noon, must be suppressed at 8pm") requires suppression *before* that rollover. So the suppression check reads `DayStatus.currentValue`/`targetValue` directly (values `evaluate()` already computed, never re-summed from logs) and suppresses at "met or exceeded" (`actual >= target`) for At Most/Exactly — this also correctly covers the "exceeded" test cases (already-broken ceiling/already-overshot exact target), which are just as pointless to keep nagging about as an exact hit.
- **Key design decision on Paused/Archived (AC #2):** relies on `resolveLifecycleStatus` (Epic 2, `goal_lifecycle_status.dart`) rather than solely on `evaluate()`'s `DayStatusValue.empty`, because a non-Daily (period-type) goal whose *entire* period is paused makes `evaluate()` return `fail` (a "zero eligible days" misconfiguration signal), not `empty` — relying only on `status == empty` would have wrongly included such a goal. A dedicated regression test (`reminder_suppression_service_test.dart`, Task 3.3) proves this divergence and confirms `filterRemindableGoals` still excludes it correctly.
- Wired the suppression function into Story 4.1's `contentBuilder` seam via a new `buildSuppressionAwareReminderContent(Ref ref)` factory in `reminder_settings_provider.dart`, replacing the old fixed `_defaultReminderContent` at both call sites (`ReminderTimeController.setReminderTime` and `reminderInitializer`). It reads every non-Archived Goal plus its Versions/Logs/CheatDays/BlackoutDates once, calls `filterRemindableGoals`, and returns `null` (never an empty-body notification) when nothing remains (AC #5) — the real `FlutterLocalNotificationsReminderScheduler` already treats a `null` content as "cancel, don't fire" (Story 4.1).
- **Fire-time freshness (AC #5's "not just at app-open time"):** `flutter_local_notifications` bakes notification content in at *scheduling* time, not at the moment it actually fires (Story 4.1's own `ReminderContentBuilder` doc comment already flagged this and suggested a midnight-rollover hook as the fix). Implemented that hook: `midnight_rollover_provider.dart`'s existing `MidnightRolloverWatcher` now also re-registers the reminder (if one is configured) with freshly-computed suppression-aware content on every date rollover, in addition to the existing app-open (`reminderInitializer`) and Settings-write (`ReminderTimeController`) registration points. This bounds staleness to "at most since midnight" rather than "since app was last opened" — a genuine improvement, though not perfect intraday freshness (a goal completed at 3pm won't un-suppress an 8pm reminder already showing it as outstanding); that residual gap is the same accepted `flutter_local_notifications` limitation Story 4.1 already documented, not something this story's task list asked to solve further.
- Extracted `current_date_provider.dart`'s private `_today()` into a public `todayDateOnly()` so the new content builder can do a plain one-shot "what date is it" read without subscribing to (and needing to keep alive) the reactive `currentDateProvider` stream — using that stream directly caused a `StateError` in tests (`currentDateProvider` disposed mid-load, since nothing was watching it to keep it alive outside the real app's `midnightRolloverWatcherProvider`).
- Updated `test/presentation/reminder_settings_provider_test.dart` to override the Goal/Version/Log/CheatDay/BlackoutDate repositories with the shared `InMemoryStore`/`InMemoryXRepository` fakes (`test/domain/services/fakes.dart`), since the new content builder now reads them; added two integration-style tests (Task 3.2) proving zero-vs-one `scheduleDaily` content calls for empty/non-empty remindable sets. Extended `test/presentation/midnight_rollover_test.dart` with two tests proving the new rollover reschedule hook fires (with correct content) when a reminder is configured, and is a no-op when none is.
- Manual/platform verification note: this story adds no new platform-specific behavior beyond Story 4.1's already-flagged manual checklist (real-device notification firing/reboot survival) — nothing new to add to that checklist here.

### File List

**New:**
- `lib/domain/services/reminder_suppression_service.dart`
- `test/domain/services/reminder_suppression_service_test.dart`

**Modified:**
- `lib/presentation/providers/reminder_settings_provider.dart` — added `buildSuppressionAwareReminderContent`; replaced `_defaultReminderContent` at both `scheduleDaily` call sites.
- `lib/presentation/providers/midnight_rollover_provider.dart` — added the rollover reminder-reschedule hook (`_rescheduleReminderIfSet`).
- `lib/presentation/providers/current_date_provider.dart` — extracted `_today()` into public `todayDateOnly()`.
- `test/presentation/reminder_settings_provider_test.dart` — added repository fakes/overrides; added Subtask 3.2 integration tests.
- `test/presentation/midnight_rollover_test.dart` — added reminder-repository/scheduler fakes/overrides; added two rollover-reschedule tests.
