---
baseline_commit: NO_VCS
---

# Story 2.1: Edit a Goal's Rules Mid-Stream

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to edit a live goal's schedule or target,
so that I can adjust a commitment as life changes without losing or corrupting the history of days already logged.

## Acceptance Criteria

1. **Given** a goal with logs before today, **when** Panda edits its target/eligible-days/evaluation period effective today, **then** GoalService creates a new dated GoalVersion rather than mutating the existing one (FR-3).
2. **Given** a day was logged before the rule change, **when** that day is re-evaluated, **then** it is evaluated against the GoalVersion that was active on that date, not the new one (FR-3 consequence).
3. **Given** Panda edits the same goal twice on the same calendar day before any log exists against the first edit, **when** the second edit saves, **then** it amends the still-log-free Version in place rather than creating a second Version for the same date (AD-6 — at most one Version per `(goalId, versionStartDate)`).
4. **Given** a GoalLog already exists against a Version, **when** Panda attempts another same-day edit, **then** the edit is rejected and Panda must choose a later effective date instead (AD-6).
5. **And** the edit-creates-a-Version write commits inside a single Drift transaction (Transaction atomicity).

## Tasks / Subtasks

- [x] Task 1: Add the version-write collision algorithm to `GoalService` (AC: 1, 2, 3, 4, 5)
  - [x] 1.1 In `lib/domain/services/goal_service.dart`, add `Future<GoalServiceResult<GoalVersion>> editGoalVersion({required String goalId, required String effectiveDate, required GoalVersionDraft newRules})`. `GoalVersionDraft` (new value object in `lib/domain/entities/goal_version_draft.dart`) carries the editable rule fields (`evaluationPeriod`, `eligibleDaysRule`, `targetComparison`, `targetValue`, `trackingType`, `cheatDayQuota`) — everything on `GOAL_VERSION` except `id`, `goalId`, `versionStartDate`.
  - [x] 1.2 Implement the exact collision rule inside one method (introduce a private helper, e.g. `_writeVersionSegment`, that both this story and Story 2.2's pause/resume call — see Dev Notes for the precise algorithm): look up any existing `GoalVersion` for `goalId` whose `versionStartDate == effectiveDate`. If none exists, INSERT a new `GoalVersion` row with a fresh UUIDv4 id. If one exists and no `GoalLog` exists with `date >= effectiveDate` for this goal, UPDATE that row's rule fields in place (same row id). If one exists and at least one such `GoalLog` exists, return `GoalServiceResult.failure(GoalServiceFailure.versionLocked)` — do not write anything.
  - [x] 1.3 Add `GoalServiceFailure.versionLocked` to the sealed failure type in `lib/domain/services/goal_service_result.dart` (introduce this file now if Epic 1 has not already: a sealed `GoalServiceResult<T>` with `Success(T value)` / `Failure(GoalServiceFailure reason)`, per the architecture's Result/Either convention — no thrown exceptions). Give `versionLocked` a message payload suitable for the specific-reason copy rule (UX-DR19): e.g. "This goal already has entries logged under today's version — choose a later effective date."
  - [x] 1.4 Wrap the existence-check read plus the INSERT/UPDATE write in one Drift transaction (`db.transaction(...)`), so a kill mid-write can never leave a half-written Version (AC 5).
- [x] Task 2: Repository support for the collision check (AC: 3, 4)
  - [x] 2.1 Add `Future<GoalVersion?> findByGoalIdAndStartDate(String goalId, String versionStartDate)` to the `GoalVersionRepository` interface (`lib/domain/services/`) and its Drift implementation `DriftGoalVersionRepository` (`lib/data/repositories/`).
  - [x] 2.2 Add `Future<bool> existsOnOrAfter(String goalId, String date)` to `GoalLogRepository` / `DriftGoalLogRepository` for the "any GoalLog against this Version" check.
  - [x] 2.3 No Drift schema change is required — `GOAL_VERSION` already has every column this story needs, per the ARCHITECTURE-SPINE.md ERD.
- [x] Task 3: Confirm evaluator reuse, do not touch `evaluate()` (AC: 1, 2)
  - [x] 3.1 No changes to `lib/domain/evaluator/`. Epic 1 already built `evaluate()`'s `versions` parameter and AD-5's version-boundary splitting; this story is the first to actually exercise it against a second, real, GoalService-written Version. Add regression tests (Task 5) rather than modifying evaluator source.
- [x] Task 4: Presentation — edit entry point (AC: 1, 3, 4)
  - [x] 4.1 Add a minimal Goal Detail screen at `lib/presentation/screens/goal_detail_screen.dart` (flat file directly under `screens/`, matching the Structural Seed's naming — not a `goal_detail/` subfolder), reached by tapping a goal row from the Goals list. This is the first version of this screen in the app (Epic 1 does not build it — FR-27's full Goal Detail with Streak/Version Timeline/stats is Story 3.2). It shows the goal name, a plain-language summary of its current (latest) Version's rules, and a `button-secondary` "Edit" action (UX-DR10). Story 3.2 extends this exact same file with `stat-card`s/historical calendar/Version Timeline — confirmed shared ownership, do not create a second, competing Goal Detail screen.
  - [x] 4.2 If Epic 1 has not already built a bare Goals list surface, add a minimal one at `lib/presentation/screens/goals/goals_list_screen.dart` so goal rows are reachable outside of Day View (Day View's goal-row tap toggles Boolean/opens the Counter stepper per Story 1.1, it does not open Goal Detail).
  - [x] 4.3 Reuse the Story 1.9 guided wizard (`lib/presentation/screens/goal_wizard/`) in "edit mode": pre-fill every step from the goal's current (latest) Version, and surface an effective-date field (default: today) on the dates step only when in edit mode.
  - [x] 4.4 On Save, call `goalServiceProvider.editGoalVersion(...)`. On `GoalServiceFailure.versionLocked`, keep the wizard open on the dates step, show the specific inline message from Task 1.3 (UX-DR19: no exclamation points, names the exact reason), and require Panda to pick a later date before Save re-enables.
  - [x] 4.5 The wizard's existing Review step (built in 1.9) restates the edited rule in one plain-language sentence before committing (UX-DR15) — reuse it unchanged.
- [ ] Task 5: Testing (AC: 1, 2, 3, 4, 5)
  - [x] 5.1 Unit test `test/domain/services/goal_service_test.dart`: same-day double edit before any log amends the existing row in place (row count unchanged, same id, new field values).
  - [x] 5.2 Unit test: edit attempted same-day after a GoalLog exists against that Version returns `Failure(versionLocked)` and writes nothing.
  - [x] 5.3 Unit test: edit at a later effective date succeeds even when the current Version has logs against it.
  - [x] 5.4 Unit test (evaluator regression, `test/domain/evaluator/`): a day logged under Version A, then a real GoalService-created Version B effective later, re-evaluating the earlier day still returns Version A's outcome (AC 2) — confirms AD-5's boundary splitting holds with GoalService-authored data, not just synthetic Epic 1 fixtures.
  - [x] 5.5 Widget test: edit wizard pre-fills from the current Version; the effective-date field/error path from Task 4.4 renders correctly on `versionLocked`.

## Dev Notes

- **AD-6 is the load-bearing rule for this whole story.** `GoalService` is the only component permitted to write a `GoalVersion` — no repository call from presentation, and no write from the wizard's save handler except through `GoalService`. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6]
- **Exact collision algorithm** (write this precisely, it is the crux of AC 1/3/4): given `(goalId, effectiveDate)` —
  1. Query for an existing `GoalVersion` where `versionStartDate == effectiveDate`.
  2. If none → INSERT a new row (new Version segment; this is the normal "edit effective today/future" path, AC 1).
  3. If one exists and no `GoalLog` for this goal has `date >= effectiveDate` → UPDATE that row's rule columns in place, same primary key (AC 3 — "amends the still-log-free Version in place").
  4. If one exists and at least one such `GoalLog` exists → reject, `versionLocked` (AC 4).
  This is exactly the rule stated in ARCHITECTURE-SPINE.md's AD-6 text: "at most one `GoalVersion` per `(goalId, versionStartDate)`... a same-day second edit amends the still-log-free Version in place; once any `GoalLog` exists against it, a same-day edit is rejected." [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6]
- **AD-5 (version-boundary splitting)** already exists from Epic 1 and must not be touched: a Version's window is `[versionStartDate, nextVersion.startDate or goal end]`; the evaluator truncates at the boundary and evaluates each segment against its own un-prorated target. This story only proves that logic against real, persisted multi-version data for the first time. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-5]
- **AD-4 (pure evaluator)**: `evaluate()`'s signature already takes `versions` (per Epic 1's implementation note in epics.md: "the function's signature takes `versions` from day one"). Do not add parameters or branches to `evaluate()` for this story — the version-selection-by-date logic already lives there. [Source: docs/epics.md#Epic 1 Implementation notes; docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4]
- **`GOAL_LOG` carries no stored Version FK** — which Version governs a log is resolved at evaluation time by matching `date` against Version windows, never stored. This is why the "does a GoalLog exist against this Version" check in the collision algorithm is a date-range query (`date >= versionStartDate`), not a foreign-key lookup. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md — Core-entity relationships note]
- **Transaction atomicity**: the existence-check + INSERT/UPDATE must be one Drift transaction — a multi-statement domain mutation per the Consistency Conventions table. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Consistency Conventions]
- **Data conventions**: new `GoalVersion` ids are UUIDv4 strings; `effectiveDate` and all dates are naive ISO-8601 date-only strings (`YYYY-MM-DD`), never timezone-aware `DateTime`. Failures are returned via `GoalServiceResult`/sealed-failure types, never thrown. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Consistency Conventions]
- **Anti-duplication**: reuse the Story 1.9 wizard for editing — do not build a second, separate "edit goal" form. Reuse Epic 1's `evaluate()` unchanged. Reuse the `GoalVersionRepository`/`GoalLogRepository` interfaces already defined in `domain/services` from Epic 1, extending them rather than adding parallel repository interfaces.
- **UX tokens**: `button-secondary` for Edit (UX-DR10, never a tertiary/ghost style); Review step plain-language restatement (UX-DR15); no exclamation points and a specific, named reason on the `versionLocked` rejection message (UX-DR19 voice/tone — "Import-conflict and validation copy names the exact problem... never a generic 'Something went wrong'" applies equally to this rejection). [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components; docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Voice and Tone]
- **FR-9 regression risk**: custom recurrence (every-N-days etc., Story 1.5) anchors to the *Goal's* `startDate`, not any Version's `versionStartDate`. Editing a goal's rules must never re-anchor these cycles — confirm this stays true in the regression tests (Task 5.4 scope extends naturally here since it exercises real multi-version evaluation).
- **Testing standards**: unit-test the collision algorithm exhaustively in `test/domain/services/` (mirrors `lib/domain/services`, per the Structural Seed's `test/domain/` convention extended to services). Widget-test only the wizard's pre-fill and error-surfacing behavior — never re-test evaluator correctness at the widget layer (NFR-6's correctness bar lives in the domain unit tests).

### Project Structure Notes

- `lib/domain/services/goal_service.dart` and `lib/domain/services/goal_service_result.dart` are extensions of files the Structural Seed places in `domain/services/` — consistent with Epic 1's `GoalService` (AD-6) and `StatsService` (AD-8) living there. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed]
- `lib/domain/entities/goal_version_draft.dart` fits the seed's `domain/entities/` bucket alongside `Goal`, `GoalVersion`, `GoalLog`, `CheatDay`, `BlackoutDate`, `DayStatus`.
- `lib/presentation/screens/goal_detail_screen.dart` and `lib/presentation/screens/goals/goals_list_screen.dart` fit the seed's `presentation/screens/` bucket ("daily entry, goal detail, calendar..., dashboard, settings") — flat files directly under `screens/`, per the seed's literal naming, not per-screen subfolders.
- **Screen ownership (confirmed):** this story creates the minimal Goal Detail screen (schedule/target summary, Edit action) since Epic 2's edit/pause/archive actions need a UI home before Epic 3 exists. Story 3.2 extends this exact same file with `stat-card`s, the historical calendar, and the Version Timeline, rather than creating a second file. Story 2.2 adds the Pause/Resume button and Story 2.3 adds Archive-state handling to this same file before Story 3.2 extends it further — treat it as one continuously-extended screen across Stories 2.1 → 2.2 → 2.3 → 3.2, never a competing second implementation.

### References

- [Source: docs/epics.md#Story 2.1: Edit a Goal's Rules Mid-Stream]
- [Source: docs/epics.md#Epic 2: Goal Lifecycle, Versioning & Cheat Days]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-5]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Consistency Conventions]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components — button-primary/button-secondary]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Voice and Tone]
- [Source: docs/prd/4-features.md#FR-3: Goal Versioning]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

### Completion Notes List

- Tasks 1-3 (domain-layer collision algorithm, repository support, evaluator regression coverage) and Task 5.1-5.4 unit/regression tests were implemented in an earlier session and verified against the full test suite (162/162 passing, `dart analyze` clean apart from 3 pre-existing unused-import warnings in `goal_wizard_provider.dart` staged for Task 4.3) before resuming Task 4.
- Task 4: added `GoalDetailScreen` (goal name, plain-language rule summary via a reused `buildReviewSentence`, `button-secondary` Edit action — the component's first use in the app) and a minimal `GoalsListScreen`, reached from Month View's app-bar (no persistent tab bar exists yet). Extended the Story 1.9 wizard with an `isEditMode` path: `GoalWizard.loadForEdit` pre-fills every step from the goal's latest Version; `RecurrenceSelector` gained an optional `initialPattern` param (backward-compatible, `null` preserves the exact prior create-mode default) so the Schedule step's eligible-days pre-fill actually sticks; the Name step renders read-only in edit mode since `editGoalVersion` has no way to persist a name/description change (Story 2.1's scope is schedule/target only); the Dates step swaps Start/End date for a single effective-date field defaulting to today.
- Task 4.4: Review step's Save branches to `editGoalVersion` in edit mode; on `GoalServiceFailure.versionLocked` the wizard jumps back to the Dates step (`GoalWizard.reportVersionLocked`) showing the exact UX-DR19 message, and `datesStepValid`/`reviewStepValid` stay false until Panda picks a later effective date (`effectiveDateClearsLock`), which also disables Save via the same validity-chaining every other step already uses.
- Made `goalWizardProvider` `@Riverpod(keepAlive: true)`: edit-mode pre-fill is applied synchronously from `GoalDetailScreen`'s Edit button (before the wizard route is pushed) so `TextEditingController`s that seed themselves once in their own `initState` (Name/Target steps) see the pre-filled data on the wizard's first build — an autoDispose provider was getting torn down in the gap between that call and the new screen's first watch, and deferring the load via `addPostFrameCallback` (the pattern used elsewhere for build-time-safety) arrived one frame too late for those controllers. Both entry points (`DayViewScreen`'s "Create Goal" and `GoalDetailScreen`'s "Edit") now fully initialize the state they need before pushing (`reset()` / `loadForEdit()` respectively), so no exit path needs to clean up after itself.
- Task 5.5: `test/presentation/goal_edit_wizard_test.dart` covers the wizard's edit-mode pre-fill (Name/Tracking Type/Schedule/Target steps, effective-date tile replacing Start/End date) through to a successful amend-in-place Save, and the `versionLocked` rejection rendering its specific message on the Dates step with Save disabled until a later date is chosen.
- Full suite verified directly (not just self-reported): `dart analyze` clean (5 pre-existing infos only), `flutter test` 164/164 passing (162 pre-existing + 2 new).

### File List

- `lib/domain/services/goal_service_result.dart` (new)
- `lib/domain/entities/goal_version_draft.dart` (new)
- `lib/domain/services/goal_service.dart` (modified — `editGoalVersion`, `_writeVersionSegment`)
- `lib/domain/services/goal_version_repository.dart` (modified — `findByGoalIdAndStartDate`)
- `lib/data/repositories/drift_goal_version_repository.dart` (modified)
- `lib/domain/services/goal_log_repository.dart` (modified — `existsOnOrAfter`)
- `lib/data/repositories/drift_goal_log_repository.dart` (modified)
- `test/domain/services/goal_service_test.dart` (modified — AC 1/3/4/5 coverage)
- `test/domain/services/fakes.dart` (modified — in-memory repository extensions)
- `test/domain/evaluator/goal_service_multi_version_test.dart` (new — AC 2/5.4 boundary regression)
- `lib/presentation/screens/goal_detail_screen.dart` (new)
- `lib/presentation/screens/goals/goals_list_screen.dart` (new)
- `lib/presentation/components/secondary_button.dart` (new — `button-secondary`, first use)
- `lib/presentation/providers/goal_wizard_provider.dart` (modified — edit-mode fields, `loadForEdit`, `reportVersionLocked`, `keepAlive: true`; generated `.g.dart` regenerated)
- `lib/presentation/providers/goal_wizard_provider.g.dart` (regenerated)
- `lib/presentation/components/recurrence_selector.dart` (modified — optional `initialPattern`)
- `lib/presentation/components/wizard/schedule_step.dart` (modified — passes `initialPattern`)
- `lib/presentation/components/wizard/name_step.dart` (modified — read-only in edit mode)
- `lib/presentation/components/wizard/dates_step.dart` (modified — effective-date field + `versionLocked` message in edit mode)
- `lib/presentation/components/wizard/review_step.dart` (modified — edit-mode Save routing)
- `lib/presentation/screens/goal_creation_wizard.dart` (unchanged behavior; reviewed while wiring the fix above)
- `lib/presentation/screens/day_view.dart` (modified — `_openCreateGoal` resets the wizard provider before pushing)
- `lib/presentation/screens/month_view.dart` (modified — app-bar "Goals" action to `GoalsListScreen`)
- `test/presentation/goal_edit_wizard_test.dart` (new — Task 5.5)
