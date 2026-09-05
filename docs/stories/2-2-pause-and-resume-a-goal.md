---
baseline_commit: NO_VCS
---

# Story 2.2: Pause and Resume a Goal

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to pause a goal and resume it later,
so that I can step away from a commitment temporarily without it counting against me or losing its history.

## Acceptance Criteria

1. **Given** an Active goal, **when** Panda pauses it, **then** its state becomes Paused, recorded as a new dated GoalVersion segment (FR-2, FR-3).
2. **Given** a Paused goal's date range, **when** the calendar or evaluator considers that range, **then** it produces no Eligible Days at all for those dates — not Empty, not Pending (FR-2 consequence).
3. **Given** a Paused goal, **when** Panda resumes it, **then** it becomes Active again from the resume date forward, recorded as another new Version segment (FR-2).
4. **And** this pause/resume mechanism reuses Story 2.1's versioning write path rather than a separate one.

## Tasks / Subtasks

- [x] Task 1: Extend the schema with a pause flag (AC: 1, 2, 3)
  - [x] 1.1 Confirmed the `isPaused BOOLEAN NOT NULL DEFAULT FALSE` column already exists on the `GOAL_VERSION` Drift table (`lib/data/drift/tables.dart`) and the `GoalVersion` domain entity (`lib/domain/entities/goal_version.dart`) — Story 1.1 added it and Story 1.3's `evaluate()` already reads it for eligible-day pool computation. No schema migration needed.
  - [x] 1.2 Confirmed `GoalVersionDraft` has no `isPaused` field — pause/resume do not go through it.
- [x] Task 2: `GoalService.pauseGoal` / `resumeGoal`, reusing Story 2.1's write path (AC: 1, 3, 4)
  - [x] 2.1 Added `pauseGoal`/`resumeGoal` to `lib/domain/services/goal_service.dart`.
  - [x] 2.2 Both call the shared private `_writeVersionSegment` helper via a new private `_writePauseState` wrapper — same AD-6 collision algorithm as `editGoalVersion`, no parallel write path.
  - [x] 2.3 `pauseGoal` writes `isPaused = true` with every other rule field copied forward from the Version governing `effectiveDate` (added `GoalVersionRepository.findGoverningVersion` to source those fields ahead of the write; the in-transaction `existing` row is preferred over the pre-fetched one when a same-day collision occurs).
  - [x] 2.4 `resumeGoal` writes `isPaused = false`, same rule-forwarding mechanism.
  - [x] 2.5 Both commit inside `_writeVersionSegment`'s single Drift transaction.
- [x] Task 3: Goal-lifecycle-status resolver (AC: 1, 2, 3)
  - [x] 3.1 Added `lib/domain/entities/goal_lifecycle_status.dart` with `GoalLifecycleStatus` and `resolveLifecycleStatus()`.
  - [x] 3.2 Implemented the `paused` branch only, per the latest Version with `versionStartDate <= today`.
  - [x] 3.3 Added `lib/domain/services/paused_range_helper.dart` exposing `isPausedOn(versions, date)`.
- [x] Task 4: Presentation — filter paused ranges out of the calendar; wire pause/resume actions (AC: 1, 2, 3)
  - [x] 4.1 Wired `isPausedOn` into Day View (`_GoalRowForDate`), Week View (`_WeekBody`/`_WeekGoalRow`), and Month View (`_MonthGrid._dayCell`) — a paused `(goal, date)` pair never calls `evaluate()` and never renders a status-cell color; Month View excludes it from that day's cross-goal aggregation instead of omitting a whole cell, since it renders one combined cell per day.
  - [x] 4.2 Added a `button-secondary` Pause/Resume action to `GoalDetailScreen`, label toggling via `resolveLifecycleStatus`, single-tap with no confirmation (UX-DR24).
  - [x] 4.3 Effective date defaults to `DateTime.now()` (today), matching Story 2.1's default; pause/resume has no wizard step, so there's no shared date-picker widget to reuse — it writes directly through `GoalService`.

## Dev Notes

- **Reuse mandate (AC 4) — be concrete, not just aspirational**: `pauseGoal`/`resumeGoal` must call the exact same `_writeVersionSegment` private helper `editGoalVersion` uses in Story 2.1, with the same collision algorithm (same-day amend-in-place vs. reject-with-`versionLocked`). If a dev agent is tempted to write a separate "pause version writer," that is the anti-pattern this AC exists to prevent. [Source: docs/epics.md#Story 2.2: Pause and Resume a Goal]
- **Schema, confirmed (not an open item)**: `GOAL_VERSION.isPaused` (boolean, default `false`) is part of ARCHITECTURE-SPINE.md's ER diagram and was added to the `GoalVersion` entity/Drift table in Story 1.1, with `evaluate()` (Story 1.3) already reading it for eligible-day pool computation from day one. FR-4's derived-status philosophy is satisfied the same way as every other lifecycle signal: paused state is a queryable field on the versioned record, never a separately-stored top-level "Paused" flag on `GOAL` itself (which would violate the versioned-history model). This story's job is purely to start *setting* the field via `pauseGoal`/`resumeGoal` — the field, its evaluator-awareness, and its schema migration all shipped in Epic 1. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md — Core-entity relationships, AD-4, AD-5]
- **Two separate, non-duplicating pause mechanisms — do not conflate them**: (1) `evaluate()` itself (Story 1.1/1.3) excludes any date governed by a paused Version from a *period's* eligible-day pool — this is what makes Week/Month rollups, Streaks (Epic 3), and stats correctly ignore paused days without under- or over-counting the period's target. (2) `isPausedOn()` (this story, Task 3.3) is a separate, cheap presentation-layer pre-check used only to decide whether to render a goal-row/status-cell for one specific `(goal, date)` pair on the Day/Week/Month calendar at all — since AC 2 requires paused dates show *neither* Empty *nor* Pending, and DESIGN.md's `status-cell` only defines five glyphs (none of which is "paused"), the calendar simply omits the row rather than rendering any of the five. `isPausedOn()` does not feed into `evaluate()` and does not duplicate its pool-exclusion logic — it answers a narrower, purely cosmetic question ("should this row render today?") that `evaluate()` was never asked. [Source: docs/epics.md#Story 2.2; docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4 — Pure Evaluator Contract]
- **AD-6 still applies**: pause/resume writes are `GoalVersion` writes, so they must go through `GoalService` exclusively — no repository call from presentation. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6]
- **Transaction atomicity**: pause/resume writes commit inside one Drift transaction, identical to Story 2.1's pattern. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Consistency Conventions]
- **UX-DR24**: pause/resume remain single-tap, reversible actions — no secondary confirmation. Only Reset/Erase-All (Epic 6) gets the two-step confirmation. [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Interaction Primitives]
- **Anti-duplication**: reuse Story 2.1's `_writeVersionSegment`, `GoalServiceResult`/`GoalServiceFailure` types, the minimal Goal Detail screen, and the effective-date UI affordance. Do not reinvent any of these.
- **Testing standards**: unit-test `resolveLifecycleStatus`'s `paused` branch and `isPausedOn` exhaustively in `test/domain/entities/` and `test/domain/services/` — cover a date exactly on the pause's `versionStartDate`, a date exactly on the resume's `versionStartDate` (resume date itself is Active again, per AC 3's "from the resume date forward"), and a date strictly inside the paused range. Widget/integration-test that Day/Week/Month/Dashboard omit the goal-row entirely for paused dates (not render it as any status-cell color). Add one integration-level test in this story that pauses a period-based goal (e.g. Weekly "3x/week") mid-period, resumes it before the period ends, and asserts `evaluate()` still judges the period correctly against the shrunk-but-unified eligible-day pool — `evaluate()`'s own pool-exclusion unit tests already live in Story 1.3, so this test is about proving `pauseGoal`/`resumeGoal`'s writes actually produce the Version data `evaluate()` expects, not re-deriving the pool logic itself.

### Project Structure Notes

- `lib/data/drift/tables/goal_versions_table.dart` and `lib/data/drift/app_database.dart` are existing Epic 1 files this story modifies (migration), not new files — confirm current schema version before bumping.
- `lib/domain/entities/goal_lifecycle_status.dart` and `lib/domain/services/paused_range_helper.dart` are new files fitting the seed's `domain/entities/` and `domain/services/` buckets respectively.
- Reuses `lib/presentation/screens/goal_detail_screen.dart` from Story 2.1 — do not create a second Goal Detail screen. Story 3.2 (Epic 3) later extends this same file further with stats/timeline.
- The `GOAL_VERSION.isPaused` approach (versioned segment flag, rather than a separate `GOAL.lifecycleState` column or a dedicated event log) is confirmed as the intended design — it keeps pause/resume inside the existing versioning write path (AC 4's explicit reuse requirement) and lets `evaluate()` treat it as just another Version field.

### References

- [Source: docs/epics.md#Story 2.2: Pause and Resume a Goal]
- [Source: docs/epics.md#Epic 2: Goal Lifecycle, Versioning & Cheat Days]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-3]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Consistency Conventions]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md — Core-entity relationships]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components — status-cell]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Interaction Primitives]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#State Patterns]
- [Source: docs/prd/4-features.md#FR-2: Goal Lifecycle]
- [Source: docs/stories/2-1-edit-a-goals-rules-mid-stream.md — `_writeVersionSegment` helper, `GoalServiceResult` pattern, minimal Goal Detail screen]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

### Completion Notes List

- Task 1 was a confirm-only task: the `isPaused` column/field/evaluator-awareness all already existed from Story 1.1/1.3, so no code changed.
- Task 2: `GoalVersionRepository` gained `findGoverningVersion(goalId, date)` (Drift: `ORDER BY versionStartDate DESC LIMIT 1` where `versionStartDate <= date`; in-memory fake mirrors it) so `pauseGoal`/`resumeGoal` can source the rule fields to carry forward *before* calling `_writeVersionSegment` (whose `buildVersion` callback is synchronous). Inside the transaction, the same-day `existing` row is preferred over the pre-fetched governing Version when both apply, since `existing` is read fresher, but the two are always the same row when both are non-null.
- Task 3: `resolveLifecycleStatus`/`isPausedOn` each carry their own small private "latest Version on or before a date" lookup rather than sharing one, mirroring `evaluate.dart`'s own private `_findGoverningVersion` — kept `domain/entities` and `domain/services` independent of each other rather than introducing a cross-layer import for a 5-line function.
- Task 4.1: Month View excludes a paused goal from that day's `aggregateDayStatus` input list entirely (never calling `evaluate()` for it) rather than omitting the whole grid cell, since Month View renders exactly one combined cell per day across all goals — Day View/Week View, which render one row per goal, omit the row/cell outright.
- Full suite verified directly: `dart analyze` clean (5 pre-existing infos only, same as Story 2.1), `flutter test` 188/188 passing (164 pre-existing + 24 new: `pauseGoal`/`resumeGoal` collision-algorithm coverage, `resolveLifecycleStatus`/`isPausedOn` unit tests, a mid-period pause/resume evaluator integration test, and Day/Week/Month View + Goal Detail widget coverage).

### File List

- `lib/domain/services/goal_version_repository.dart` (modified — `findGoverningVersion`)
- `lib/data/repositories/drift_goal_version_repository.dart` (modified — `findGoverningVersion`)
- `lib/domain/services/goal_service.dart` (modified — `pauseGoal`, `resumeGoal`, `_writePauseState`)
- `lib/domain/entities/goal_lifecycle_status.dart` (new)
- `lib/domain/services/paused_range_helper.dart` (new)
- `lib/presentation/screens/day_view.dart` (modified — `isPausedOn` gate before `evaluate()` in `_GoalRowForDate`)
- `lib/presentation/screens/week_view.dart` (modified — nullable per-day statuses, `isPausedOn` gate, null-aware aggregation)
- `lib/presentation/screens/month_view.dart` (modified — `isPausedOn` exclusion in `_dayCell`'s aggregation)
- `lib/presentation/screens/goal_detail_screen.dart` (modified — Pause/Resume `SecondaryButton`, `resolveLifecycleStatus`-driven label)
- `test/domain/services/fakes.dart` (modified — `InMemoryGoalVersionRepository.findGoverningVersion`)
- `test/domain/services/goal_service_test.dart` (modified — `pauseGoal`/`resumeGoal` AC 1/3/4/5 coverage)
- `test/domain/entities/goal_lifecycle_status_test.dart` (new)
- `test/domain/services/paused_range_helper_test.dart` (new)
- `test/domain/evaluator/pause_resume_evaluation_test.dart` (new — mid-period pause/resume integration test)
- `test/presentation/day_view_test.dart` (modified — paused-date row omission)
- `test/presentation/week_view_test.dart` (modified — paused-date status-cell omission)
- `test/presentation/month_view_test.dart` (modified — paused-goal aggregation exclusion)
- `test/presentation/goal_detail_screen_test.dart` (new — Pause/Resume button)
