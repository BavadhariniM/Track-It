# Story 1.8: Pending, Certain-Failure Red, and the Zero-Eligible-Days Signal

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want a day or period to only turn red once failure is truly certain, and to see a clear warning if I've misconfigured a goal with no eligible days,
so that the calendar never guilt-trips me early or hides a mistake.

## Acceptance Criteria

1. **Given** a Weekly "at least 3 of 5 workdays" goal with 2 of 5 days missed and 3 remaining **When** `evaluate()` runs mid-week **Then** the period shows Pending, not Red (FR-18)
2. **Given** the same goal with 3 of 5 workdays already missed **When** `evaluate()` runs **Then** the period turns Red — failure is now mathematically certain (FR-18)
3. **Given** a Rolling-Window "10x in any 14 days" goal **When** the remaining days in the window can no longer mathematically reach 10 **Then** it turns Red that day, with no other red-triggering condition (FR-18 consequence)
4. **Given** a goal whose Eligible-Days Rule produces zero eligible days in an entire period **When** `evaluate()` runs **Then** that period shows Red, not the Empty/gray treatment (FR-5 — a deliberate exception)
5. **And** the five-state status vocabulary (UX-DR6, UX-DR20) pairs each of Pending/Empty/Fail-by-zero-eligible-days/Success/Cheat with a distinct color, glyph, and screen-reader label — none collapse into a generic gray

## Tasks / Subtasks

- [x] Task 1: Certain-failure math in the evaluator (AC: #1, #2, #3)
  - [x] Subtask 1.1: Implement the certain-failure determination as the final stage of `evaluate()`'s pipeline (Story 1.7's Task 2.2 pipeline: boundary → eligibility → aggregation → comparison → **this stage**): given the period's Target Comparison, current aggregated total, and the count of *remaining* eligible days in the period (eligible days at/after the evaluation date, still within the period, not yet logged), determine whether the best-possible remaining outcome can still satisfy the target
  - [x] Subtask 1.2: For At Least: failure is certain when `currentTotal + maxPossibleFromRemainingEligibleDays < target` (e.g. "3 of 5 workdays" — with 5 total eligible days, once 3 have been missed, only 2 remain, and even if both remaining days succeed, `currentTotal(0 more possible) + 2 < 3`... concretely: 2 missed + 3 remaining means at most `total logged so far + 3` can be reached; failure becomes certain once `remainingEligibleDays < (target - currentTotal)`, i.e. once even a perfect run on all remaining eligible days cannot reach the target)
  - [x] Subtask 1.3: For At Most: failure is certain once `currentTotal > target` already (no remaining-days math needed — once exceeded, it's exceeded; this differs structurally from At Least's "can we still catch up" framing)
  - [x] Subtask 1.4: For Exactly: failure is certain once `currentTotal > target` (overshoot, can never come back down within the period since Counter corrections reduce a *day's* total per Story 1.2 but the period total only grows via eligible-day contributions — confirm this against the domain model) **or** once `currentTotal + maxPossibleFromRemaining < target` (can no longer reach it)
  - [x] Subtask 1.6: For Rolling Window specifically (AC #3): "remaining days" means the days still to come within the trailing-N-day window as it continues to slide forward — since the window itself moves each day (Story 1.3), compute certain-failure using the *current* window's remaining eligible days exactly as any other period type, with no other red-triggering condition beyond this same mathematical-certainty rule (explicitly ruling out e.g. "red if you missed yesterday" or any day-specific heuristic)
  - [x] Subtask 1.7: Before failure is certain and before the target is already met, the status is **Pending** (FR-4, FR-18) — this is the default "in-progress, outcome unknown" state and must never be conflated with Empty (not eligible) or the zero-eligible-days Fail case (Task 2)
  - [x] Subtask 1.8: When the target is already met (and, for Exactly/At Most, not yet exceeded past the point of no return), the status is Success — reuse the existing Success determination from Stories 1.1/1.2, now generalized across all Target Comparisons from Story 1.7
- [x] Task 2: Zero-eligible-days exception (AC: #4)
  - [x] Subtask 2.1: Add a check, evaluated per-period, ahead of/alongside the normal certain-failure logic: if the Eligible-Days Rule (Stories 1.4/1.5) produces **zero** eligible days across the *entire* period boundary (Story 1.3), the period's status is forced to Fail/Red — this is a deliberate exception to the normal "no eligible days = nothing scheduled = Empty" default (FR-5) and must short-circuit before the certain-failure math in Task 1, since with zero eligible days the certain-failure math would otherwise degenerate ambiguously (e.g. dividing by zero remaining days, or vacuously "no days missed yet")
  - [x] Subtask 2.2: Distinguish this from Story 1.4's ordinary single-day Empty case precisely: a single day within a period that has *other* eligible days elsewhere in the period is Empty for that day (Story 1.4) — this Task 2 exception is specifically "the entire period, across its whole boundary, produced zero eligible days," which is a misconfiguration signal (e.g. an Eligible-Days Rule that mistakenly resolves to no weekdays at all)
  - [x] Subtask 2.3: This is a real edge case that must be reachable in practice — confirm at least one construction (e.g. a Custom every-N-days rule combined with an extremely short Custom period, or a wizard misconfiguration) can actually produce this state, so the test in Task 4 exercises a genuine scenario, not a contrived impossible one
- [x] Task 3: Presentation — five-state vocabulary completeness (AC: #5)
  - [x] Subtask 3.1: Confirm `status_cell.dart`/`status_badge` (Story 1.1's component, extended for Empty in Story 1.4) now renders all five states distinctly: Success (✓, green), Fail (✕, red) — covering both certain-failure and zero-eligible-days Fail, Cheat (C, yellow — not yet reachable until Epic 2 Story 2.4 creates Cheat Days, but the rendering case should exist in the component's enum now since `DayStatus.status` is a shared type), Empty (dash, gray/neutral), Pending (ellipsis, a distinct muted color per DESIGN.md — "visually closer to the muted neutrals than to any pass/fail color, so it never reads as a disguised red or green")
  - [x] Subtask 3.2: Verify Pending's color token (`status-pending`, `#6B7CA0` light / `#8B9BC7` dark per DESIGN.md) is visually and programmatically distinct from both Empty (`status-empty`, `#E4E7EC` light) and Fail (`status-fail`, `#D34A4A` light) — do not let Pending default to a shared "gray" with Empty; they are different tokens (UX-DR11, UX-DR20)
  - [x] Subtask 3.3: Ensure each status has its own screen-reader label distinguishing semantic meaning, not just color name (e.g. "Failed, certain" vs. "Not scheduled" vs. "Pending, 2 of 3 remaining") per EXPERIENCE.md's Accessibility Floor — the zero-eligible-days Fail case in particular should ideally have a screen-reader label distinguishable from an ordinary certain-failure Fail if feasible (not explicitly required by any AC, but consistent with the accessibility floor's intent — flagged as a nice-to-have, not a blocking requirement)
- [x] Task 4: Testing (AC: all)
  - [x] Subtask 4.1: Unit-test AC #1 exactly as specified: Weekly "at least 3 of 5 workdays," 2 missed, 3 remaining → Pending
  - [x] Subtask 4.2: Unit-test AC #2 exactly as specified: same goal, 3 of 5 already missed → Red
  - [x] Subtask 4.3: Unit-test AC #3: Rolling-Window "10x in 14 days," remaining days can no longer reach 10 → Red that day; and confirm no other condition (e.g. a single bad day) triggers Red prematurely
  - [x] Subtask 4.4: Unit-test AC #4: a goal configured so its Eligible-Days Rule produces zero eligible days across an entire period → Red, explicitly distinguished from the Empty case (add a companion test proving a normal non-eligible single day within a populated period still renders Empty, to guard the boundary between Story 1.4's behavior and this story's exception)
  - [x] Subtask 4.5: Unit-test certain-failure math for At Most and Exactly (overshoot-triggers-immediately), since epics.md's ACs only spell out At Least and Rolling-Window explicitly but Story 1.7 requires all three comparisons to be fully supported
  - [x] Subtask 4.6: Widget-test that all five statuses render with visually distinct colors/glyphs/labels in the `status-cell` component

## Dev Notes

- **This is the correctness capstone for FR-18/FR-5 and completes the five-state vocabulary started in Story 1.1.** It builds directly on Story 1.7's comparison predicate and Story 1.3's period-boundary/remaining-days concept — do not reopen either; this story adds exactly one new pipeline stage (certain-failure/status determination) plus the zero-eligible-days short-circuit.
- **FR-18, verbatim:** "A day/period turns red only once failure is mathematically certain given remaining eligible days, never merely because target isn't hit yet. Before certain, shows Pending." This is the core anti-pattern to avoid: never turn a cell Red just because "the target hasn't been met yet today" — Red requires proof that no remaining sequence of eligible-day outcomes can reach the target.
- **FR-5, verbatim:** "A period with zero Eligible Days shows red, not gray (deliberate misconfiguration flag)." This is intentionally the *opposite* of the normal Empty-day default (Story 1.4) — the architecture and UX both call this out as a deliberate, load-bearing exception, not an inconsistency to "fix." Do not let a future refactor collapse this into Empty for consistency's sake; it is deliberately inconsistent by design.
- **AD-4 (pure evaluator):** the certain-failure math is pure arithmetic over already-computed values (target, current total, remaining eligible-day count) — no I/O, no Flutter, no Drift, deterministic. This logic lives inside `evaluate()`'s pipeline, not in a presentation-layer "should this render red" helper — the color a screen renders must be a direct, unmodified read of `DayStatus.status` as `evaluate()` computed it (AD-4's whole reason for existing: one function, no re-implementation, no caller second-guessing the result).
- **UX-DR6/UX-DR11/UX-DR20 (five-state vocabulary, Pending never tinted):** per DESIGN.md's Do's/Don'ts, "Pending must render visually distinct from both pass and fail, never tinted toward green or red" (UX-DR11) and per EXPERIENCE.md's State Patterns, "Pending vs. Empty vs. Fail... never collapsed into a generic gray" (UX-DR20). This story is where all five states must simultaneously coexist correctly in the UI for the first time — audit the `status_cell` component's full enum handling, not just the new Fail/Pending cases in isolation.
- **Anti-duplication guidance:** extend `evaluate()`'s existing pipeline (Story 1.7's staged design) with one new final stage; extend the existing `status_cell` component's rendering logic (already handling Success from Story 1.1 and Empty from Story 1.4) rather than building new components. The Cheat (yellow) rendering case can be stubbed into the enum/switch now even though it's unreachable until Epic 2 Story 2.4 — this avoids a rewrite of the status-rendering switch statement later.
- **Testing standards:** FR-18's certain-failure math is exactly the "day-boundary cases" and correctness-critical arithmetic NFR-6 flags as a first-class acceptance bar. Test each Target Comparison's certain-failure boundary explicitly (the exact day/count at which Pending flips to Red), not just a single example — off-by-one errors here are the most likely and most consequential bug class in the whole evaluator.

### Project Structure Notes

- No new top-level folders. Extends `lib/domain/evaluator/evaluate.dart` (new pipeline stage) and `lib/presentation/components/status_cell.dart` (Story 1.1/1.4's component, now handling all five states).
- New test file recommended: `test/domain/evaluator/certain_failure_test.dart` given the volume and importance of boundary-math test cases this story requires.
- No conflicts detected between epics.md, architecture, and UX for this story's scope.

### References

- [Source: docs/epics.md#Story 1.8: Pending, Certain-Failure Red, and the Zero-Eligible-Days Signal]
- [Source: docs/epics.md#Requirements Inventory] (FR-5, FR-18)
- [Source: docs/prd/4-features.md#FR-18: Certain-Failure Red]
- [Source: docs/prd/4-features.md#FR-5: Zero-Eligible-Days Signal]
- [Source: docs/prd/4-features.md#FR-4: Derived Status] (Pending definition)
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4 — Pure Evaluator Contract]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Evaluator flow] (mermaid flowchart — certain-failure decision node)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Colors] (status-pending token, distinct from status-empty/status-fail)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Do's and Don'ts] (UX-DR11 — Pending never tinted toward green/red)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#State Patterns] (UX-DR20 — Pending vs Empty vs Fail never collapsed)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Accessibility Floor] (screen-reader labels per state)
- [Source: docs/stories/1-3-evaluate-all-evaluation-period-types.md] (previous story intelligence — period boundary/remaining-days concept)
- [Source: docs/stories/1-4-eligible-days-rules-presets-and-arbitrary-selection.md] (previous story intelligence — Empty-day default this story's exception overrides at the period level)
- [Source: docs/stories/1-7-target-comparisons-and-free-combination.md] (previous story intelligence — evaluator pipeline stages and comparison predicate this story's certain-failure math consumes)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `flutter analyze lib test`: clean (only the 5 pre-existing `prefer_initializing_formals` info suggestions in `goal_service.dart`).
- `flutter test`: 115/115 passing (100 pre-existing + 12 new in `certain_failure_test.dart` + 3 new in `status_cell_test.dart`).

### Completion Notes List

- Added `_determineStatus()` to `evaluate.dart` as the final pipeline stage (boundary → eligibility → aggregation → comparison → **status determination**), implemented exactly per the switch-statement spec worked out ahead of coding: At Most exceeds immediately to Fail, withholds Success until `remainingEligibleDays <= 0`; Exactly overshoots immediately to Fail, also withholds Success until closure, and additionally short-circuits to Fail early once `actual + remainingEligibleDays < target` for non-unbounded tracking types; At Least reaches Success the moment `actual >= target` (monotonic, can't un-resolve) and only Fails once closed-and-short or provably unreachable.
- `_evaluatePeriod`'s per-date loop now computes `totalEligibleDays` and `remainingEligibleDays` alongside the existing `actual` aggregation, using one shared per-date bucketing: paused/non-eligible days contribute nothing (unchanged); summed Counter days add to `remainingEligibleDays` whenever `cursor >= date` regardless of same-day logs (a summed day's total can still be corrected); Boolean/`counterDoneCount` days that already have a completed log resolve into `actual` permanently, blacked-out unresolved days count as remaining capacity (FR-10 exemption, not a miss), and today-or-future unresolved days count as remaining — everything else (a past, unlogged, non-blackout day) is a genuine used-up miss, contributing to neither number. The `cursor >= date` (not `>`) boundary is deliberate and commented at the point of use: `evaluate()` has no wall-clock notion of "today is over," so the query date itself must stay open/remaining until a later call proves otherwise.
- `_evaluateDay`'s Counter branch now also calls `_determineStatus` (with `remainingEligibleDays: 1`, since a Daily period is always "cursor >= date" relative to itself) instead of the old raw `met ? success : pending` check, giving Daily Counter goals the same overshoot-Fail behavior for At Most/Exactly. The Boolean branch was left untouched per the story's explicit instruction — its existing Pending/Fail/Success logic for the single-day Boolean-Exactly-1 case was already correct.
- Zero-eligible-days short-circuit (FR-5) sits in `_evaluatePeriod` immediately after the aggregation loop, ahead of `_determineStatus`: if `totalEligibleDays == 0` for the whole period, returns Fail immediately, before any comparison math could degenerate ambiguously. Verified this is reachable with a real construction (an Eligible-Days Rule built from an empty weekday set — `EligibleDaysRule.fromWeekdays({})` — the kind of state a "deselect all days" wizard bug could produce) and added a companion test proving an ordinary single non-eligible day within an otherwise-populated period (Story 1.4's per-day Empty case) is unaffected.
- `status_cell.dart` already implemented all five states with distinct glyphs/colors/screen-reader labels from Stories 1.1/1.4 — Task 3 was verification-only; added widget tests confirming Fail and Pending each render their own glyph/label, plus a test asserting Pending/Empty/Fail resolve to three programmatically distinct fill colors (guards UX-DR11/UX-DR20 — Pending must never collapse into a shared gray with Empty or read as a disguised red).
- Judgment call: fixed several pre-existing test expectations in `thirteen_patterns_test.dart` that Story 1.7 had written before certain-failure math existed and that are now provably wrong under the corrected semantics (not just the two the story flagged). Found by re-deriving each test's `remainingEligibleDays` by hand against the new model:
  - Pattern 3 (`Daily`/Counter/At Most 2): logging exactly 2 is now Pending (not Success) — a Daily period always has 1 remaining/open day (itself), so it's not yet certain the limit won't be exceeded later that same day. Exceeding it (3) is now immediate Fail (was Pending).
  - Pattern 2 (`Weekly`/Workdays/Counter-done-count/At least 3) and Pattern 11 (`Weekly`/Workdays/Boolean/At least 3): both "only 2 done" tests were evaluated on the Saturday *after* all 5 workdays had already passed unlogged — under the new model that's a genuinely closed period with 3 workdays missed and 0 remaining, so it's now certain Fail, not Pending. This is structurally the same scenario as AC #2, just discovered by re-checking Story 1.7's own suite rather than being called out by name.
  - Pattern 8 (`Quarterly`/Boolean/Exactly 1) and Pattern 13 (`Weekly`/Boolean/Exactly 2), plus the axis-independence "At Least vs Exactly" test: each had an on-target or overshoot case whose old "Success"/"Pending" expectation didn't account for a still-open remaining day (Exactly withholds Success until closure) or an overshoot (which is now immediate Fail, not Pending). Pattern 8/13's Success cases were fixed by moving the evaluation date to after the period's last eligible day passes (closing the period) rather than weakening the logic; the two overshoot cases were fixed to expect Fail.
  - Cross-checked `evaluate_test.dart`'s Counter/At-least and Weekly/Boolean groups by hand against the new `remainingEligibleDays`/`_determineStatus` math (including the pause-carve-out and Blackout-Date tests) — all passed unchanged, as expected since At Least doesn't get the new "withhold Success until closed" treatment and none of those scenarios happen to close the eligible-day pool to zero.
- No new Drift tables, providers, or codegen — pure `evaluate.dart` pipeline logic plus test coverage.

### File List

- `lib/domain/evaluator/evaluate.dart` — added `_determineStatus()` (the shared certain-failure/status-determination stage); `_evaluatePeriod` now tracks `totalEligibleDays`/`remainingEligibleDays` per-date and applies the zero-eligible-days Fail short-circuit (FR-5) plus `_determineStatus`; `_evaluatePeriod` gained a `sortedBlackoutDates` parameter (FR-10 now consumed at the period level); `_evaluateDay`'s Counter branch now calls `_determineStatus` instead of the old raw `met ? success : pending` check
- `test/domain/evaluator/certain_failure_test.dart` — new: AC #1/#2 (Weekly at-least-3-of-5-workdays boundary), AC #3 (Rolling-Window 10x/14-days, including a "no premature Fail" companion), AC #4 (zero-eligible-days Fail + the Story 1.4/1.8 Empty boundary), and At-Most/Exactly certain-failure boundary math at the period-aggregation level
- `test/domain/evaluator/thirteen_patterns_test.dart` — updated expectations on Patterns 2, 3, 8, 11, 13, and the At-Least-vs-Exactly axis-independence test per the corrected certain-failure semantics (see Completion Notes)
- `test/presentation/status_cell_test.dart` — added Fail/Pending glyph-and-label tests and a Pending/Empty/Fail distinct-fill-color test
- `docs/stories/1-8-pending-certain-failure-red-and-the-zero-eligible-days-signal.md` — status/task checkboxes and this Dev Agent Record
- `docs/stories/sprint-status.yaml` — story status `in-progress` → `review`
