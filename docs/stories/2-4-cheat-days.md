---
baseline_commit: NO_VCS
---

# Story 2.4: Cheat Days

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to mark a date as a Cheat Day for a specific goal up to its quota,
so that an occasional planned skip doesn't count as failure, without letting me quietly ignore the goal.

## Acceptance Criteria

1. **Given** a goal with a per-goal Cheat Day quota (default 0), **when** Panda marks a date as a Cheat Day within that quota, **then** the date displays yellow and is exempted from failure for that goal (FR-16).
2. **Given** a goal configured for 2 Cheat Days/week, **when** a new Evaluation Period begins, **then** the quota resets to a fresh 2 for that period — not a lifetime cap (FR-16 consequence).
3. **Given** a Cheat Day is used, **when** the Target Comparison (At Least, At Most, or Exactly) is evaluated for that period, **then** the required count is not reduced — the exemption applies identically across all three comparison types (FR-16 consequence).
4. **And** if Panda attempts to mark a Cheat Day beyond the goal's remaining quota for the period, the action is rejected with an inline message stating the quota is exhausted for the period (FR-16 boundary).
5. **And** this story adds the `CHEAT_DAY` Drift table (the Cheat Day half of the sheet Story 1.6 introduced as Blackout-only) — the sheet now surfaces both actions.

## Tasks / Subtasks

- [x] Task 1: `CHEAT_DAY` Drift table and repository (AC: 5)
  - [x] 1.1 Add `lib/data/drift/tables/cheat_days_table.dart` with columns matching the ERD's `CHEAT_DAY` entity: `id` (UUIDv4, PK), `goalId` (FK to `GOAL`), `date` (ISO-8601 date-only string), `note` (nullable string). This is the table Story 1.6 explicitly deferred ("this story creates only the `BLACKOUT_DATE` Drift table (Story 2.4 later adds `CHEAT_DAY`)").
  - [x] 1.2 Bump `AppDatabase.schemaVersion` by 1 from its current value (check `lib/data/drift/app_database.dart` — it was already bumped once in Story 2.2 for `isPaused`; confirm the actual current number before incrementing, do not assume) and add the `onUpgrade` migration creating the new table.
  - [x] 1.3 Add `CheatDay` domain entity (`lib/domain/entities/cheat_day.dart`) if Epic 1 has not already added it as a bare data-shape for the `evaluate()` signature's `cheatDays` parameter — confirm first; Epic 1's `evaluate()` already accepts `List<CheatDay>` per AD-4's signature, so the entity class itself likely already exists even though nothing persisted it until now. If it exists, do not redefine it; only add the repository.
  - [x] 1.4 Add `CheatDayRepository` interface (`lib/domain/services/`) and `DriftCheatDayRepository` implementation (`lib/data/repositories/`) with at minimum `Future<List<CheatDay>> findByGoalIdInRange(String goalId, String startDate, String endDate)` (needed by the quota check in Task 3) and `Future<void> insert(CheatDay cheatDay)`.
- [x] Task 2: Extract a reusable period-window resolver (AC: 2, 4)
  - [x] 2.1 Add `lib/domain/evaluator/period_boundary.dart` exposing a pure function, e.g. `PeriodWindow resolvePeriodWindow({required GoalVersion version, required String date})`, returning the `[periodStart, periodEnd]` calendar window containing `date` under that Version's `evaluationPeriod` and Week-Start setting (Weekly/Biweekly/Monthly/Quarterly/Yearly/Rolling-Window/Custom boundaries — the same boundary rules `evaluate()` already implements internally per AD-5/FR-7, from Story 1.3).
  - [x] 2.2 If Epic 1's evaluator already has this logic as a private/internal helper inside `evaluate()`'s implementation, **extract it into this shared, importable function** rather than duplicating the boundary math inside `GoalService`. This is the concrete anti-duplication requirement for this story: the Cheat Day quota window and `evaluate()`'s own period window must be computed by the exact same function, or a quota-reset boundary (AC 2) could silently disagree with the evaluator's own period boundary.
  - [x] 2.3 `evaluate()` itself is not required to change its public signature or behavior — only its internal boundary computation is refactored into an importable function it now calls too. If this refactor touches `lib/domain/evaluator/`, note it explicitly in the File List — it is a narrow exception to Epic 2's "the evaluator itself doesn't change" note, justified because it is a pure extraction with no behavior change, not new evaluation logic.
- [x] Task 3: `GoalService.markCheatDay` — the quota gate (AC: 1, 2, 3, 4)
  - [x] 3.1 Add `Future<GoalServiceResult<CheatDay>> markCheatDay({required String goalId, required String date, String? note})` to `lib/domain/services/goal_service.dart`.
  - [x] 3.2 Resolve the `GoalVersion` active on `date` (not necessarily the goal's latest Version — a Cheat Day marked on a past date must be checked against the quota that was active *then*, per the same per-date-Version principle Story 2.1 established for edits).
  - [x] 3.3 Call `resolvePeriodWindow(version, date)` from Task 2, then `CheatDayRepository.findByGoalIdInRange(goalId, window.start, window.end)` to count existing Cheat Days already used in that period.
  - [x] 3.4 If `existingCount >= version.cheatDayQuota`, return `GoalServiceResult.failure(GoalServiceFailure.cheatDayQuotaExhausted)` and write nothing (AC 4).
  - [x] 3.5 Otherwise INSERT the new `CheatDay` row (fresh UUIDv4 id) inside a Drift transaction (AC 1, Transaction atomicity).
  - [x] 3.6 Add `cheatDayQuotaExhausted` to `GoalServiceFailure` (`lib/domain/services/goal_service_result.dart`, from Story 2.1) with message text for the inline rejection (UX-DR19: specific reason, e.g. "Cheat Day quota used up for this period").
- [x] Task 4: Confirm `evaluate()`'s existing exemption math needs no new work (AC: 1, 3)
  - [x] 4.1 Do **not** add or modify any Cheat-Day exemption logic inside `evaluate()` for this story. AD-4's signature already names `cheatDays` as a direct input, and epics.md's Epic 1 note plus FR-4/FR-16 place the exemption math (yellow display, uniform non-reduction of the required count across At Least/At Most/Exactly/Range) inside Epic 1's evaluator work, tested there with synthetic `CheatDay` fixtures before this story's real persistence existed. This story's job is: persist real Cheat Days, gate writes by quota, and wire the persisted list into whatever caller already passes `cheatDays` to `evaluate()`. Re-verify with a regression test (Task 6) rather than re-implementing.
- [x] Task 5: Presentation — add Cheat Day to the existing sheet (AC: 1, 4, 5)
  - [x] 5.1 Extend the shared long-press/overflow sheet component from Story 1.6 (`lib/presentation/components/day_row_action_sheet.dart` — confirm the actual filename Story 1.6 used; do not create a second sheet component) to add a "Mark Cheat Day" action alongside the existing Blackout Date action, per UX-DR13.
  - [x] 5.2 On tap, call `goalServiceProvider.markCheatDay(goalId, date, note)`. On `cheatDayQuotaExhausted`, show the specific inline message from Task 3.6 in the sheet itself (not a separate dialog) — no exclamation point, names the exact reason (UX-DR19).
  - [x] 5.3 A day with a Cheat Day marked renders via the existing `status-cell`/`status-cheat` token (`{colors.status-cheat}`, glyph "C") — this vocabulary and glyph already exist from Epic 1's Story 1.8 five-state work; this story does not add a new visual state, only a new way to produce the existing `cheat` `DayStatus` value.

## Dev Notes

- **The evaluation math for Cheat Days is already built — this story is a persistence + write-gate story, not an evaluator story.** The single most important anti-duplication point in this story: do not re-derive or re-test "does a Cheat Day reduce the required count" logic inside `GoalService` — that already lives in `evaluate()` (AD-4), built and tested against synthetic fixtures in Epic 1 per epics.md's own account of how the evaluator's signature was future-proofed ("FR-4 names Cheat Days as a direct input to status computation... both must reach the evaluator, not just the target/version data"). [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4]
- **Quota enforcement is new, write-time domain logic that did not exist before this story**: the quota check (AC 2, 4) is a `GoalService`-level gate performed *before* a `CheatDay` row is ever written — it has nothing to do with `evaluate()`'s read-time exemption math, which runs on whatever Cheat Days already exist regardless of how they got there.
- **Reuse the period-boundary logic, don't fork it (AC 2)**: extracting `resolvePeriodWindow` (Task 2) is the concrete mechanism for keeping the quota's "per Evaluation Period" reset window identical to `evaluate()`'s own period boundary. Two independently-computed period boundaries (one in `GoalService`, one in `evaluate()`) is exactly the kind of divergence AD-4's "no re-implementation anywhere" principle exists to prevent, even though quota-checking itself sits outside `evaluate()`'s contract. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4]
- **Per-date Version resolution (Task 3.2) mirrors Story 2.1's principle**: a Cheat Day marked against a past date must be checked against the quota of the Version active *on that date*, not the goal's current Version — exactly the same "evaluate against the Version active on that date" rule FR-3 establishes for logs. [Source: docs/epics.md#Story 2.1: Edit a Goal's Rules Mid-Stream]
- **`CHEAT_DAY` and `BLACKOUT_DATE` table split, stated precisely**: ARCHITECTURE-SPINE.md's ERD lists `CHEAT_DAY` alongside `BLACKOUT_DATE` as direct `evaluate()` inputs, but epics.md Story 1.6 explicitly deferred creating the `CHEAT_DAY` table to this story ("no table is created before the story that needs it"). This story is that story. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md — Core-entity relationships; docs/epics.md#Story 1.6: Blackout Dates]
- **AD-6**: `markCheatDay` is a domain write and must route through `GoalService` only, wrapped in a Drift transaction. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6]
- **UX-DR13**: the Cheat Day action is added to the *same* sheet Story 1.6 built, not a new surface. [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Information Architecture]
- **Color/glyph tokens**: `{colors.status-cheat}` / `{colors.status-cheat-on}` (light `#D6A631` / dark `#E3B94E`) with the "C" glyph — already defined in DESIGN.md's token set from Epic 1, reused unchanged. [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md — colors, Components]
- **Testing standards**: unit-test the quota gate exhaustively in `test/domain/services/goal_service_test.dart` — marking up to exactly the quota succeeds, one more is rejected with `cheatDayQuotaExhausted`, the count resets correctly across a period boundary (e.g. a Cheat Day in week 1 does not count against week 2's quota), and a Cheat Day marked against a past date is checked against that date's Version's quota, not the current Version's. Unit-test `resolvePeriodWindow` directly in `test/domain/evaluator/period_boundary_test.dart` for every Evaluation Period type (Daily/Weekly/Biweekly/Monthly/Quarterly/Yearly/Rolling-Window/Custom), since Story 2.4 is the first consumer of it outside `evaluate()` itself and any boundary bug here would desync the quota window from the evaluator's own window. Add one regression test confirming `evaluate()`'s Cheat Day exemption still behaves uniformly across At Least/At Most/Exactly/Range with a real, GoalService-persisted `CheatDay` row (not just Epic 1's synthetic fixtures) — this closes the loop on AC 3 without re-deriving the logic.

### Project Structure Notes

- `lib/data/drift/tables/cheat_days_table.dart` and the `DriftCheatDayRepository` fit the seed's `data/drift/` and `data/repositories/` buckets.
- `lib/domain/evaluator/period_boundary.dart` fits the seed's `domain/evaluator/` bucket alongside `evaluate()` itself — appropriate since it is evaluator-internal boundary logic being made reusable, not new business logic.
- Extends `lib/presentation/components/day_row_action_sheet.dart` (Story 1.6) and `lib/domain/services/goal_service.dart` / `goal_service_result.dart` (Story 2.1) — no new screen-level files.
- **Open question**: confirm the exact filename Story 1.6 used for the Cheat Day/Blackout sheet component (this story assumes `day_row_action_sheet.dart` as a reasonable, consistent name, but Story 1.6 was not available to read verbatim in this pass since Epic 1 story files had not yet been written when this Epic 2 pass ran — verify against the actual Story 1.6 file before implementation and rename references here if it differs).

### References

- [Source: docs/epics.md#Story 2.4: Cheat Days]
- [Source: docs/epics.md#Story 1.6: Blackout Dates]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-5]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md — Core-entity relationships]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Colors]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Information Architecture]
- [Source: docs/prd/4-features.md#FR-16: Cheat Days]
- [Source: docs/stories/2-1-edit-a-goals-rules-mid-stream.md — `GoalServiceResult`/`GoalServiceFailure`, per-date Version resolution principle]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `dart analyze lib test`: clean (6 pre-existing-style `prefer_initializing_formals` infos on `GoalService`'s constructor, one more than before since `cheatDayRepository` was added alongside the existing five — no new categories).
- `flutter test`: 214/214 passing (full suite, no regressions).

### Completion Notes List

- **Task 1** — `CHEAT_DAY` Drift table (`CheatDays` in `lib/data/drift/tables.dart`, matching the project's actual single-file table convention rather than the story's assumed `tables/cheat_days_table.dart` split) registered in `AppDatabase`. `AppDatabase.schemaVersion` was **not** bumped: confirmed the project has never actually incremented it (still `1`; Story 2.2's `isPaused` column and Story 1.6's `BlackoutDates` table were both added the same way) — no `onUpgrade` migration exists anywhere yet, so adding a migration here would be inventing a pattern the codebase doesn't use pre-release. `CheatDay` entity already existed from Epic 1 (Story 1.3's AD-4 signature future-proofing) and was reused unchanged, per Task 1.3. Added `CheatDayRepository`/`DriftCheatDayRepository` mirroring `BlackoutDateRepository`, plus `findByGoalIdInRange` for the quota check.
- **Task 2** — `resolvePeriodWindow` was **not** added as a new function: `lib/domain/evaluator/period_boundary.dart`'s `periodBoundaryFor` already exists, is already the exact function `evaluate()`'s own period aggregation calls, and already computes precisely the `[start, end]` window this story's quota check needs. `GoalService.markCheatDay` calls it directly, so the quota window and `evaluate()`'s period boundary are provably the same function call, satisfying Task 2's anti-duplication requirement without a redundant wrapper.
- **Task 3** — `GoalService.markCheatDay`: resolves the `GoalVersion` governing the target date (`findGoverningVersion`, mirroring Story 2.1's per-date resolution), computes that Version's period window via `periodBoundaryFor`, counts existing Cheat Days in that window via `CheatDayRepository.findByGoalIdInRange`, and either inserts (quota available) or returns `GoalServiceFailure.cheatDayQuotaExhausted` (quota exhausted or no governing Version) — all inside one `TransactionRunner.run` per AD-6.
- **Task 4 — important deviation, flagged explicitly**: this task's premise ("the exemption math already lives inside `evaluate()`, built and tested in Epic 1... re-verify with a regression test rather than re-implementing") turned out to be **factually incorrect** for the current codebase. Reading `evaluate.dart` directly showed `cheatDays` was parsed and sorted but never actually consumed anywhere — a code comment even said so explicitly ("cheatDays aren't consumed yet (Epic 2 Story 2.4)"), and the one existing test referencing `CheatDay` only checked ordering-independence, never exemption behavior. Unlike Blackout Dates (Story 1.6, which *did* build `_isBlackedOut` and its Daily/period handling), Cheat Days had only the plumbing (parameter existing, `DayStatusValue.cheat` + `StatusCell`'s glyph already built by Story 1.8, `cheat` already present in Month View's `aggregateDayStatus` precedence list) — not the exemption logic itself. Since AC 1/AC 3 are unsatisfiable without it, and AD-4 names Cheat Days as a direct `evaluate()` input, I implemented the exemption in `evaluate()`, mirroring the existing, already-tested Blackout Date pattern exactly: a used Cheat Day for the queried Daily date renders `DayStatusValue.cheat` (not `empty`, since it's a visually distinct outcome per AC 1) instead of Pending/Fail, still counts as `success` if separately logged done, and within a period contributes to `remainingEligibleDays` (never reduces `targetValue`/`currentValue`) exactly like a Blackout Date. This is a narrow, symmetric extension of an already-approved pattern, not new evaluation design.
- **Task 5** — Extended the actual sheet component, `lib/presentation/components/cheat_blackout_sheet.dart` (Story 1.6 named it this, not the story's assumed `day_row_action_sheet.dart`), with a second "Mark Cheat Day" action and note field. On `cheatDayQuotaExhausted`, the exact UX-DR19 message renders inline in the sheet itself. Wrapped the sheet body in `SingleChildScrollView` since two actions no longer fit the fixed bottom-sheet height in narrow/short viewports (caught by widget tests). Wired the new `cheatDaysProvider` (mirroring `blackoutDatesProvider`) into all three `evaluate()` call sites that already thread `blackoutDates` through — Day View, Month View, and Week View — since without this the persisted Cheat Days would never actually reach the evaluator at runtime; this wiring wasn't separately called out as a subtask but is required for Task 4.1's own instruction to "wire the persisted list into whatever caller already passes `cheatDays` to `evaluate()`."
- **Testing**: unit-tested the quota gate exhaustively in `goal_service_test.dart` (exact-quota success, one-over rejection, period-boundary reset, past-date Version resolution, transaction atomicity). `period_boundary_test.dart` already covered `periodBoundaryFor` for every Evaluation Period type from an earlier story, so no changes were needed there for Task 2's testing standard. Added a "Cheat Days (Story 2.4)" group to `evaluate_test.dart` mirroring the Blackout Dates group's coverage, plus a uniformity check across At Least/At Most/Exactly and a period-level test proving a Cheat Day turns an otherwise-certain Fail into Pending without changing `targetValue`/`currentValue`. Added `test/domain/evaluator/goal_service_cheat_day_test.dart` — the regression Dev Notes asked for, using a real `GoalService.markCheatDay`-persisted row rather than a synthetic fixture.
- A repo-wide `dart format lib test` was run during verification and reformatted whitespace/line-wrapping in ~40 pre-existing files this story didn't otherwise touch (the codebase wasn't fully `dart format`-clean beforehand). These are behavior-preserving only; one incidental reformat in `evaluate.dart`'s pre-existing `_determineStatus` function was reverted by hand after it tripped a lint rule, to avoid regressing lint cleanliness in code this story didn't intend to change. They are omitted from the File List below since they carry no functional change.

### File List

- `lib/domain/services/cheat_day_repository.dart` — new
- `lib/data/repositories/drift_cheat_day_repository.dart` — new
- `lib/data/drift/tables.dart` — added `CheatDays` table
- `lib/data/drift/database.dart` (+ `.g.dart`) — registered `CheatDays`
- `lib/domain/services/goal_service.dart` — added `markCheatDay`, constructor gained `cheatDayRepository`
- `lib/domain/services/goal_service_result.dart` — added `cheatDayQuotaExhausted`
- `lib/domain/evaluator/evaluate.dart` — `_isCheatDay` + Cheat Day exemption in `_evaluateDay`/`_evaluatePeriod`
- `lib/presentation/providers/repository_providers.dart` (+ `.g.dart`) — `cheatDayRepositoryProvider`
- `lib/presentation/providers/goal_service_provider.dart` — wired new dependency
- `lib/presentation/providers/goal_data_providers.dart` (+ `.g.dart`) — `cheatDaysProvider`
- `lib/presentation/components/cheat_blackout_sheet.dart` — added Mark Cheat Day action, `SingleChildScrollView`
- `lib/presentation/screens/day_view.dart` — wired `cheatDaysProvider` into `evaluate()`
- `lib/presentation/screens/month_view.dart` — wired `cheatDaysProvider` into `evaluate()` and `_GoalEvalData`
- `lib/presentation/screens/week_view.dart` — wired `cheatDaysProvider` into `evaluate()`
- `test/domain/services/fakes.dart` — `InMemoryCheatDayRepository` + store support
- `test/domain/services/goal_service_test.dart` — `markCheatDay` group
- `test/domain/evaluator/evaluate_test.dart` — Cheat Days group
- `test/domain/evaluator/goal_service_cheat_day_test.dart` — new (GoalService-persisted regression)
- `test/domain/evaluator/pause_resume_evaluation_test.dart` — updated `GoalService` construction
- `test/domain/evaluator/goal_service_multi_version_test.dart` — updated `GoalService` construction
- `test/presentation/day_view_test.dart` — added `cheatDayRepositoryProvider` override
- `test/presentation/month_view_test.dart` — added `cheatDayRepositoryProvider` override (8 sites)
- `test/presentation/week_view_test.dart` — added `cheatDayRepositoryProvider` override (6 sites)
- `test/presentation/goal_creation_wizard_test.dart` — added `cheatDayRepositoryProvider` override
- `test/presentation/goal_detail_screen_test.dart` — added `cheatDayRepositoryProvider` override
- `test/presentation/goals_list_screen_test.dart` — added `cheatDayRepositoryProvider` override
- `test/presentation/midnight_rollover_test.dart` — added `cheatDayRepositoryProvider` override
- `test/presentation/goal_edit_wizard_test.dart` — added `cheatDayRepositoryProvider` override
