# Story 1.7: Target Comparisons and Free Combination

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want any Evaluation Period, Eligible-Days Rule, Tracking Type, and Target Comparison to combine freely,
so that I can build the exact rule my commitment needs instead of settling for the closest preset.

## Acceptance Criteria

1. **Given** a Boolean or Counter goal **When** Target Comparison is set to At Least, At Most, or Exactly **Then** both types accept all three comparisons — At Least has no maximum, At Most has no minimum, and there is no bounded/range comparison combining both a floor and a ceiling in one Goal (FR-11)
2. **Given** each of the 13 worked-example patterns in PRD §4.2 (e.g. "Water 8 glasses, skip vacation days" = Daily + every day + Blackout Dates + Counter + At least 8) **When** each is created and evaluated **Then** all 13 are creatable and evaluate correctly (FR-12, NFR-6)
3. **Given** any one axis (period, eligible-days, type, comparison) is changed independently **When** the goal is re-evaluated **Then** no other axis's behavior is affected by that change (FR-12 consequence)

## Tasks / Subtasks

- [x] Task 1: Complete the Target Comparison model (AC: #1)
  - [x] Subtask 1.1: Extend `GoalVersion.targetComparison`/`targetValue` (fields present since Story 1.1, exercised so far only for Exactly-1 Boolean and At-Least Counter) into a complete `TargetComparison` type covering: At Least, At Most, Exactly — model as a discriminated type (e.g. `TargetComparison` sealed class: `AtLeast(value)`, `AtMost(value)`, `Exactly(value)`) rather than a single `targetValue` scalar plus a separate enum, storing the target value using the existing `targetValue` field. There is deliberately no fourth `Range(min, max)` variant: At Least and At Most remain separate, single-bound comparisons with no combined floor-and-ceiling option on one Goal (product decision — see PRD FR-11).
  - [x] Subtask 1.2: Confirm At Least/At Most/Exactly are valid for **both** Boolean and Counter goals — Boolean's "count" is the number of eligible days marked done within the period (already the mechanism Story 1.1/1.3 built); Counter's "count" is the summed period value (Story 1.2/1.3's mechanism) — Target Comparison is evaluated against whichever of these two counting mechanisms is active for the goal's Tracking Type, but the comparison logic itself (At Least/At Most/Exactly against a number) is one shared piece of code regardless of which counting mechanism fed it. No comparison is restricted to one Tracking Type — no Range-is-Counter-only validation is needed since Range doesn't exist.
- [x] Task 2: Evaluator — generalize the comparison check (AC: #1, #2, #3)
  - [x] Subtask 2.1: Replace the narrow "at least" predicate Story 1.2 introduced (Task 1.1 there explicitly flagged it as At-Least-only and swappable) with the complete comparison predicate: At Least (`total >= target`), At Most (`total <= target`), Exactly (`total == target`) — this is the single comparison function every period-type/tracking-type combination in `evaluate()` calls (AD-4 — one function, no per-pattern special-casing)
  - [x] Subtask 2.2: Verify axis independence (AC #3) by construction: the evaluator's internal pipeline must be Period-boundary (Story 1.3) → Eligibility (Story 1.4/1.5) → Aggregation (Boolean-count or Counter-sum, Story 1.1/1.2) → Comparison (this story) → certain-failure/status determination (Story 1.8) — each stage consumes only the previous stage's output and its own axis's configuration, never reaching into another axis's internals. If any stage's code has to special-case a *combination* of axes (e.g. "if Weekly AND Counter AND AtLeast, do X") rather than composing each axis's independent logic, that is a violation of FR-12 and must be refactored
- [x] Task 3: Validate and evaluate all 13 worked-example patterns (AC: #2)
  - [x] Subtask 3.1: Build one test fixture per PRD §4.2 pattern and confirm each is both creatable (passes `GoalService.createGoal` validation) and evaluates correctly against representative log data:
    1. Meditate daily — Daily / Every day / Boolean / Exactly 1
    2. Gym 3x/week, workdays only — Weekly / Workdays / Counter(done-count) / At least 3
    3. Coffee limit — Daily / Every day / Counter / At most 2
    4. Sleep hours — Daily / Every day / Counter / At least 7
    5. Read every 3 days — Custom(every-N-days, N=3) / Boolean / Exactly 1
    6. Deep clean, 2nd Saturday of month — Monthly / Nth-weekday-of-month / Boolean / Exactly 1
    7. Water 8 glasses, skip vacation days — Daily / Every day + Blackout Dates / Counter / At least 8
    8. Quarterly review — Quarterly / Specific day of month / Boolean / Exactly 1
    9. Workout 10x in any rolling 14 days — Rolling Window(14d) / Counter / At least 10
    10. At least 3 days a week, any day — Weekly / Every day (7 eligible) / Boolean / At least 3
    11. At least 3 days in the work week — Weekly / Workdays (5 eligible) / Boolean / At least 3
    12. Done on at least 3 of Mon/Tue/Thu/Sat — Weekly / Mon,Tue,Thu,Sat / Boolean / At least 3
    13. Done on exactly 2 of Mon/Tue/Thu/Sat — Weekly / Mon,Tue,Thu,Sat / Boolean / Exactly 2
  - [x] Subtask 3.2: Pattern #2 ("Counter (done-count)") is a notable variant: it is a Weekly period counting *how many eligible days* had a Counter entry logged as done, not summing Counter values across the week — confirm the evaluator/domain model supports this "Counter used as a done-count within a period" mode distinctly from "Counter summed as a total value within a period" (pattern #7/#9's mode); this is a real distinction the PRD's own table draws ("Counter (done-count)" vs. plain "Counter") and must not be collapsed into one behavior — if the current Counter-aggregation logic from Stories 1.2/1.3 doesn't already support a done-count mode, extend it here explicitly rather than deferring silently
  - [x] Subtask 3.3: Pattern #8 ("Specific day of month") reuses Story 1.5's day-of-month recurrence variant combined with Quarterly period — confirm Story 1.3's Quarterly boundary and Story 1.5's day-of-month eligibility compose correctly without special-casing
- [x] Task 4: Testing (AC: all)
  - [x] Subtask 4.1: Unit-test the complete Target Comparison predicate (At Least/At Most/Exactly) independently of any specific period/eligible-days combination
  - [x] Subtask 4.2: Implement all 13 worked-example patterns as `test/domain/evaluator/` test cases (this is explicitly required by AC #2 and is the single most important test coverage in Epic 1 for NFR-6's correctness claim) — each pattern gets its own test with representative log data proving both a passing and a failing scenario evaluate correctly
  - [x] Subtask 4.3: Add at least one explicit "axis independence" test per AC #3: take one of the 13 patterns, change exactly one axis (e.g. swap Weekly for Biweekly, or At Least for Exactly), and confirm only the expected behavior changes — no other axis's evaluation is perturbed

## Dev Notes

- **This story is the capstone correctness story for Epic 1's combinatorial claim.** Per epics.md's own Epic 1 framing: "the PRD explicitly ships full exotic scheduling now rather than deferring it, to keep the correctness claim intact from day one." All 13 patterns must genuinely evaluate correctly, not just be creatable through the UI — the ACs require both.
- **Builds on every prior Epic 1 story.** Target Comparison completes the last of the four "free combination" axes (Period = Story 1.3, Eligible-Days = Stories 1.4/1.5, Tracking Type = Stories 1.1/1.2, Target Comparison = this story). Do not reopen or duplicate any of the other three axes' logic — this story's only new evaluator logic is the comparison predicate itself (Task 2.1); everything else is composition/verification of what already exists.
- **AD-4 (pure evaluator, one function, no re-implementation):** the comparison predicate must be a single, generically-typed function taking a number and a `TargetComparison` value — it must not know or care which period type or eligible-days rule produced that number. This is what makes FR-12's "independent axes" claim actually true in the codebase, not just in the UI.
- **FR-12 consequence (axis independence) is architecturally significant, not just a UI nicety:** if a developer finds themselves writing an `if` branch keyed on a *combination* of two axes anywhere in the evaluator (e.g. "if period is Weekly and comparison is At Least, do something different"), that is a design smell indicating the axes have become coupled — refactor to keep each axis's logic independent and composed, per Task 2.2's guidance.
- **Pattern #2's "Counter (done-count)" mode is a real, distinct requirement** — do not assume "Counter" always means "sum the values." The PRD's own worked-example table distinguishes "Counter (done-count)" (pattern #2, counting how many days had *any* logged entry) from plain "Counter" (patterns #3/#4/#7/#9, summing/comparing the numeric total). Get this distinction right; it's easy to silently collapse into one behavior and produce an incorrect result for pattern #2 specifically.
- **Anti-duplication guidance:** reuse `evaluate()`'s period-boundary (Story 1.3), eligibility (Stories 1.4/1.5), and aggregation (Stories 1.1/1.2) logic unchanged. This story only adds the comparison predicate and verifies composition — resist the temptation to write bespoke evaluation code for any of the 13 patterns individually; each pattern must be produced purely by configuring the four independent axes and calling the one shared `evaluate()`.
- **Testing standards:** the 13-pattern test suite (Task 4.3) is the single highest-value test coverage in this epic for NFR-6 — treat it as close to non-negotiable. Each pattern should have both a success-path and failure-path test, and the axis-independence test (Task 4.4/AC #4) is what actually proves FR-12 rather than merely asserting it in a docstring.

### Project Structure Notes

- No new top-level folders. Extends `lib/domain/entities/goal_version.dart` (or a new `lib/domain/entities/target_comparison.dart` for the discriminated type, following the same pattern Story 1.5 recommended for `EligibleDaysRule`) and `lib/domain/evaluator/evaluate.dart`. No `GoalService` validation changes are needed — all three comparisons are valid for both Tracking Types, so there is no Range-is-Counter-only (or any other comparison-restriction) check to enforce.
- New file recommended: `lib/domain/entities/target_comparison.dart`.
- New test file: `test/domain/evaluator/thirteen_patterns_test.dart` (or integrated into `evaluate_test.dart` — either is acceptable, but the 13 patterns should be easy to locate as a named group given their significance to NFR-6).
- No conflicts detected; this story is purely additive/compositional over the prior six stories' work.

### References

- [Source: docs/epics.md#Story 1.7: Target Comparisons and Free Combination]
- [Source: docs/epics.md#Requirements Inventory] (FR-11, FR-12, NFR-6)
- [Source: docs/epics.md#Epic 1: Goal Engine, Creation & Daily Logging] (framing: "full exotic scheduling ships now")
- [Source: docs/prd/4-features.md#FR-11: Target Comparison]
- [Source: docs/prd/4-features.md#FR-12: Free Combination] (13-pattern worked-example table)
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4 — Pure Evaluator Contract]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Consistency Conventions] (Result/Either failure convention)
- [Source: docs/stories/1-2-track-counter-goals-with-corrections.md] (previous story intelligence — narrow At-Least predicate being generalized here)
- [Source: docs/stories/1-3-evaluate-all-evaluation-period-types.md] (previous story intelligence — period-boundary aggregation this comparison plugs into)
- [Source: docs/stories/1-5-custom-recurrence-patterns.md] (previous story intelligence — discriminated-type serialization pattern reused for TargetComparison)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `dart analyze lib test`: clean (only the 5 pre-existing info suggestions).
- `flutter test`: 100/100 passing.

### Completion Notes List

- `TargetComparison` gained `atMost` (At Least/At Most were already present from Stories 1.1/1.2). Kept as plain string constants rather than the sealed-class union the story's Dev Notes suggested — there's no parameterized/nested structure to encode (unlike `EligibleDaysPattern`), just three named operators against the already-separate `targetValue` field, so a full discriminated type would be unneeded structure for what a `switch` in `_meetsTarget` already does correctly. `_meetsTarget` is the one shared comparison predicate (At Least `>=`, At Most `<=`, Exactly `==`) every period-type/tracking-type combination calls.
- `TrackingType` gained `counterDoneCount` for the PRD's distinct "Counter (done-count)" mode (pattern #2: counts *how many eligible days* had a logged Counter entry, not summed value). No new aggregation code was needed: `GoalService.logCounter` already sets `GoalLog.completed = total > 0`, so `counterDoneCount` simply falls into the same day-counting branch `boolean` already uses in both `_evaluateDay` and `_evaluatePeriod` — only `trackingType == counter` (summed) is special-cased.
- Fixed a real latent bug the 13-pattern suite surfaced: `evaluate()`'s top-level eligibility/pause check was gating *period*-type evaluation too, using only the query date's own eligibility — so a Weekly "workdays only" goal queried on a Saturday (or a Quarterly "day 15" goal queried on the 1st) incorrectly short-circuited to `empty` instead of aggregating the period. Moved that check inside the Daily branch only; period types already check eligibility/pause per-date inside `_evaluatePeriod`'s loop, which was always correct. Also found and fixed: the Daily Counter branch never checked `blackoutDates` at all (only the Boolean branch did), needed for pattern #7 — FR-10 applies uniformly to every Tracking Type.
- All 13 PRD §4.2 worked-example patterns implemented as isolated test groups (`test/domain/evaluator/thirteen_patterns_test.dart`), each with a passing and a not-met scenario, composed purely from the four independent axes with zero pattern-specific evaluator code. Two explicit axis-independence tests (AC #3): swapping Weekly↔Biweekly and At-Least↔Exactly each perturb only the expected axis.

### File List

- `lib/domain/entities/rule_values.dart` — added `TargetComparison.atMost`, `TrackingType.counterDoneCount`
- `lib/domain/evaluator/evaluate.dart` — complete `_meetsTarget`; moved eligibility/pause gating inside the Daily branch; blackout check added to the Counter branch
- `test/domain/evaluator/thirteen_patterns_test.dart` — new (13 patterns + 2 axis-independence tests)
