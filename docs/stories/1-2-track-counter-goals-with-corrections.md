# Story 1.2: Track Counter Goals with Corrections

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to log a numeric Counter goal (e.g. glasses of water) with increments and corrections,
so that I can track quantities, not just done/not-done.

## Acceptance Criteria

1. **Given** a Counter-type goal with target "At least 8" for today **When** Panda taps + on the stepper **Then** the running daily total increases by 1 and is written via GoalService (FR-14)
2. **Given** Panda enters a decimal value directly (e.g. 7.5) **When** they save **Then** the value is accepted and stored (FR-14 — decimals supported)
3. **Given** a Counter goal already has a logged value today **When** Panda logs a negative correction **Then** the day's total decreases but never goes below 0, enforced by GoalService before persisting (FR-15, AD-6)
4. **Given** multiple increments are logged in one day **When** Panda views the day **Then** they see a single running total, not per-increment timestamps (FR-14 consequence)
5. **And** the `numeric` tabular-figure typography token (UX-DR2) is used so digits do not visually shift width as the value updates live

## Tasks / Subtasks

- [x] Task 1: Extend domain entities and evaluator for Counter type (AC: #1, #2, #4)
  - [x] Subtask 1.1: Confirm `GoalVersion.trackingType` (from Story 1.1) supports a `counter` value alongside `boolean`; `GoalVersion.targetComparison`/`targetValue` already exist generically — this story's "At least 8" target is the first non-`Exactly-1` value exercised, but full Target Comparison semantics (At Least/At Most/Exactly/Range across both types) are formally delivered in Story 1.7. For this story, implement only "At Least" support for Counter sufficiently to pass these ACs, and do not hardcode assumptions that block Story 1.7 from adding At Most/Exactly/Range later
  - [x] Subtask 1.2: Extend `lib/domain/evaluator/evaluate.dart` (from Story 1.1) to sum all of a day's `GoalLog.value` entries into a single running total for Counter goals, and compare that summed total against the target — do not create a second evaluator function or a Counter-specific branch file; this is one function widening its Tracking Type handling (AD-4 — every caller shares this one function)
  - [x] Subtask 1.3: `GoalLog.value` (float, already on the entity per Story 1.1's ER-diagram-based definition) is reused as-is for Counter values, including decimals — no schema change needed
- [x] Task 2: GoalService — Counter logging with correction floor (AC: #1, #2, #3, #4)
  - [x] Subtask 2.1: Add `GoalService.logCounter(goalId, date, delta, {note})` use-case: computes the day's new running total as `max(0, currentTotal + delta)` and persists it — the floor-at-0 enforcement lives in `GoalService`, not in presentation, not in the Drift repository, and not in the evaluator (AD-6, FR-15)
  - [x] Subtask 2.2: Decide and document the log-writing strategy consistently with Story 1.1's `GoalLog` shape: since `GoalLog` has no per-increment timestamp field by design (FR-14 consequence — "no per-increment timestamp is captured"), each `logCounter` call must either (a) upsert a single `GoalLog` row per `(goalId, date)` by updating its `value` in place, or (b) insert additional rows that the evaluator sums — pick (a), upsert-in-place per `(goalId, date)`, since it is the direct, non-ambiguous reading of "a single running total" and keeps `evaluate()`'s summing logic in Task 1.2 as a one-row lookup rather than a multi-row aggregation for the common case (still support summing multiple rows defensively in the evaluator for robustness, but the write path should not create multiple rows per day)
  - [x] Subtask 2.3: This upsert-and-floor write is a single Drift transaction, consistent with Story 1.1's transaction-atomicity pattern for `logBoolean` (Transaction atomicity, AD-6)
  - [x] Subtask 2.4: Accept and persist decimal `value`s without any integer coercion anywhere in the write path (FR-14)
  - [x] Subtask 2.5: Accept an optional `note` string on `logCounter`, persisted to `GoalLog.note` (already on the entity per Story 1.1)
- [x] Task 3: Presentation — stepper and direct numeric entry (AC: #1, #2, #3, #5)
  - [x] Subtask 3.1: Build `lib/presentation/components/counter_stepper.dart`: a −/+ stepper for quick increments (per EXPERIENCE.md's Counter entry component pattern) plus a tappable numeric field for direct entry, both routing through `GoalService.logCounter` via its Riverpod provider — no local-only state drives the displayed total; the displayed total always reflects the persisted/evaluated value (AD-4 consistency with Story 1.1's "no separately stored done flag" principle, applied here to Counter totals)
  - [x] Subtask 3.2: A negative correction is entered as a negative delta through the same stepper/field, not a separate "correction mode" UI — the row visibly floors at 0 rather than silently rejecting the input (EXPERIENCE.md Component Patterns — Counter entry)
  - [x] Subtask 3.3: Extend the `goal-row` component from Story 1.1 with its Counter/period-goal variant: progress bar + fraction (e.g. "5/8"), per UX-DR7 — this is the same shared `goal-row` component gaining a second rendering mode, not a new component
  - [x] Subtask 3.4: Apply the `numeric` typography token (tabular/monospaced figures) to every place a Counter value or fraction renders live: the stepper's current value, the goal-row's fraction, so digits don't shift width while incrementing (UX-DR2)
- [x] Task 4: Testing (AC: all)
  - [x] Subtask 4.1: Unit-test `evaluate()`'s Counter-summing behavior in `test/domain/evaluator/evaluate_test.dart`: single log, multiple same-day logs summing correctly (if the defensive multi-row summing path is exercised), decimal values, and correct comparison against an "At least 8" target
  - [x] Subtask 4.2: Unit-test `GoalService.logCounter`'s floor-at-0 behavior explicitly: an existing total of 2 with a delta of −5 must persist 0, never a negative number; verify this is enforced in `GoalService`, not relying on a database CHECK constraint alone (AD-6 requires the domain-layer enforcement point)
  - [x] Subtask 4.3: Unit-test decimal value persistence and retrieval round-trip (7.5 in, 7.5 out, no rounding/truncation)
  - [x] Subtask 4.4: Widget-test the stepper's +/− interactions and direct numeric entry, confirming the rendered value uses the `numeric` typography token and updates from the persisted/evaluated source, not local widget state alone

## Dev Notes

- **Builds directly on Story 1.1** — do not re-create `GoalLog`, `evaluate()`, `GoalService`, the Drift schema, or the `goal-row`/`status-cell` components. This story only *extends* each of those in place: `evaluate()` gains Counter-summing logic, `GoalService` gains `logCounter`, `goal-row` gains its Counter-variant rendering. Reuse the exact file paths and class names Story 1.1 established (`lib/domain/evaluator/evaluate.dart`, `lib/domain/services/goal_service.dart`, `lib/presentation/components/goal_row.dart`).
- **AD-4 (pure evaluator):** the Counter-summing logic must live inside the same single `evaluate()` function from Story 1.1 — still zero I/O, zero Flutter/Drift imports, deterministic, internally sorting any list inputs. Do not add a `evaluateCounter()` sibling function; widen the existing one's Tracking Type branch.
- **AD-6 (GoalService as sole writer, correction floor):** the floor-at-0 rule (FR-15) is explicitly named in AD-6 as something `GoalService` enforces "before persisting a `GoalLog`" — this is not optional placement. Do not implement the floor in the Drift repository (e.g. via a SQL `MAX(0, ...)` clause) as the primary enforcement point; the domain layer must own this logic so it's testable in isolation and consistent regardless of which repository implementation is wired in.
- **FR-14 consequence — no per-increment timestamp:** confirm the write strategy (Task 2.2 — upsert-in-place per `(goalId, date)`) doesn't accidentally introduce a timestamped multi-row log. `GoalLog.timestamp` (already on the entity from Story 1.1's ER-diagram fields) records when the row was last written, not a per-increment audit trail — it is not read by `evaluate()`.
- **Target Comparison scope boundary:** this story only needs "At Least" comparison support for Counter goals to satisfy its ACs. Full Target Comparison coverage (At Most, Exactly, Range, and their combination with Boolean goals too) is Story 1.7's job — do not attempt to build the full comparison matrix here, but also do not write `evaluate()`'s comparison logic in a way that's hardcoded to "At Least" only; keep the target-comparison check as a small, swappable predicate so Story 1.7 extends it rather than rewrites it.
- **UX-DR2 (`numeric` token):** required specifically because Counter values render live and change frequently — apply tabular figures to the stepper's live value and to the goal-row's fraction display. This is the first story that touches live-updating numbers; establish the pattern (e.g. a shared `NumericText` component or a text-style constant) here since Story 1.9 (wizard target step) and Epic 3 (stat cards) will reuse the same token for their own numeric displays.
- **Anti-duplication guidance:** reuse Story 1.1's `goal-row`, `status-cell`, `GoalService`, `evaluate()`, and Drift repositories. The only new presentation component is the stepper/direct-entry control (Task 3.1) — there is no existing stepper to reuse from an earlier story since this is Epic 1's first Counter-type story.
- **Testing standards:** the floor-at-0 correction logic is exactly the kind of boundary-math case NFR-6 calls a first-class acceptance bar — unit-test it directly against `GoalService`, not only indirectly through a widget test. Decimal round-tripping is also a correctness-sensitive case (floating point storage) — verify no precision loss for typical values like 7.5.

### Project Structure Notes

- No new top-level folders required; all new files land inside the seed Story 1.1 established (`lib/domain/evaluator/`, `lib/domain/services/`, `lib/presentation/components/`, `test/domain/evaluator/`).
- New file: `lib/presentation/components/counter_stepper.dart` (new component; not overlapping any Story 1.1 file).
- No conflicts detected between epics.md, architecture, and UX for this story's scope. One judgment call flagged as an open question below: the exact multi-row-vs-upsert write strategy for `GoalLog` under repeated same-day Counter logging is not explicitly specified by epics.md/architecture beyond "single running total, no per-increment timestamp" — this story's Dev Notes resolve it as upsert-in-place, which is the most direct reading, but flag for confirmation if a later story's needs (e.g. average/total stats in Epic 3 Story 3.4) turn out to require per-log granularity instead of a single upserted row.

### References

- [Source: docs/epics.md#Story 1.2: Track Counter Goals with Corrections]
- [Source: docs/epics.md#Requirements Inventory] (FR-14, FR-15)
- [Source: docs/prd/4-features.md#FR-14: Counter Entry]
- [Source: docs/prd/4-features.md#FR-15: Corrections]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4 — Pure Evaluator Contract]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6 — GoalService Owns All Version and Log Writes]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Core-entity relationships] (GOAL_LOG.value, no per-increment timestamp)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Typography] (UX-DR2 — numeric tabular figures)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components] (goal-row Counter/period-goal variant)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Component Patterns] (Counter entry — stepper + direct entry, correction as negative delta floors at 0)
- [Source: docs/stories/1-1-scaffold-the-app-and-track-a-simple-daily-goal.md] (previous story intelligence — established entities, evaluate(), GoalService, Drift schema, goal-row/status-cell components)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `dart analyze lib test`: clean (only the 4 pre-existing `prefer_initializing_formals` info suggestions from Story 1.1).
- `flutter test`: 21/21 passing (17 domain + 4 widget).

### Completion Notes List

- `evaluate()` widened in place (no second function): `trackingType == counter` sums matching same-day `GoalLog.value` rows defensively and compares via a new swappable `_meetsTarget()` predicate (`at_least` only, per Story 1.7's boundary); Boolean's existing branch is untouched.
- `GoalLogRepository` gained `upsertLog`/`getLogForDate`; `DriftGoalLogRepository` implements upsert via `insertOnConflictUpdate` keyed on a reused row `id` looked up per `(goalId, date)`. `GoalService.logCounter` does the read-compute-floor-write inside one transaction, reusing the existing day's row id so repeated taps update one row rather than inserting new ones (FR-14/FR-15).
- `GoalRow` gained the Counter variant (progress bar + fraction, `numeric` tabular-figure style) as a second render branch, not a new component. New `CounterStepper` component (−/+ buttons + direct-entry dialog, all routing through the same delta-based `onDelta` callback — corrections are just negative deltas, no separate mode).
- `CreateGoalScreen` extended with a Boolean/Counter `SegmentedButton` and a target field (Counter only) — still deliberately minimal, not Story 1.9's wizard.
- `DayViewScreen`'s `_GoalRowForDate` branches on tracking type: Counter goals open a small `_CounterStepperDialog` (itself watching providers live, so the stepper always reflects the persisted total, never local-only state) rather than the row's tap directly logging.
- Floor-at-0 and decimal round-trip are unit-tested directly against `GoalService` per Testing standards; widget test exercises Create → Counter → step twice → dialog close → fraction reflects "2/8".

### File List

- `lib/domain/entities/rule_values.dart` — added `TargetComparison.atLeast`, `TrackingType.counter`
- `lib/domain/evaluator/evaluate.dart` — Counter-summing branch + `_meetsTarget()`
- `lib/domain/services/goal_log_repository.dart` — added `upsertLog`/`getLogForDate`
- `lib/domain/services/goal_service.dart` — added `logCounter`
- `lib/data/repositories/drift_goal_log_repository.dart` — added `upsertLog`/`getLogForDate`
- `lib/presentation/components/design_tokens.dart` — added `AppTypography.numeric`, `formatNumeric`
- `lib/presentation/components/counter_stepper.dart` — new
- `lib/presentation/components/goal_row.dart` — added Counter variant
- `lib/presentation/screens/create_goal_screen.dart` — added tracking-type toggle + target field
- `lib/presentation/screens/day_view.dart` — Counter branch + `_CounterStepperDialog`
- `test/domain/evaluator/evaluate_test.dart` — Counter/At-least group
- `test/domain/services/fakes.dart` — `upsertLog`/`getLogForDate` on the fake
- `test/domain/services/goal_service_test.dart` — `logCounter` group
- `test/presentation/day_view_test.dart` — Counter creation + stepper widget test
