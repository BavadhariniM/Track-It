---
baseline_commit: NO_VCS
---

# Story 2.3: Archive, Expire, and Delete = Archive

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want archiving a goal (including via "Delete") to hide it from active views while keeping full history, and an end-dated goal to expire on its own,
so that nothing I've tracked is ever silently lost.

## Acceptance Criteria

1. **Given** an Active or Paused goal, **when** Panda taps "Delete" or "Archive," **then** the same operation runs — the goal's state becomes Archived; there is no hard delete (FR-2, FR-35).
2. **Given** an Archived goal, **when** Panda views active tracking surfaces (Dashboard, Day/Week/Month), **then** it does not appear; **when** Panda views historical/stats surfaces, **then** it remains fully visible (FR-2 consequence).
3. **Given** a goal with an end date, **when** that end date passes, **then** its state becomes Expired automatically, without Panda manually archiving it (FR-2).
4. **And** for any Archived or Expired goal, all GoalVersions and GoalLogs remain intact and unmodified (FR-35 consequence).

## Tasks / Subtasks

- [x] Task 1: `GoalService.archiveGoal` (AC: 1, 4)
  - [x] 1.1 Added `archiveGoal({required String goalId})` to `lib/domain/services/goal_service.dart`. No schema migration needed — `GOAL.archived` already existed.
  - [x] 1.2 `archiveGoal` writes no `GoalVersion`/`GoalLog` rows — a direct `GOAL.archived` flag flip via a new `GoalRepository.findById`/`updateGoal`, not `_writeVersionSegment`.
  - [x] 1.3 Idempotent: re-archiving an already-archived goal just re-writes `archived = true` and succeeds.
  - [x] 1.4 The read + UPDATE run inside `_transactionRunner.run(...)`.
  - [x] 1.5 Confirmed no `CacheWriter` exists yet in this codebase (Epic 3 concern) — nothing to avoid calling.
- [x] Task 2: Extend the lifecycle-status resolver from Story 2.2 (AC: 2, 3)
  - [x] 2.1 Added `archived`/`expired` branches to `resolveLifecycleStatus` in `lib/domain/entities/goal_lifecycle_status.dart` — same function, not a second resolver.
  - [x] 2.2 Precedence implemented exactly as specified: `archived` → `expired` (`today > endDate`, strict) → `paused` → `active`.
  - [x] 2.3 `expired` is a pure read-time computation only — no write path exists for it.
- [x] Task 3: Presentation — filter active vs. historical surfaces, wire Delete/Archive (AC: 1, 2)
  - [x] 3.1 Extended Day View (`_GoalRowForDate`), Week View (`_WeekBody`), and Month View (`_buildGrid`'s `goalData`/`visibleGoals`) to call `resolveLifecycleStatus` at the same call site as Story 2.2's `isPausedOn` check and omit Archived/Expired goals.
  - [x] 3.2 Confirmed Goal Detail (`goal_detail_screen.dart`) renders unconditionally regardless of lifecycle status — no exemption code needed since it was never filtered.
  - [x] 3.3 Extended `goals_list_screen.dart` with an Active/Paused/Archived/Expired grouped list (`_GroupedGoalsList`).
  - [x] 3.4 Added an "Archive" `button-secondary` action to Goal Detail, wired to `archiveGoal`, single-tap, no confirmation dialog, with a `SnackBar` showing the exact EXPERIENCE.md copy verbatim.

## Dev Notes

- **AD-6 still applies but this is a distinct write shape from 2.1/2.2**: `archiveGoal` is a `GoalService`-owned write (AD-6's scope covers "every edit that changes target/eligible-days/lifecycle state"), but it is a direct `GOAL.archived` flag write, not a new `GoalVersion`. Do not force this into the versioning write path — archiving has no "effective date," no dated segment, and no collision to resolve. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6]
- **FR-35 consequence (AC 4) is a non-event, not a task**: because `archiveGoal` never touches `GoalVersion`/`GoalLog` rows, "all GoalVersions and GoalLogs remain intact and unmodified" is satisfied by construction — there is nothing to write to preserve. The only thing to get right is that no code path treats archiving as a cascading delete/mutation.
- **Reuses Story 2.2's `resolveLifecycleStatus`, extended, not duplicated.** This is the second story in a row to extend that one function — see Story 2.2's Dev Notes for the `paused` branch this story adds `archived`/`expired` on top of. [Source: docs/stories/2-2-pause-and-resume-a-goal.md — `resolveLifecycleStatus`]
- **"Delete" vs. "Archive" labeling is not pinned by DESIGN.md/EXPERIENCE.md** — FR-35 only guarantees the two are the *same operation*, not that the UI must show both words. This story recommends a single button (label "Delete" or "Archive," implementer's choice) calling the one `archiveGoal` method, since showing two separate buttons that both silently archive risks confusing Panda into thinking they are different actions. Flagged as an open UX-copy decision, not a blocking ambiguity.
- **UX-DR24 / voice-tone copy**: archive stays single-tap; the exact confirmation copy "Archived Goals leave active views but keep full history" is given verbatim in EXPERIENCE.md and should be reused exactly, not paraphrased, to stay consistent with the specific-reason copy rule (UX-DR19). [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Voice and Tone]
- **AD-7 boundary check**: confirm in code review that `archiveGoal` never calls `CacheWriter` — AD-7's cache-write trigger list (`GoalLog` commit / `GoalVersion` commit / midnight-rollover job) does not include archiving, and adding a spurious cache write here would be scope creep against AD-7's "exactly one writer" invariant being invoked only at its defined trigger points. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-7]
- **Testing standards**: unit-test `resolveLifecycleStatus`'s full precedence order exhaustively in `test/domain/entities/` — an archived-and-past-end-date goal resolves `archived`; a paused-and-past-end-date goal resolves `expired` (expired outranks paused); a goal exactly on its end date (not yet past) is still `active`/`paused` as applicable, not `expired` — pin the boundary (`today > endDate`, strictly after, not on). Unit-test `archiveGoal`'s idempotency. Widget/integration-test that Day/Week/Month/Dashboard omit archived/expired goals while Goal Detail and the Goals list's historical grouping still render them.

### Project Structure Notes

- No Drift schema/migration change in this story — `GOAL.archived` already exists per the Epic 1-established schema.
- Extends `lib/domain/entities/goal_lifecycle_status.dart` and reuses `lib/presentation/screens/goal_detail_screen.dart` and `lib/presentation/screens/goals/goals_list_screen.dart`, all introduced in Stories 2.1/2.2 — no new top-level screen files for this story. Story 3.2 (Epic 3) later extends `goal_detail_screen.dart` further with stats/timeline; the Archived-state handling built here must remain intact when that happens.
- **Open question carried forward**: same Goal Detail/Goals-list ownership question flagged in Story 2.1 — confirm with the architect/PM whether Story 3.5's full category filtering (FR-25) is meant to replace or extend the lifecycle-status grouping this story adds to `goals_list_screen.dart`, so the two stories don't build conflicting filter UIs on the same screen.

### References

- [Source: docs/epics.md#Story 2.3: Archive, Expire, and Delete = Archive]
- [Source: docs/epics.md#Epic 2: Goal Lifecycle, Versioning & Cheat Days]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-7]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md — Core-entity relationships]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Voice and Tone]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Interaction Primitives]
- [Source: docs/prd/4-features.md#FR-2: Goal Lifecycle]
- [Source: docs/prd/4-features.md#FR-35: Delete = Archive]
- [Source: docs/stories/2-1-edit-a-goals-rules-mid-stream.md — minimal Goal Detail/Goals list screens]
- [Source: docs/stories/2-2-pause-and-resume-a-goal.md — `resolveLifecycleStatus`, active-surface filtering pattern]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

### Completion Notes List

- Task 1: `GoalRepository` gained `findById`/`updateGoal` (mirroring `GoalVersionRepository`'s existing pattern) so `archiveGoal` can read-modify-write inside one transaction without a new failure-reason enum — the `goalId` precondition (must reference an existing Goal) is trusted rather than defensively checked, matching every caller (Goal Detail always holds the Goal it's archiving).
- Task 3.1: Month View's `_buildGrid` now derives a `visibleGoals` list (goals with a `goalData` entry) used for both the day-cell aggregation and the long-press goal picker, so an archived goal disappears from both consistently rather than needing two separate filters.
- Task 3.3: `goals_list_screen.dart`'s `_GroupedGoalsList` groups by `resolveLifecycleStatus`, keyed `goals-list-group-<status.name>`, rendering only non-empty groups in Active/Paused/Archived/Expired order.
- Full suite verified directly: `dart analyze` clean (5 pre-existing infos only), `flutter test` 202/202 passing (188 pre-existing + 14 new: `archiveGoal` idempotency/atomicity/AC-4-non-mutation coverage, `resolveLifecycleStatus` precedence-order unit tests, and Day/Week/Month/Goal Detail/Goals List widget coverage for archived exclusion).

### File List

- `lib/domain/services/goal_repository.dart` (modified — `findById`, `updateGoal`)
- `lib/data/repositories/drift_goal_repository.dart` (modified — `findById`, `updateGoal`)
- `lib/domain/services/goal_service.dart` (modified — `archiveGoal`)
- `lib/domain/entities/goal_lifecycle_status.dart` (modified — `archived`/`expired` branches)
- `lib/presentation/screens/day_view.dart` (modified — lifecycle-status gate before `evaluate()`)
- `lib/presentation/screens/week_view.dart` (modified — lifecycle-status skip in `_WeekBody`)
- `lib/presentation/screens/month_view.dart` (modified — `visibleGoals`/`goalData` lifecycle filtering)
- `lib/presentation/screens/goal_detail_screen.dart` (modified — Archive `SecondaryButton`, `SnackBar` confirmation)
- `lib/presentation/screens/goals/goals_list_screen.dart` (modified — `_GroupedGoalsList` by lifecycle status)
- `test/domain/services/fakes.dart` (modified — `InMemoryGoalRepository.findById`/`updateGoal`/`shouldFailOnUpdate`)
- `test/domain/services/goal_service_test.dart` (modified — `archiveGoal` AC 1/4 + idempotency + atomicity coverage)
- `test/domain/entities/goal_lifecycle_status_test.dart` (modified — archived/expired precedence coverage)
- `test/presentation/day_view_test.dart` (modified — archived-goal row omission)
- `test/presentation/week_view_test.dart` (modified — archived-goal status-cell omission)
- `test/presentation/month_view_test.dart` (modified — archived-goal aggregation exclusion)
- `test/presentation/goal_detail_screen_test.dart` (modified — Archive button + confirmation)
- `test/presentation/goals_list_screen_test.dart` (new — lifecycle-status grouping)
