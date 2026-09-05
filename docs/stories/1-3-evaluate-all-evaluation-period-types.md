# Story 1.3: Evaluate All Evaluation Period Types

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want a goal's target evaluated over the right kind of period (daily, weekly, monthly, rolling window, etc.),
so that goals like "3x a week" or "10x in any 14 days" are judged correctly, not just per day.

## Acceptance Criteria

1. **Given** a goal with Evaluation Period = Weekly and Week-Start = Monday **When** `evaluate()` runs for any date in that week **Then** the period boundary is Monday–Sunday (FR-7, FR-24)
2. **Given** a goal with Evaluation Period = Rolling Window (14 days) **When** `evaluate()` runs for today **Then** the window is always "the trailing 14 days ending today," with no fixed calendar boundary (FR-7)
3. **Given** Biweekly, Monthly, Quarterly, and Yearly period types **When** a goal of each type is evaluated **Then** each follows its respective calendar boundary (FR-7)
4. **Given** the pure `evaluate()` signature `evaluate({goal, versions, logs, cheatDays, blackoutDates, date})` **When** called by two different callers with the same inputs supplied in different order **Then** the result is identical — inputs are sorted internally, never depending on caller-supplied ordering (AD-4)

## Tasks / Subtasks

- [x] Task 1: Formalize the full AD-4 `evaluate()` signature (AC: #4)
  - [x] Subtask 1.1: Widen `lib/domain/evaluator/evaluate.dart` (Story 1.1/1.2) to accept the complete AD-4 signature: `DayStatus evaluate({Goal goal, List<GoalVersion> versions, List<GoalLog> logs, List<CheatDay> cheatDays, List<BlackoutDate> blackoutDates, DateTime date})`. `cheatDays` and `blackoutDates` parameters accept empty lists in this story (their entities/tables don't exist yet — Story 1.6 adds `BlackoutDate`, Epic 2 Story 2.4 adds `CheatDay`) but the signature itself must be finalized here since it is the contract every later story's caller code depends on
  - [x] Subtask 1.2: Implement internal sorting: `versions` sorted by `versionStartDate`, `logs`/`cheatDays`/`blackoutDates` sorted by `date`, performed unconditionally inside `evaluate()` regardless of input order — add a dedicated unit test that calls `evaluate()` twice with the same data in reversed list order and asserts identical output (AD-4, AC #4)
  - [x] Subtask 1.3: Confirm `evaluate()` still has zero I/O, zero Flutter/Drift imports, and is fully deterministic (AD-1, AD-4) — this is a widening of the existing function, not a new one; there must be exactly one `evaluate()` in the codebase
- [x] Task 2: Period-boundary calculation module (AC: #1, #2, #3)
  - [x] Subtask 2.1: Create period-boundary logic (e.g. `lib/domain/evaluator/period_boundary.dart`, called internally by `evaluate()` — keep it a private helper of the evaluator, not a second public evaluation entry point) that, given `evaluationPeriod` + `date` + Week-Start setting, returns the `[periodStart, periodEnd]` window containing `date`:
    - Daily: the day itself (already implemented in Story 1.1)
    - Weekly: Monday–Sunday or Sunday–Saturday per the Week-Start setting (FR-24) — this story implements the boundary math; the actual user-facing Week-Start *setting* UI is not part of Epic 1's scope beyond what's needed to parametrize this calculation (FR-24 itself is fully covered here at the evaluator level; Settings screen wiring, if any UI surface is needed beyond a default, should default to Monday per FR-24 and not block this story)
    - Biweekly: two-week blocks anchored to the Goal's start date (consistent with the "anchored to start date" pattern Story 1.5 will use for custom recurrence — establish the anchoring convention here since Biweekly is the simplest anchored-period case)
    - Monthly: calendar month boundary
    - Quarterly: calendar quarter boundary (Jan–Mar, Apr–Jun, Jul–Sep, Oct–Dec)
    - Yearly: calendar year boundary
    - Rolling Window (N days): **not** a fixed calendar boundary — always `[date - (N-1), date]`, i.e. the trailing N days ending on the evaluation date; recomputed fresh for every `date` passed to `evaluate()`, never cached as a fixed range
    - Custom: this story's "Custom" period-type handling only needs to exist as a named case that Story 1.5 (Custom Recurrence Patterns) fully populates — do not leave it unhandled/throwing, but do not attempt to implement every custom pattern here either; a minimal pass-through or explicit "not yet evaluable" domain failure is acceptable as long as Story 1.5 can slot in without changing this function's shape
  - [x] Subtask 2.2: Ensure Version-boundary intersection (AD-5) is respected even though full editing/versioning isn't exposed until Epic 2: the boundary calculation must intersect the calendar boundary with the Version's `[versionStartDate, nextVersion.startDate or goal end]` window — since Epic 1 only ever constructs a single Version, this intersection degenerates to "calendar boundary clipped at goal start/end date" for now, but the code path must be the general AD-5 intersection logic, not a Version-oblivious calculation that would need rewriting when Epic 2 adds multi-Version goals
  - [x] Subtask 2.3: For each period type, once the boundary is known, aggregate that period's eligible-day logs/targets exactly as Stories 1.1/1.2 already aggregate a single day (Boolean: count of eligible days marked done within the period; Counter: summed value within the period) — this generalizes the existing per-day evaluation into a per-period evaluation without introducing a second evaluation code path
  - [x] Subtask 2.4: When building a period's eligible-day pool, exclude any date whose governing Version has `isPaused == true` from that pool entirely (AD-4's pause-awareness rule) — contributes zero eligible days for that date, same treatment as a date `eligibleDaysRule` itself excludes. Per AD-5's pause/resume carve-out, do **not** treat an `isPaused`-only Version boundary (every other rule field identical to the adjacent Version) as a rule-change boundary that truncates the period into independent segments — the period stays one continuous window with one un-split target; only the pool shrinks. Epic 1 never sets `isPaused = true` (no UI yet), so this branch is unreachable by this story's own tests, but the pool-computation code must implement it now so Epic 2 Story 2.2 doesn't have to modify this function.
- [x] Task 3: Week-Start setting plumbing (AC: #1)
  - [x] Subtask 3.1: Since Week-Start (FR-24) is a simple user setting per AD-3 ("shared_preferences... for simple user settings (week-start day, reminder time)"), define the setting's default (Monday, per FR-24) as a parameter `evaluate()` accepts or as a value already resolved onto the `Goal`/caller context before calling `evaluate()` — `evaluate()` itself must remain pure (no reading `shared_preferences` internally, since that would violate "no I/O" in AD-4); the Week-Start value must be passed in as plain data by the caller, not fetched inside the evaluator
  - [x] Subtask 3.2: Full Settings-screen UI for changing Week-Start is not required by this story's ACs (Story 1.10 exercises the calendar-rendering side of Week-Start); this story only needs the evaluator to correctly compute Monday–Sunday when Week-Start = Monday is passed in, and Sunday–Saturday when Sunday is passed in
- [x] Task 4: Testing (AC: all)
  - [x] Subtask 4.1: Unit-test each period type's boundary calculation independently in `test/domain/evaluator/period_boundary_test.dart` (or within `evaluate_test.dart`): Weekly (both Week-Start settings), Biweekly, Monthly, Quarterly, Yearly, Rolling Window — including boundary edge cases (e.g. a date exactly on a month/quarter/year boundary, a Rolling Window evaluated on the Goal's very first day when fewer than N days of history exist)
  - [x] Subtask 4.2: Unit-test the ordering-independence guarantee (AC #4) explicitly: construct identical `versions`/`logs`/`cheatDays`/`blackoutDates` data in two different orderings, call `evaluate()` with each, assert identical `DayStatus` output
  - [x] Subtask 4.3: Unit-test that Rolling Window's boundary is recomputed relative to the evaluation `date` and is never a fixed calendar range — evaluate the same goal on two different dates and confirm the trailing-14-day window shifts accordingly
  - [x] Subtask 4.4: Property-based or table-driven tests are appropriate here given NFR-6's emphasis on exotic scheduling correctness — consider a parametrized test table covering all seven period types (Daily already covered by Story 1.1/1.2 tests) × both Week-Start settings where applicable
  - [x] Subtask 4.5: Unit-test the pause-exclusion pool logic directly (Subtask 2.4) even though no Epic 1 goal sets `isPaused`: construct a `List<GoalVersion>` by hand with a middle Version where `isPaused = true` and identical other rule fields on both sides, and assert (a) the period is evaluated as one window, not split, and (b) dates under the paused Version contribute zero to the eligible-day pool. This test exists now specifically so Epic 2 Story 2.2 can rely on this behavior being already verified rather than discovering it broken when pause ships.

## Dev Notes

- **This story does not touch Eligible-Days Rules, Custom Recurrence details, Blackout Dates, full Target Comparison, or certain-failure Red logic** — those are Stories 1.4, 1.5, 1.6, 1.7, and 1.8 respectively. This story's sole job is period *boundary* correctness: given a period type and a date, what date range does that period cover, and how do a period's logs aggregate within it. Every goal exercised by this story's tests should keep using "every day" eligible-days and a simple target (reuse Story 1.1/1.2's Boolean-Exactly-1 and Counter-At-Least patterns) so the only variable under test is the period boundary itself.
- **AD-4 (pure evaluator contract) — this is the story that finalizes the contract.** The signature `DayStatus evaluate({Goal goal, List<GoalVersion> versions, List<GoalLog> logs, List<CheatDay> cheatDays, List<BlackoutDate> blackoutDates, DateTime date})` becomes fixed here. All prior and future callers (live calendar in Story 1.10, the eventual `CacheWriter` in Epic 3, `StatsService` in Epic 3, widget precompute in Epic 5) must call this exact function — no re-implementation anywhere. The "no I/O, no Flutter, no Drift, fully deterministic, sorts its own inputs" constraints are non-negotiable and are directly tested by AC #4.
- **AD-5 (version-boundary period splitting):** even though Epic 1 never constructs more than one `GoalVersion` per goal, the period-boundary logic built in this story must already perform the calendar-boundary ∩ Version-window intersection described in AD-5, because Epic 2 Story 2.1 will start creating multiple Versions and must not require rewriting this function. Specifically: "a `GoalVersion`'s evaluation window is `[version.startDate, nextVersion.startDate or goal end]`... boundary = calendar boundary ∩ Version window; truncated segments evaluate in full against their own un-prorated target." Build the intersection logic now, even though with one Version it always resolves to "the calendar boundary, clipped at goal start (and end date if set)."
- **Pause-awareness (AD-4/AD-5, forward-looking for FR-2):** `GoalVersion.isPaused` (added to the entity in Story 1.1) must be consulted by this story's eligible-day-pool computation, not deferred to Epic 2. A period spanning a pause/resume boundary — where `isPaused` is the *only* field that differs between adjacent Versions — is evaluated as a single continuous period with dates under the paused Version contributing zero eligible days, rather than being split into independently-targeted segments the way a genuine rule-field change would be. This exists precisely so that pausing a "3x/week" goal for 2 of its 5 eligible days doesn't force the remaining 3 days to somehow hit "3" on their own after an AD-5-style truncation — the target stays measured against the shrunk-but-unified pool for the whole period. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4 — Pure Evaluator Contract; #AD-5 — Version-Boundary Period Splitting (No Pro-Rating)]
- **FR-7 boundary definitions, verbatim:** Weekly follows the Week-Start Setting (FR-24); Monthly/Quarterly/Yearly follow calendar month/quarter/year boundaries; a Rolling Window has no fixed calendar boundary — it is always "the trailing N days ending today." Biweekly is not explicitly defined beyond "each follows its respective calendar boundary" (epics.md AC #3) — this story's Dev Notes resolve Biweekly as two-week blocks anchored to the Goal's start date (consistent with FR-9's anchoring convention for custom N-based recurrence), since no other anchor point is specified anywhere in the PRD/architecture; flagged as an open question below for confirmation.
- **NFR-3 (no timezone/DST):** all period boundary math operates on naive ISO-8601 date-only values — no `DateTime`-with-timezone anywhere, no DST adjustment logic. Treat dates as plain calendar dates throughout.
- **Anti-duplication guidance:** widen the single `evaluate()` function and its private period-boundary helper — do not create a second evaluation path for "period goals" versus "daily goals." Reuse Story 1.1's Boolean-day-aggregation and Story 1.2's Counter-summing logic by generalizing them to operate over an arbitrary `[periodStart, periodEnd]` range instead of a single day (a single day is simply the Daily period's `[date, date]` range).
- **Testing standards:** this is squarely NFR-6 territory — "edge-case evaluation logic (exotic recurrence, rolling-window, day-boundary cases) is a first-class acceptance bar." Every period type must have explicit unit tests, and the ordering-independence guarantee (AC #4) must be tested directly, not just assumed from code inspection. Boundary edge cases (period-start day, period-end day, leap years for Yearly, quarter transitions) deserve explicit test cases given the correctness bar.

### Project Structure Notes

- New file: `lib/domain/evaluator/period_boundary.dart` (private helper module used only by `evaluate()`) — stays under the existing `lib/domain/evaluator/` folder from Story 1.1's seed, no new top-level folder needed.
- New test files under `test/domain/evaluator/` — consistent with the seed's `test/domain/` mirroring convention.
- No conflicts detected between epics.md, architecture, and UX for this story's core scope. One open question flagged below regarding Biweekly's anchor point.

### References

- [Source: docs/epics.md#Story 1.3: Evaluate All Evaluation Period Types]
- [Source: docs/epics.md#Requirements Inventory] (FR-7, FR-24)
- [Source: docs/prd/4-features.md#FR-7: Evaluation Period Types]
- [Source: docs/prd/4-features.md#FR-24: Week-Start Setting]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4 — Pure Evaluator Contract]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-5 — Version-Boundary Period Splitting (No Pro-Rating)]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Evaluator flow] (mermaid flowchart — locate period, check Version boundary, truncate/split, aggregate)
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Consistency Conventions] (NFR-3 date convention)
- [Source: docs/stories/1-1-scaffold-the-app-and-track-a-simple-daily-goal.md] (previous story intelligence — evaluate() skeleton, entities)
- [Source: docs/stories/1-2-track-counter-goals-with-corrections.md] (previous story intelligence — Counter-summing logic being generalized here)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `dart analyze lib test`: clean (only the 4 pre-existing `prefer_initializing_formals` info suggestions).
- `flutter test`: 41/41 passing (37 domain + 4 widget).

### Completion Notes List

- Finalized AD-4's full signature: `evaluate({goal, versions, logs, cheatDays = const [], blackoutDates = const [], date, weekStart = WeekStart.monday})`. Created minimal `CheatDay`/`BlackoutDate` entities (id/goalId/date/note-or-reason, per the ER diagram) purely so the signature could be typed — neither is consumed yet (Story 1.6 / Epic 2 Story 2.4). Defaulted rather than `required` so no unrelated call site (`day_view.dart`, existing tests) needed churn.
- New `lib/domain/evaluator/period_boundary.dart`: pure `periodBoundaryFor()` covering Daily/Weekly(±week-start)/Biweekly(anchored to `goal.startDate`)/Monthly/Quarterly/Yearly/Rolling-Window(N)/Custom(single-day placeholder). No public evaluation logic of its own — boundary-shape math only, per the story's own "not a second evaluation entry point" constraint.
- `evaluate()` branches on `evaluationPeriod == daily` to reuse Story 1.1/1.2's exact single-day logic unchanged (preserves the Fail-vs-Pending distinction for an explicit `completed:false` log); every other period type routes through a new `_evaluatePeriod()` that intersects the raw calendar boundary with the AD-5 rule-window (`_ruleWindowFor`, which walks outward through adjacent Versions sharing every rule field except `isPaused` — the AD-5 pause carve-out) and aggregates Boolean-day-count or Counter-sum over the clipped range, re-checking each individual date's own governing Version for eligibility/pause exclusion.
- `EvaluationPeriod` gained `weekly`/`biweekly`/`monthly`/`quarterly`/`yearly`/`custom` string constants plus `rollingWindow(int)`/`isRollingWindow`/`rollingWindowDays` for the `"rolling_window:N"` encoding (consistent with the existing string-not-enum pattern for rule fields that need to grow).
- Ordering-independence (AC #4) is tested directly with the full signature including `cheatDays`/`blackoutDates` passed in reversed order. The AD-5 pause-carve-out (Subtask 4.5) has a dedicated hand-constructed 3-Version test proving both non-split-period and pool-exclusion behavior together, even though Epic 1 never exercises it through the UI.

### File List

- `lib/domain/entities/cheat_day.dart` — new (minimal)
- `lib/domain/entities/blackout_date.dart` — new (minimal)
- `lib/domain/entities/rule_values.dart` — added Weekly/Biweekly/Monthly/Quarterly/Yearly/Custom/RollingWindow `EvaluationPeriod` values
- `lib/domain/evaluator/period_boundary.dart` — new
- `lib/domain/evaluator/evaluate.dart` — finalized full AD-4 signature; added `_evaluatePeriod`/`_ruleWindowFor`/`_sameRuleExceptPause`
- `test/domain/evaluator/period_boundary_test.dart` — new
- `test/domain/evaluator/evaluate_test.dart` — added Weekly/Rolling-Window/ordering-independence groups
