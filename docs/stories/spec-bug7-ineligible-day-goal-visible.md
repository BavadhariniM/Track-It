---
title: 'Bug 7: Goals not eligible for a date still render their row in Day View'
type: 'bugfix'
created: '2026-08-31'
status: 'done'
review_loop_iteration: 0
context: []
baseline_commit: 'NO_VCS'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `_GoalRowForDate` in Day View always renders a goal's row once `evaluate()` returns, even when the result is `DayStatusValue.empty` (a Daily-period goal outside its `eligibleDaysRule`, or a blacked-out date) — the row still shows the goal name and a "Not eligible" dash instead of disappearing, unlike two other places in the app (`StatsService.todayProgress`, the widget bridge's `'today'` scope) that already hide a goal for a date when its status is `empty`.

**Approach:** Add one guard in `_GoalRowForDate`, right after `dayStatus` is computed, that omits the row when `dayStatus.status == DayStatusValue.empty` — mirroring the `status != empty` rule already proven at the two call sites above, applied to the one screen still missing it.

## Boundaries & Constraints

**Always:**
- Guard on `dayStatus.status == DayStatusValue.empty`, using the `dayStatus` already computed by the existing `evaluate()` call in `_GoalRowForDate` — do not add a second evaluation path or re-implement `_isEligibleDay`/`EligibleDaysPattern` in the presentation layer.
- Place the guard immediately after `dayStatus` is computed and before it is read for anything else (status cell, DNF badge, counter value, tap handler).

**Ask First:** Nothing — this mirrors an already-shipped pattern verbatim (`StatsService.todayProgress`'s `status != empty` filter, and the widget bridge's `excludeEmptyStatus: true` for its `'today'` scope), just applied to the one screen missing it.

**Never:**
- Do not touch `lib/domain/evaluator/evaluate.dart`, `EligibleDaysPattern`, `_isEligibleDay`, or `_evaluatePeriod` — `DayStatusValue.empty` is already the correct, sufficient signal; no domain change is needed.
- Do not touch Week View, Month View, or the widget bridge's week/month scopes — they deliberately render every cell, including `empty`, for calendar-grid alignment (`excludeEmptyStatus: false`, documented in `widget_bridge_writer_impl.dart`). Only Day View is in scope.
- Do not change `StatusCell`'s rendering of the `empty` status — it's still needed by Week/Month grids.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Daily goal, ineligible weekday | Daily-period goal, `eligibleDaysRule` = Mon/Wed/Fri, Day View showing a Tuesday | Goal's row omitted entirely (no name, no status cell) | N/A |
| Daily goal, eligible weekday | Same goal, Day View showing a Wednesday | Goal's row renders normally with its real status | N/A |
| Blacked-out date, status resolves empty | Goal has a blackout date that evaluates to `DayStatusValue.empty` | Goal's row still renders with a `–` dash, unchanged (deferred — see Design Notes/deferred-work.md) | N/A |
| Period-type goal, non-eligible day within period | Weekly "5x/week, workdays only" goal, Day View showing a Saturday inside an unresolved week | Row still renders with the period's aggregate (non-empty) status — unchanged | N/A |
| Week/Month View, any ineligible date | Same Daily goal as above, viewed in Week or Month grid | Cell still renders as `empty` ("Not eligible") — unchanged | N/A |

</frozen-after-approval>

## Code Map

- `lib/domain/services/paused_range_helper.dart` -- add a new pure helper `isIneligibleDailyDayOn(versions, date, goalStartDate)`, alongside the existing `isPausedOn`, that finds the governing Version for `date` and returns `true` only when it is a Daily-period Version whose `eligibleDaysRule` excludes `date` (via `EligibleDaysPattern.decode(...).isEligible(...)`, same as `evaluate.dart`'s private `_isEligibleDay`).
- `lib/presentation/screens/day_view.dart` -- `_GoalRowForDate.build()` (~line 202-212): add `isIneligibleDailyDayOn(...)` as a third guard alongside the existing `isPausedOn`/pre-start-date guards, before `evaluate()` is called.
- `lib/domain/evaluator/evaluate.dart` -- read-only reference: confirms `_isEligibleDay`'s exact semantics (line 545-552) to mirror in the new helper, and that blackout-caused `empty` (line 147-151, 191-195) and period-type aggregation (line 59-67, 318-324) are untouched by this fix.
- `test/presentation/day_view_test.dart` -- extend with the new ineligible-weekday scenario; the existing Workdays/Saturday test (line 145-164) and the blackout test (line 166-191) are explicitly NOT changed by this fix (see Never, below).

## Tasks & Acceptance

**Execution:**
- [x] `lib/domain/services/paused_range_helper.dart` -- add `isIneligibleDailyDayOn(List<GoalVersion> versions, DateTime date, DateTime goalStartDate)`: find the governing Version for `date` (same lookup `isPausedOn` already does), return `false` if none or if its `evaluationPeriod != EvaluationPeriod.daily`, otherwise return `!EligibleDaysPattern.decode(governing.eligibleDaysRule).isEligible(date: date, goalStartDate: goalStartDate)`.
- [x] `lib/presentation/screens/day_view.dart` -- in `_GoalRowForDate.build()`, add `if (isIneligibleDailyDayOn(versions, date, DateTime.parse(goal.startDate))) return const SizedBox.shrink();` alongside the existing `isPausedOn`/pre-start-date guards, before `evaluate()` is called.
- [x] `test/presentation/day_view_test.dart` -- update the existing "Workdays-only goal ... Saturday" test: it was asserting the exact bug (row visible with a `–` dash on an ineligible date), so its expectation is corrected to `findsNothing` rather than adding a separate, redundant test.

**Acceptance Criteria:**
- Given a Daily-period goal restricted to specific weekdays, when Day View renders a date outside that rule, then the goal's row does not appear at all.
- Given a period-type goal (e.g. weekly) with an unresolved aggregate status, when Day View renders any date within that period — including a day the recurrence excludes — then the row still renders with the period's real status, unchanged from today.
- Given a blacked-out date, when Day View renders it, then the row still renders with a `–` dash, unchanged from today (`day_view_test.dart:166-191` must keep passing unmodified).
- Given Week View or Month View, when rendering any date, then behavior is unchanged — ineligible/blacked-out cells still render as `empty`.

## Spec Change Log

- Narrowed from the original "hide on any `DayStatusValue.empty`" approach after discovering it would also hide blacked-out dates, breaking two existing tests (`day_view_test.dart:145-164`, `:166-191`) that lock in blackout-stays-visible as a deliberate decision from spec-bug5. Panda deferred the "should blackout also hide" question (see `deferred-work.md`) rather than deciding it now, so this fix targets only the weekday-eligibility case via a new, narrowly-scoped presentation-layer helper that never touches blackout or period-type status.
- Review (Edge Case Hunter) found the first implementation applied the new `isIneligibleDailyDayOn` guard unconditionally, before checking blackout status — so a date that was both blacked out *and* excluded by the goal's own weekday rule (reachable via a Story 2.1 mid-stream rule edit made after the blackout was set) would be hidden, contradicting this spec's own Acceptance Criteria that blackout dates must keep rendering. Fixed by gating the new guard on `!isBlackedOutToday` in `day_view.dart`. KEEP: the narrow, Daily-only scope of `isIneligibleDailyDayOn` itself was correct and is unchanged — only its call site's guard ordering was fixed. Also corrected a stale I/O-matrix row (leftover from the pre-narrowing draft) that still said blackout rows get omitted; it now matches the Acceptance Criteria and the actual, tested behavior.
- Review also flagged (deferred, not fixed here — see `deferred-work.md`): missing regression coverage for period-type goals never hiding via this guard (added as unit tests on `isIneligibleDailyDayOn` instead, which is a more precise place for that invariant than a full wizard-driven widget test); triplicated governing-Version-lookup logic across `isPausedOn`, `isIneligibleDailyDayOn`, and `evaluate.dart`'s `_findGoverningVersion`; and an identical "Not eligible" visibility issue on Goal Detail's Current Pace stat card, out of scope for a Day View fix.

## Design Notes

The original approach (guard on `dayStatus.status == DayStatusValue.empty` generically) would have matched the already-shipped `status != empty` filter used by `StatsService.todayProgress` and the widget bridge's `'today'` scope — but `empty` is overloaded: it's also returned for blackout dates, and two existing tests assert blackout dates must stay visible (a deliberate spec-bug5 decision, not an oversight). Since that question is now explicitly deferred rather than decided, this fix instead adds a new, narrowly-scoped presentation-layer predicate — mirroring `isPausedOn`'s existing shape exactly — that only answers "does this Daily-period goal's own weekday/recurrence rule exclude this date," leaving blackout and period-type behavior completely untouched.

## Verification

**Commands:**
- `flutter test test/presentation/day_view_test.dart` -- expected: all pass, including the new ineligible/blackout/period-type cases.
- `flutter analyze` -- expected: no new issues.

**Manual checks (if no CLI):**
- Run the app, create a Daily goal restricted to e.g. Mon/Wed/Fri, and confirm it disappears from Day View on Tue/Thu/Sat/Sun while still showing on Mon/Wed/Fri.

## Suggested Review Order

**Eligibility predicate**

- New pure helper: the "not scheduled for this day" check, scoped to Daily-period goals only.
  [`paused_range_helper.dart:42`](../../lib/domain/services/paused_range_helper.dart#L42)

- Unit coverage locking in the Daily-only scope, including the period-type-must-never-hide invariant.
  [`paused_range_helper_test.dart:81`](../../test/domain/services/paused_range_helper_test.dart#L81)

**Day View wiring & blackout precedence**

- The guard itself, and why blackout must be checked first (review-found ordering bug, fixed here).
  [`day_view.dart:214`](../../lib/presentation/screens/day_view.dart#L214)

- Widget coverage: ineligible day hides the row.
  [`day_view_test.dart:146`](../../test/presentation/day_view_test.dart#L146)

- Widget coverage: a blackout on an already-ineligible day still wins and shows the row.
  [`day_view_test.dart:192`](../../test/presentation/day_view_test.dart#L192)

- Unchanged control: blackout on an otherwise-eligible day still shows the row (locks in spec-bug5's decision).
  [`day_view_test.dart:165`](../../test/presentation/day_view_test.dart#L165)
