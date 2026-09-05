# Story 1.5: Custom Recurrence Patterns

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to schedule a goal on patterns like "every 3 days" or "the 2nd Saturday of the month,"
so that irregular but real commitments are modeled precisely instead of forced into a weekly shape.

## Acceptance Criteria

1. **Given** a goal with "every N days" (N=3) anchored to a Jan 1 start date **When** `evaluate()` computes eligible days **Then** they fall on Jan 1, 4, 7, 10… and editing other rules does not re-anchor this cycle (FR-9)
2. **Given** "every N weeks on specific weekdays" and "every N months" **When** evaluated **Then** each produces the correct fixed calendar grid anchored to the goal's start date (FR-9)
3. **Given** "Nth weekday of month" (e.g. 2nd Tuesday) **When** `evaluate()` computes eligibility for a given month **Then** it is computed independently per calendar month, not relative to the goal's start date (FR-9 consequence)
4. **Given** an explicit custom date selection **When** those specific dates are chosen **Then** only those dates are eligible (FR-9)

## Tasks / Subtasks

- [x] Task 1: Extend the Eligible-Days Rule model for custom recurrence (AC: #1, #2, #3, #4)
  - [x] Subtask 1.1: Extend `GoalVersion.eligibleDaysRule` (Story 1.1's field, widened by Story 1.4 into a weekday-set representation) to support additional recurrence-rule variants alongside the plain weekday set: every-N-days, every-N-weeks-on-specific-weekdays, every-N-months, specific-day(s)-of-month, Nth-weekday-of-month, and explicit-custom-date-list. Model this as a discriminated rule type (e.g. `EligibleDaysRule` sealed class/union with variants: `WeekdaySet`, `EveryNDays(n)`, `EveryNWeeks(n, weekdays)`, `EveryNMonths(n)`, `DayOfMonth(days)`, `NthWeekdayOfMonth(nth, weekday)`, `CustomDates(dates)`) rather than overloading the Story 1.4 weekday-set field with special sentinel values — this keeps Story 1.4's simple case clean while giving each custom pattern its own well-typed parameters
  - [x] Subtask 1.2: Persist the new rule variants in the same `eligibleDaysRule` Drift column established in Story 1.1/1.4 — since Drift columns are typically scalar, serialize the discriminated rule (e.g. as a small JSON blob or a `type` + params string) rather than adding new columns per rule type; document the chosen serialization format in code comments since Story 1.9's wizard and any future rule-editing UI must read/write it consistently
- [x] Task 2: Evaluator — custom recurrence eligibility (AC: #1, #2, #3, #4)
  - [x] Subtask 2.1: Extend the eligibility predicate built in Story 1.4 (`lib/domain/evaluator/evaluate.dart` and its internal helpers) with a case per new rule variant — this remains one shared eligibility-check function inside the single `evaluate()`, not a separate "custom recurrence evaluator"
  - [x] Subtask 2.2: Implement every-N-days/every-N-weeks/every-N-months as **anchored to the Goal's start date** (`Goal.startDate`, established in Story 1.1): the cycle is computed as `(date - goal.startDate).inDays % N == 0` for every-N-days (and the calendar-aware equivalents for N-weeks/N-months) — critically, this anchor is `Goal.startDate`, and it must **not** shift when other rules (target, period type, etc.) are edited; Epic 2's versioning will introduce edits that create new `GoalVersion`s, but per FR-9 "editing the Goal's other rules does not re-anchor this cycle" — the anchor stays `Goal.startDate` even across Version changes, not `versionStartDate`. This is an explicit, easy-to-get-wrong detail: use `goal.startDate`, never the active `GoalVersion.versionStartDate`, as the anchor for N-day/N-week/N-month cycles
  - [x] Subtask 2.3: Implement Nth-weekday-of-month (e.g. "2nd Tuesday") as computed **independently per calendar month** — for a given month, find the Nth occurrence of the target weekday within that month; this calculation takes only the month and the rule's (nth, weekday) parameters as input, deliberately ignoring `Goal.startDate` as an anchor (FR-9 consequence, AC #3) — this is the opposite anchoring behavior from Task 2.2's N-day/N-week/N-month cycles, so keep the two code paths clearly distinguished
  - [x] Subtask 2.4: Implement specific-day(s)-of-month (e.g. "the 1st and 15th") as a per-calendar-month check against the stored day-of-month list, with sensible handling for months shorter than a specified day (e.g. day 31 in a 30-day month — document the chosen behavior: skip that month for that occurrence, since the PRD/architecture does not specify a shift-to-last-day fallback; flagged as an open question below)
  - [x] Subtask 2.5: Implement explicit custom-date-selection as a direct set-membership check: a date is eligible iff it appears in the stored `CustomDates` list — no calendar-grid computation at all for this variant
- [x] Task 3: Presentation — custom recurrence selection UI (AC: #1, #2, #3, #4)
  - [x] Subtask 3.1: Extend the eligible-days selection control from Story 1.4 with additional input modes for each custom recurrence variant (N-value entry for every-N-days/weeks/months, weekday+ordinal picker for Nth-weekday-of-month, day-of-month multi-select, and a date-picker-based multi-select for explicit custom dates) — this is an extension of the same selector component, not a parallel UI flow; full wizard integration/step sequencing is Story 1.9's job, but the underlying input controls must exist and function by this story's completion since its ACs are exercised at goal creation/evaluation
- [x] Task 4: Testing (AC: all)
  - [x] Subtask 4.1: Unit-test every-N-days (N=3) anchored to a Jan 1 start date produces exactly Jan 1, 4, 7, 10… and confirm the anchor does not move when other rule fields are changed (simulate an edit to target/period without touching eligible-days and confirm the recurrence dates are unaffected)
  - [x] Subtask 4.2: Unit-test every-N-weeks-on-specific-weekdays and every-N-months for correct anchored grids
  - [x] Subtask 4.3: Unit-test Nth-weekday-of-month across at least two different calendar months to prove it's computed per-month, not via any goal-start-date offset (e.g. confirm "2nd Tuesday" lands correctly in a month where the 1st falls on a Tuesday versus a month where it doesn't)
  - [x] Subtask 4.4: Unit-test specific-day-of-month's short-month edge case (e.g. day 31 rule evaluated against February/April)
  - [x] Subtask 4.5: Unit-test explicit custom-date selection: only the selected dates are eligible, no others
  - [x] Subtask 4.6: Given NFR-6's emphasis on exotic recurrence correctness, ensure this story's test suite in `test/domain/evaluator/` is exhaustive per pattern — this is precisely the "exotic recurrence... edge-case evaluation logic" the NFR calls out as a first-class acceptance bar

## Dev Notes

- **Builds directly on Story 1.4's Eligible-Days Rule mechanism** — this story widens the same field/concept rather than introducing a parallel "custom recurrence" system. The presets from Story 1.4 (every day/workdays/weekends) and this story's custom variants must coexist as different cases of one `EligibleDaysRule` type consumed by one eligibility predicate inside the one `evaluate()` function (AD-4).
- **Two opposite anchoring rules — do not conflate them:**
  - Every-N-days / every-N-weeks / every-N-months: anchored to `Goal.startDate`, fixed forever, never re-anchored by other edits (FR-9).
  - Nth-weekday-of-month: computed fresh per calendar month, with **no** dependency on `Goal.startDate` at all (FR-9 consequence).
  This distinction is explicitly called out by two separate epics.md ACs (AC #1/#2 vs. AC #3) precisely because it's an easy mistake to anchor both the same way.
- **AD-4 (pure evaluator):** all of this logic lives inside `evaluate()`'s internal eligibility-predicate helper (Story 1.4's extension point) — zero I/O, zero Flutter/Drift, deterministic, sorts its own inputs. Calendar-month arithmetic (finding the Nth Tuesday, handling short months) must be implemented with plain date arithmetic, no timezone-aware `DateTime` (NFR-3).
- **AD-6 note (not yet fully exercised):** although this story doesn't implement Goal *editing* (that's Epic 2), the requirement that "editing the Goal's other rules does not re-anchor this cycle" must still be honored by the anchor-choice decision here (`Goal.startDate`, not `GoalVersion.versionStartDate`) so that when Epic 2 Story 2.1 introduces editing, the anchor behavior is already correct by construction rather than needing a fix.
- **Anti-duplication guidance:** extend Story 1.4's eligibility predicate and `EligibleDaysRule` representation; do not create a second "recurrence engine." Reuse the same `evaluate()` call sites, the same Drift `eligibleDaysRule` column (with an extended serialization format), and the same presentation selector component (extended with new input modes) rather than new parallel structures.
- **Testing standards:** this story is the heart of NFR-6's "exotic recurrence" correctness bar. Every recurrence variant needs explicit, isolated unit tests, plus at least one test proving each anchoring behavior (fixed-to-start-date vs. computed-per-month) is implemented as specified, not swapped.

### Project Structure Notes

- No new top-level folders; extends `lib/domain/entities/goal_version.dart` (or a dedicated `lib/domain/entities/eligible_days_rule.dart` if the discriminated-union type warrants its own file — recommended, since it is a meaningfully complex type now), `lib/domain/evaluator/evaluate.dart`, and the Story 1.4 selector component.
- New file recommended: `lib/domain/entities/eligible_days_rule.dart` for the discriminated rule-type union, imported by `goal_version.dart`.
- Open questions flagged below regarding short-month day-of-month handling and the exact serialization format for the extended rule (both left unresolved by epics.md/architecture and required a judgment call here).

### References

- [Source: docs/epics.md#Story 1.5: Custom Recurrence Patterns]
- [Source: docs/epics.md#Requirements Inventory] (FR-9)
- [Source: docs/prd/4-features.md#FR-9: Custom Recurrence]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4 — Pure Evaluator Contract]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Consistency Conventions] (NFR-3 — no timezone/DST)
- [Source: docs/stories/1-4-eligible-days-rules-presets-and-arbitrary-selection.md] (previous story intelligence — eligibility predicate and weekday-set representation being extended here)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `dart analyze lib test`: clean (only the 4 pre-existing info suggestions).
- `flutter test`: 65/65 passing.

### Completion Notes List

- New sealed class `EligibleDaysPattern` (`lib/domain/entities/eligible_days_rule.dart`) with 7 variants: `WeekdaySet` (Story 1.4, unchanged behavior), `EveryNDays`, `EveryNWeeks`, `EveryNMonths` (all three anchored to `Goal.startDate`, never `GoalVersion.versionStartDate` — verified directly with a test that swaps the two anchors and shows the result differs), `DayOfMonth`, `NthWeekdayOfMonth` (computed fresh per calendar month, deliberately ignoring `goalStartDate` — verified across two different months where the 2nd Tuesday lands on a different day-of-month), and `CustomDates`.
- Serialization: prefixed strings (`"every_n_days:3"`, `"nth_weekday:2:2"`, etc.) inside the same `eligibleDaysRule` column; anything without a recognized prefix falls back to Story 1.4's bare CSV weekday-set parsing, so every rule constructed by Stories 1.1–1.4 (including `EligibleDaysRule.everyDay`) reads back correctly with no migration.
- Short-month handling (open question, resolved): `DayOfMonth`/`EveryNMonths` skip a month with no matching day-of-month rather than shifting to the last day — this falls out naturally from iterating real calendar dates (day 31 never occurs in a 30-day month), no special-casing needed.
- `evaluate()`'s `_isEligibleDay` now delegates to `EligibleDaysPattern.decode(...).isEligible(date:, goalStartDate:)` — one shared predicate, still consumed by both the Daily fast path and Story 1.3's period-aggregation loop.
- Presentation: extracted `WeekdayChips` (shared by Story 1.4's `EligibleDaysSelector` and the new `EveryNWeeks` picker) and added `RecurrenceSelector` — a dropdown for the 7 pattern kinds with minimal-but-functional inputs per kind (N text field, day-of-month/custom-dates as comma-separated text entry, Nth/weekday dropdowns). Deliberately not polished (no calendar date-picker widget, no 31-day grid) since Story 1.9's guided wizard is where that polish belongs; the underlying logic and data plumbing are what this story's ACs require.

### File List

- `lib/domain/entities/eligible_days_rule.dart` — new (`EligibleDaysPattern` sealed class + 7 variants)
- `lib/domain/evaluator/evaluate.dart` — `_isEligibleDay` delegates to `EligibleDaysPattern.decode`
- `lib/presentation/components/weekday_chips.dart` — new (extracted from `EligibleDaysSelector`)
- `lib/presentation/components/eligible_days_selector.dart` — refactored to use `WeekdayChips`
- `lib/presentation/components/recurrence_selector.dart` — new
- `lib/presentation/screens/create_goal_screen.dart` — wired in `RecurrenceSelector`
- `test/domain/entities/eligible_days_rule_test.dart` — new
- `test/presentation/recurrence_selector_test.dart` — new
