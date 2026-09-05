---
baseline_commit: NO_VCS
---

# Story 2.5: DNF Marking

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to explicitly mark a day as "did not finish" as a placeholder,
so that I can note it in the moment even before the period's real outcome is known, without that guess overriding the actual computed result later.

## Acceptance Criteria

1. **Given** an eligible day, **when** Panda marks it DNF, **then** the day shows a distinct "DNF (pending period close)" treatment (FR-17, UX-DR20).
2. **Given** a day marked DNF, **when** its enclosing Evaluation Period actually closes, **then** the DNF mark is silently superseded by whatever `evaluate()` actually computed for that period — the DNF mark is never itself an `evaluate()` input (FR-17).
3. **And** if a day marked DNF turns out to have succeeded once logged, the real Success status is shown once the period closes, with no stale DNF treatment left visible (FR-17 consequence, UX-DR20).

## Tasks / Subtasks

- [x] Task 1: Confirm/add the `dnfMarked` column on `GOAL_LOG` (AC: 1, 2, 3)
  - [x] 1.1 Before writing any code, check `lib/data/drift/tables/goal_logs_table.dart` for a `dnfMarked` (or `dnf_marked`) boolean column. ARCHITECTURE-SPINE.md's ERD lists `dnfMarked` on `GOAL_LOG` without an epic-timing caveat (unlike the explicit `CHEAT_DAY`/`BLACKOUT_DATE` table-split note for Story 1.6/2.4), so it may already exist from Epic 1's initial `GOAL_LOG` migration.
  - [x] 1.2 If it is missing, add it now: `dnf_marked BOOLEAN NOT NULL DEFAULT FALSE`, bump `AppDatabase.schemaVersion` by 1 from its current value (check the actual current number in `lib/data/drift/app_database.dart` — this will be at least the 3rd schema bump across Epic 2, after Story 2.2's `isPaused` and Story 2.4's `CHEAT_DAY` table, do not assume a specific prior value), and add the `onUpgrade` migration. Flag in the File List whichever branch (already-present vs. newly-added) actually applied, since this was not resolvable with certainty at story-writing time (see Dev Notes "Open question").
- [x] Task 2: `GoalService.markDnf` (AC: 1, 2, 3)
  - [x] 2.1 Add `Future<GoalServiceResult<GoalLog>> markDnf({required String goalId, required String date})` to `lib/domain/services/goal_service.dart`.
  - [x] 2.2 Before writing, call `evaluate()` for `(goalId, date)` with the goal's current versions/logs/cheatDays/blackoutDates to confirm the date currently resolves to `pending`. If the date is not eligible for this goal, or its period has already resolved to a certain outcome (success/fail, including the FR-5 zero-eligible-days-red case), return `GoalServiceResult.failure(GoalServiceFailure.notEligibleOrAlreadyResolved)` — marking DNF on a day that can never show it (AC 2/3 mean a resolved period always wins) would be meaningless and should be rejected rather than silently accepted.
  - [x] 2.3 If a `GoalLog` already exists for `(goalId, date)`, UPDATE only its `dnfMarked` field to `true` — never touch `value`/`completed`/`note`. If none exists, INSERT a placeholder `GoalLog` (`completed = false`, `value = 0`, `dnfMarked = true`) so the flag has a row to live on.
  - [x] 2.4 Wrap the read-check (`evaluate()` call) plus the INSERT/UPDATE in a single Drift transaction, consistent with every other `GoalService` write this epic has established.
  - [x] 2.5 Add `notEligibleOrAlreadyResolved` to `GoalServiceFailure` (`lib/domain/services/goal_service_result.dart`) with a specific-reason message (UX-DR19).
- [x] Task 3: Confirm `evaluate()` needs no change (AC: 2, 3)
  - [x] 3.1 Do **not** add `dnfMarked`/DNF handling to `evaluate()`'s signature or logic. ARCHITECTURE-SPINE.md is explicit: "`GOAL_LOG.dnfMarked` (FR-17) is a display-only annotation, not an `evaluate()` input — it is superseded by the period's actual computed outcome once that period closes." `evaluate()` computes `DayStatus` exactly as it already does in Epic 1, completely unaware DNF marks exist.
- [x] Task 4: Presentation — DNF treatment on the goal-row, not a new status-cell glyph (AC: 1, 2, 3)
  - [x] 4.1 Extend the shared long-press/overflow sheet component from Stories 1.6/2.4 (`lib/presentation/components/day_row_action_sheet.dart`) with a "Mark DNF" action, available only when the tapped day currently resolves to `pending` (gate the menu item client-side using the same `evaluate()` call the service re-validates in Task 2.2, so Panda never sees an action that would just be rejected).
  - [x] 4.2 On the `goal-row` (UX-DR7) for a day where `DayStatus == pending` and the log's `dnfMarked == true`, render a supplementary `meta`-typography label/badge reading "DNF · pending period close" alongside the existing `status-cell` (which keeps showing its normal `pending` color + ellipsis glyph — do not invent a sixth `status-cell` glyph; DESIGN.md's `status-cell` component defines exactly five: ✓ / ✕ / C / ellipsis / dash, with no DNF-specific glyph). This satisfies UX-DR20's "distinct DNF 'pending period close' treatment" as a goal-row-level annotation layered on top of the Pending status-cell, not a new calendar color.
  - [x] 4.3 Once the period closes and `evaluate()` returns anything other than `pending` for that date/period, the presentation layer must stop reading `dnfMarked` entirely for display purposes — render only the real `DayStatus` (success/fail/cheat/empty), with no leftover "DNF" label. Since `dnfMarked` is never an `evaluate()` input, this is naturally achieved by gating the Task 4.2 badge strictly on `DayStatus == pending`; no explicit "clear the DNF flag" write is needed or should be performed (the underlying `GoalLog.dnfMarked` value can remain `true` in storage indefinitely — it simply stops being read once the period is no longer pending).

## Dev Notes

- **`dnfMarked` is presentation-only, by explicit architecture statement — this is the one rule this whole story exists to protect.** Quote it exactly when implementing: "`GOAL_LOG.dnfMarked` (FR-17) is a display-only annotation, not an `evaluate()` input — it is superseded by the period's actual computed outcome once that period closes, per FR-17." [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md — Core-entity relationships]
- **Why no explicit "clear DNF" write exists (Task 4.3)**: because `evaluate()` never reads `dnfMarked`, there is no correctness reason to ever unset it once the period resolves — the presentation layer's own gating on `DayStatus == pending` is sufficient and simpler than adding a write-time "supersede" step, which would just be redundant bookkeeping. Don't add one.
- **No new `status-cell` glyph.** DESIGN.md's `status-cell` component is fixed at five glyphs (✓ / ✕ / C / ellipsis / dash) for the five `DayStatus` values (success/fail/cheat/pending/empty). DNF is not a sixth `DayStatus` value — it is a `GoalLog`-level flag surfaced as extra text on the `goal-row`, matching how DESIGN.md describes `goal-row` carrying supplementary period-level facts "surfaced on tap-through" rather than as row-level status-cell iconography. [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components — status-cell, goal-row]
- **AD-6**: `markDnf` is a `GoalLog` write and must route through `GoalService` only, in a transaction. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6]
- **Anti-duplication**: reuse the exact same shared sheet component (`day_row_action_sheet.dart`) Stories 1.6 and 2.4 already extended — this is now a three-action sheet (Blackout Date, Cheat Day, DNF). Do not create a fourth surface for DNF. Reuse `GoalServiceResult`/`GoalServiceFailure` and the transaction pattern from Story 2.1 onward.
- **Testing standards**: unit-test `markDnf` in `test/domain/services/goal_service_test.dart` — marking DNF on a currently-pending eligible day succeeds and sets the flag without disturbing an existing log's `value`/`completed`; marking DNF on a non-eligible day, or a day whose period has already resolved, is rejected with `notEligibleOrAlreadyResolved`; a placeholder log is created correctly when none existed. Unit-test the "silently superseded" behavior end-to-end: mark a day DNF while its period is Pending, then log enough to make the period resolve Success, then assert `evaluate()`'s output for that period is Success with no reference to the DNF flag anywhere in the computation — this is the regression test that actually proves AC 2/3, not just a unit test of the flag's storage. Widget-test that the DNF badge appears only while `DayStatus == pending` and disappears once resolved, without any additional write happening at the moment it disappears.

### Project Structure Notes

- Extends `lib/data/drift/tables/goal_logs_table.dart` (possibly, pending the Task 1.1 check), `lib/domain/services/goal_service.dart`, `goal_service_result.dart`, and `lib/presentation/components/day_row_action_sheet.dart` — all files established or extended earlier in this epic. No new top-level screen/service files.
- **Open question (flagged per this task's instructions, not silently resolved)**: whether `GOAL_LOG.dnfMarked` already exists from Epic 1's initial migration, or must be added here, could not be settled by reading epics.md/ARCHITECTURE-SPINE.md alone — the ERD lists it without the kind of explicit epic-timing caveat given to `CHEAT_DAY`/`BLACKOUT_DATE`. Task 1.1 requires checking the actual Epic 1 migration file at implementation time before assuming either branch; this is a genuine ambiguity, not a design choice, and should be confirmed rather than guessed.
- **Open question**: exact filename of the shared long-press sheet from Story 1.6 (assumed `day_row_action_sheet.dart` throughout Stories 2.4/2.5 in this pass) should be verified against the real Story 1.6 file once it exists, since Epic 1 stories were not available to read verbatim during this Epic 2 authoring pass.

### References

- [Source: docs/epics.md#Story 2.5: DNF Marking]
- [Source: docs/epics.md#Story 1.6: Blackout Dates]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md — Core-entity relationships]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components — status-cell, goal-row]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#State Patterns]
- [Source: docs/prd/4-features.md#FR-17: DNF Marking]
- [Source: docs/stories/2-4-cheat-days.md — shared sheet component, `GoalServiceResult` pattern]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `flutter analyze`: clean (same 6 pre-existing `prefer_initializing_formals` infos on `GoalService`'s constructor as before this story; no new categories).
- `flutter test`: 223/223 passing (full suite, no regressions).

### Completion Notes List

- **Task 1** — `dnfMarked` already existed: `GoalLogs` in `lib/data/drift/tables.dart` (the project's real single-file table convention, not the story's assumed `tables/goal_logs_table.dart` split), the `GoalLog` domain entity, and `DriftGoalLogRepository` all already carry it, with an existing comment confirming "the field exists from Story 1.1 onward." `AppDatabase.schemaVersion` is still `1` (confirmed against Story 2.4's note that no `onUpgrade` migration exists anywhere in this codebase yet) — no schema change made, nothing to flag as newly-added.
- **Task 2** — `GoalService.markDnf` added. Re-validates eligibility at write time by calling the domain's single `evaluate()` entry point with the goal's full Versions/Logs/BlackoutDates/CheatDays (AD-4). This required adding a one-shot `findAllForGoal(goalId)` method to all four repository interfaces (`GoalVersionRepository`, `GoalLogRepository`, `BlackoutDateRepository`, `CheatDayRepository`) plus their Drift implementations and the test `InMemory*` fakes — `GoalService` never needed to call `evaluate()` itself before this story, and none of the existing repository methods exposed a one-shot "every row for this goal" read (only reactive `watch*` streams, or narrower single-row/ranged queries). Rejects with `notEligibleOrAlreadyResolved` whenever the resolved `DayStatus != pending`, which uniformly covers not-yet-eligible, already-resolved (success/fail), and the FR-5 zero-eligible-days case without any separate branching. Both the existing-log update and the placeholder insert go through `GoalLogRepository.upsertLog` inside one `TransactionRunner.run` (AD-6).
- **Task 3** — confirmed, no change: `evaluate()` was not touched anywhere in this story.
- **Task 4** — extended the actual sheet component, `lib/presentation/components/cheat_blackout_sheet.dart` (Story 1.6/2.4's real filename, not the story's assumed `day_row_action_sheet.dart`), with a third "Mark DNF" section gated on the sheet's own live `evaluate()` call — the exact same per-cell `evaluate()` pattern Day/Week/Month View already use, so the action simply isn't offered when the day isn't currently `pending`. This required changing `showCheatBlackoutSheet`'s signature from `goalId` to the full `Goal` (the sheet needs `goal.startDate` for its own `evaluate()` call), updating all three call sites (Day/Week/Month View); Month View's multi-goal long-press picker now pops the whole `Goal` instead of just its id. Added `GoalRow.showDnfBadge`, rendering the "DNF · pending period close" `meta`-text beneath the goal name; callers gate it on `DayStatus == pending && log.dnfMarked` (Task 4.3 — no explicit clear-write on resolution, exactly as Dev Notes specify).
- **Known caveat, surfaced during testing and explicitly accepted by Panda for now (not silently resolved)**: for a **Daily-period Boolean goal** (the Create Goal wizard's own default shape), `evaluate()`'s existing Daily/Boolean branch (`_evaluateDay` in `evaluate.dart`) treats *any* existing `GoalLog` row as resolved — no row → `pending`, `completed: false` → `fail`, `completed: true` → `success`; there is no third state. Since Task 2.3 mandates the placeholder be `completed: false`, and Task 3 forbids touching `evaluate()`, a DNF-marked Daily/Boolean day reads back as an immediate Fail rather than staying Pending with the badge — AC 1's distinct "pending period close" treatment does not actually render for this specific goal shape, for as long as it's left unfinished. AC 2/3 still hold regardless: the placeholder is provably never an `evaluate()` input, and a later real log always overrides it correctly (verified by a regression test). Counter-tracked goals and any period-type (Weekly/Monthly/etc.) Boolean goal are unaffected, since their `evaluate()` branches treat an unfinished log the same as no log at all. Discussed directly with Panda; decision was to ship as literally specified and revisit later rather than expand this story's scope into an `evaluate()` change. Locked in with two widget tests: one proving the full badge-appears/badge-disappears round trip on a Counter goal (where the collision doesn't occur), and one pinning down the accepted Daily+Boolean Fail-instead-of-badge behavior as a documented, intentional caveat rather than a silent gap.
- **Testing** — added a "markDnf (Story 2.5)" group to `goal_service_test.dart`: Pending-day success including the exact placeholder shape, an existing (still-Pending, Counter) log's update-in-place without disturbing `value`, rejection of a never-eligible date, rejection of an already-resolved date, the AC 2/3 "silently superseded" regression against a real `GoalService`-persisted mark and a real Weekly goal resolving to Success, and a transaction-atomicity kill test. Added three widget tests to `day_view_test.dart`: the DNF badge round-trip on a Counter goal, confirmation that an already-resolved day never offers "Mark DNF", and the documented Daily+Boolean caveat above.

### File List

- `lib/domain/services/goal_service.dart` — added `markDnf`; new imports (`day_status.dart`, `evaluate.dart`)
- `lib/domain/services/goal_service_result.dart` — added `notEligibleOrAlreadyResolved`
- `lib/domain/services/goal_version_repository.dart` — added `findAllForGoal`
- `lib/domain/services/goal_log_repository.dart` — added `findAllForGoal`
- `lib/domain/services/blackout_date_repository.dart` — added `findAllForGoal`
- `lib/domain/services/cheat_day_repository.dart` — added `findAllForGoal`
- `lib/data/repositories/drift_goal_version_repository.dart` — implemented `findAllForGoal`
- `lib/data/repositories/drift_goal_log_repository.dart` — implemented `findAllForGoal`
- `lib/data/repositories/drift_blackout_date_repository.dart` — implemented `findAllForGoal`
- `lib/data/repositories/drift_cheat_day_repository.dart` — implemented `findAllForGoal`
- `lib/presentation/components/cheat_blackout_sheet.dart` — added "Mark DNF" section; signature changed `goalId` → `goal`; live `evaluate()`-based gating
- `lib/presentation/components/goal_row.dart` — added `showDnfBadge`
- `lib/presentation/screens/day_view.dart` — pass `goal` to the sheet; compute/pass `showDnfBadge`
- `lib/presentation/screens/week_view.dart` — updated sheet call site for the `goal:` signature change
- `lib/presentation/screens/month_view.dart` — updated both sheet call sites; long-press goal picker now returns the `Goal`, not just its id
- `test/domain/services/fakes.dart` — `findAllForGoal` on all four `InMemory*` repositories
- `test/domain/services/goal_service_test.dart` — `markDnf` test group
- `test/presentation/day_view_test.dart` — three new widget tests (badge round-trip, no-DNF-when-resolved, Daily+Boolean caveat)
