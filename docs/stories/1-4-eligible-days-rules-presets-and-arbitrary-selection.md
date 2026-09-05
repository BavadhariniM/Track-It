# Story 1.4: Eligible-Days Rules — Presets and Arbitrary Selection

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to restrict a goal to specific days of the week — workdays, weekends, or any arbitrary subset,
so that goals like "gym on workdays only" are scheduled correctly.

## Acceptance Criteria

1. **Given** goal creation **When** Panda selects the "Every day" preset **Then** all 7 weekdays are eligible (FR-8)
2. **Given** Panda selects "Workdays" **When** the rule is saved **Then** Monday–Friday are eligible, implemented as the same underlying arbitrary-selection mechanism as any custom subset, not a special-cased type (FR-8 consequence)
3. **Given** Panda selects an arbitrary subset (e.g. Mon/Tue/Thu/Sat) **When** saved **Then** exactly those weekdays are eligible and all others are not (FR-8)
4. **Given** a non-eligible day **When** Panda views it in Day View **Then** it renders as `status-empty`, not Pending or Fail (State Patterns)

## Tasks / Subtasks

- [x] Task 1: Model Eligible-Days Rule as arbitrary weekday selection (AC: #1, #2, #3)
  - [x] Subtask 1.1: Define the Eligible-Days Rule representation on `GoalVersion.eligibleDaysRule` (field already present per Story 1.1's ER-diagram-based entity) as a set/bitmask/list of the 7 ISO weekdays (Mon=1..Sun=7) — this is the **one underlying mechanism** for every preset; do not create separate stored "rule type" enums for "every day"/"workdays"/"weekends" that bypass the weekday-set representation (FR-8 consequence: "'Workdays' and 'weekends' are themselves just two convenience presets over the same underlying arbitrary-selection mechanism, not special-cased rule types")
  - [x] Subtask 1.2: Implement the three presets purely as UI/wizard-level conveniences that populate the same weekday-set field: "Every day" → all 7 days; "Workdays" → Mon–Fri (workdays is itself a *configurable* preset per FR-8's PRD note — for Epic 1 default it to Mon–Fri; a user-configurable workdays definition beyond the default is not called out as required by any Epic 1 AC and is out of scope here, flagged as an open question below); "Weekends" → Sat–Sun
  - [x] Subtask 1.3: No new Drift column type is needed beyond what Story 1.1 already created for `eligibleDaysRule` — confirm its storage format (e.g. a comma-separated weekday-number string, or a 7-bit integer mask) is decided now and used consistently, since Story 1.5 (Custom Recurrence) and Story 1.9 (wizard) both read/write this same field
- [x] Task 2: Evaluator — eligibility check (AC: #1, #2, #3, #4)
  - [x] Subtask 2.1: Extend `lib/domain/evaluator/evaluate.dart` (Stories 1.1–1.3) with an eligibility predicate: for a given `date`, is that date's weekday present in the Version's `eligibleDaysRule` set? This predicate gates whether a date counts toward a period's eligible-day pool at all (used by Story 1.3's period aggregation and by Story 1.8's certain-failure math) — implement it as one shared internal helper, not duplicated logic in each period-type branch
  - [x] Subtask 2.2: When a date is not eligible, `evaluate()` must return the `empty` status for that date/day-cell (not `pending`, not `fail`) — this is the default "nothing scheduled" case per the five-state vocabulary (UX-DR1, UX-DR6); the FR-5 zero-eligible-days exception (an entire *period* with zero eligible days turning Red) is Story 1.8's job and must not be conflated with a single non-eligible *day* rendering Empty within an otherwise-normal period
- [x] Task 3: Presentation — wizard/creation preset selection and Day View rendering (AC: #1, #2, #3, #4)
  - [x] Subtask 3.1: Build the eligible-days selection control (used during goal creation — full wizard flow is Story 1.9, but this story must deliver a working selection control since Story 1.4's ACs are exercised "given goal creation"): three preset buttons/chips (Every day / Workdays / Weekends) plus a 7-toggle arbitrary weekday picker, all writing to the same underlying weekday-set — selecting a preset visibly toggles the corresponding weekday toggles (so the arbitrary picker and presets are transparently the same mechanism, reinforcing FR-8's consequence for the user, not just internally)
  - [x] Subtask 3.2: Render non-eligible days in Day View using the `status-empty` treatment from the `status-cell`/`status-badge` vocabulary Story 1.1 built (dash glyph, `status-empty` color, "Not scheduled" or equivalent screen-reader label) — reuse the existing `status_cell.dart` component; do not add a new "not eligible" visual treatment outside that component's five-state enum (UX-DR6, UX-DR20)
- [x] Task 4: Testing (AC: all)
  - [x] Subtask 4.1: Unit-test the eligibility predicate for all three presets and at least one arbitrary subset (Mon/Tue/Thu/Sat), confirming exactly the right weekdays are eligible and all others are not
  - [x] Subtask 4.2: Unit-test that a non-eligible date returns `DayStatus.status == empty` from `evaluate()`, never `pending` or `fail`
  - [x] Subtask 4.3: Widget-test the preset/arbitrary-selection control: selecting "Workdays" visibly checks Mon–Fri and unchecks Sat/Sun; toggling an individual day after a preset selection correctly mutates the underlying set (proving it's one mechanism, not two)
  - [x] Subtask 4.4: Widget-test that a non-eligible day in Day View renders with the `status-empty` visual and correct screen-reader label

## Dev Notes

- **Builds on Stories 1.1–1.3.** Extends the existing `GoalVersion.eligibleDaysRule` field, the single `evaluate()` function, and the `status-cell` component — no new entities, no new Drift tables, no second evaluation path.
- **FR-8 is explicit that presets are not special-cased types:** "Any combination of 1–7 weekdays is selectable. 'Workdays' and 'weekends' are themselves just two convenience presets over the same underlying arbitrary-selection mechanism, not special-cased rule types." A developer must not model this as an enum like `EligibleDaysType { everyDay, workdays, weekends, custom }` with separate evaluation branches — there is exactly one representation (a weekday set) and presets are UI sugar that populate it.
- **State Patterns (non-eligible day = Empty, not Pending/Fail):** per EXPERIENCE.md's State Patterns section, "Empty = not eligible today." This must not be confused with FR-5's zero-eligible-days-for-an-entire-period exception (Story 1.8), which is a *period-level* Red signal, not a *day-level* Empty-vs-something-else distinction. This story only handles the ordinary case: a single day that isn't in the eligible-days set renders Empty.
- **UX-DR6 (status-cell) reuse:** the dash glyph and `status-empty` color/token from Story 1.1's component are the correct rendering for this story's non-eligible-day case — do not add a sixth status or a bespoke "not eligible" chip.
- **Anti-duplication guidance:** reuse `evaluate()`, `status_cell.dart`, and the `GoalVersion` entity from prior stories. The only new pieces are the eligibility predicate (a small addition inside the evaluator) and the preset/arbitrary-selection UI control.
- **Testing standards:** eligibility-predicate correctness is foundational to every later story (custom recurrence, blackout dates, certain-failure math all depend on knowing which days are eligible) — unit-test it thoroughly and independently of any specific period type, since Story 1.3's period aggregation and Story 1.8's certain-failure logic both consume this predicate's output.

### Project Structure Notes

- No new folders; extends `lib/domain/evaluator/evaluate.dart`, `lib/domain/entities/goal_version.dart` (no schema change, just confirming field usage), and adds a new presentation component for eligible-days selection (e.g. `lib/presentation/components/eligible_days_selector.dart`) under the existing `presentation/components/` folder.
- No conflicts detected. One open item flagged below regarding "workdays" configurability.

### References

- [Source: docs/epics.md#Story 1.4: Eligible-Days Rules — Presets and Arbitrary Selection]
- [Source: docs/epics.md#Requirements Inventory] (FR-8)
- [Source: docs/prd/4-features.md#FR-8: Eligible-Days Rule — Arbitrary Selection]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4 — Pure Evaluator Contract]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components] (status-cell — dash glyph for empty)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#State Patterns] (Pending vs. Empty vs. Fail)
- [Source: docs/stories/1-1-scaffold-the-app-and-track-a-simple-daily-goal.md] (previous story intelligence — GoalVersion entity, status-cell component)
- [Source: docs/stories/1-3-evaluate-all-evaluation-period-types.md] (previous story intelligence — evaluate() period-boundary aggregation this eligibility predicate feeds into)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `dart analyze lib test`: clean (only the 4 pre-existing info suggestions).
- `flutter test`: 52/52 passing.

### Completion Notes List

- `eligibleDaysRule` is now a comma-separated ISO-weekday-number string (Mon=1..Sun=7, matching `DateTime.weekday` exactly). `EligibleDaysRule.everyDay`/`workdays`/`weekends` are just precomputed values of the same `fromWeekdays()` builder an arbitrary picker also calls — no separate rule-type enum, per FR-8's explicit "not special-cased" requirement (verified directly: `fromWeekdays({1,2,3,4,5}) == EligibleDaysRule.workdays`).
- `evaluate()`'s `_isEligibleDay` now delegates to `EligibleDaysRule.isEligible`; this is the same one shared predicate already consumed by both the Daily fast path and Story 1.3's period aggregation — no duplication per period type.
- New `EligibleDaysSelector` (preset chips + 7-toggle picker, one shared `Set<int>`) wired into `CreateGoalScreen`; selecting a preset updates the same state a manual toggle would, and vice versa.
- Confirmed AC4 end-to-end: a Workdays-only goal viewed on a Saturday renders `status-empty` (dash glyph, "Not eligible" screen-reader label) in the real Day View, not Pending/Fail — both via a widget test through `DayViewScreen` and a direct `StatusCell` semantics test.

### File List

- `lib/domain/entities/rule_values.dart` — `EligibleDaysRule` rewritten to weekday-set representation
- `lib/domain/evaluator/evaluate.dart` — `_isEligibleDay` delegates to `EligibleDaysRule.isEligible`
- `lib/presentation/components/eligible_days_selector.dart` — new
- `lib/presentation/screens/create_goal_screen.dart` — wired in the selector
- `test/domain/entities/rule_values_test.dart` — new
- `test/domain/evaluator/evaluate_test.dart` — added Eligible-Days Rule group
- `test/presentation/eligible_days_selector_test.dart` — new
- `test/presentation/status_cell_test.dart` — new
- `test/presentation/day_view_test.dart` — added Workdays/Saturday empty-status test
