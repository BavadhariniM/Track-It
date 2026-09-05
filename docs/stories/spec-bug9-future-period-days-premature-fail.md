---
title: 'Bug 9: future period days show Fail before the day is even reached'
type: 'bugfix'
created: '2026-09-01'
status: 'in-review'
review_loop_iteration: 0
context: []
baseline_commit: 'NO_VCS'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `evaluate()`'s period-aggregation (`_evaluatePeriod`) decides which days in a period are "still open" by comparing each day to the *queried* `date` itself (`isTodayOrFuture = !cursor.isBefore(date)`). Every live calendar screen calls `evaluate(date: cellDate)` fresh per cell, so querying a future cell (e.g. navigating Day View to next Sunday, or just viewing a future column in Week/Month view) makes every day between real "today" and that future date look already-elapsed — a weekend-only goal can show Fail before either weekend day has actually happened.

**Approach:** Give `evaluate()` an optional `today` parameter (defaults to `date`, so every existing caller/test is byte-identical when omitted). Inside `_evaluatePeriod`, use `today` — never `date` — as the vantage point for the open/closed split, so a real-world-elapsed day can never be treated as "still open" just because some other cell's `date` is earlier. `date` continues to select which period window is being asked about and which row is returned; it stops standing in for "now." Wire the three live-calendar call sites to pass the real current date through.

## Boundaries & Constraints

**Always:**
- `evaluate()` stays pure — no internal `DateTime.now()`/IO; `today` is caller-supplied only.
- `today` defaults to `date` when omitted, so every other existing caller (`StatsService`, `GoalService`, `CacheWriter`, `reminder_suppression_service`, `counter_stepper`, `cheat_blackout_sheet`, `goals_list_screen`) and all of `evaluate_test.dart`/`certain_failure_test.dart` keep passing unmodified.
- The open/closed split always compares each cursor day to `today` (real current date), never to `date`. A day that has already happened in the real world is never "still open," no matter which cell's `date` triggered the call.
- Only `_evaluatePeriod`'s `isTodayOrFuture` line changes. `_evaluateDay`'s Daily-period path is already immune (hardcoded `remainingEligibleDays: 1`) — do not touch it.
- Day View / Week View pass the real date via the existing one-shot `todayDateOnly()` helper; Month View passes its already-threaded reactive `today` field. No new provider plumbing.

**Ask First:** none anticipated — implement as specified.

**Never:**
- Don't change `periodBoundaryFor` or which period window a date belongs to.
- Don't add a wall-clock read inside `evaluate.dart` itself.
- Don't touch `StatsService`/`CacheWriter`/`GoalService` call sites — they only ever query `date <= today` in practice, so the default is already correct there.
- Don't fix the unrelated pre-existing gaps already logged in `deferred-work.md`.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Future weekend day queried mid-week | Weekly period, weekend-only eligible days, "at least 1x/week", real today = Wed, `evaluate(date: Sat)` | vantage = Wed; Thu/Fri/Sat/Sun all count as remaining → Pending, never Fail | N/A |
| Querying today itself | `date == today` | vantage = today = date — identical to current behavior | N/A |
| Querying a past date within the still-ongoing current period | `date < today`, e.g. viewing Monday's cell mid-week | vantage = today; every cell in the not-yet-concluded period shows that period's one live current status, not a stale per-day snapshot | N/A |
| Querying any date within an already-concluded past period | `date` and `today` both after the period ended | vantage = today; remainingEligibleDays = 0 for the whole period, so every cell in it shows that period's one true final outcome | N/A |
| `today` omitted (every pre-existing caller/test) | no `today` arg | defaults to `date`, byte-identical to current logic | N/A |

</frozen-after-approval>

## Code Map

- `lib/domain/evaluator/evaluate.dart` -- add `today` param to `evaluate()`; use it as the sole vantage point inside `_evaluatePeriod`
- `lib/presentation/screens/day_view.dart` -- `_GoalRowForDate`'s `evaluate()` call (~line 233): pass `today: todayDateOnly()`
- `lib/presentation/screens/week_view.dart` -- `_WeekBody.build`'s `evaluate()` call (~line 165): compute `today` once, pass it through
- `lib/presentation/screens/month_view.dart` -- `_dayCell`'s `evaluate()` call (~line 418): pass the already-threaded `today` field
- `test/domain/evaluator/evaluate_test.dart` -- add coverage per the I/O matrix

## Tasks & Acceptance

**Execution:**
- [x] `lib/domain/evaluator/evaluate.dart` -- add optional `DateTime? today` param to `evaluate()`; thread it into `_evaluatePeriod`; compute `final referenceToday = today ?? date;` and use it in place of `date` in the `isTodayOrFuture` line (`!cursor.isBefore(referenceToday)`) -- fixes the root cause, nothing else
- [x] `lib/presentation/screens/day_view.dart` -- pass `today: todayDateOnly()` into `_GoalRowForDate`'s `evaluate()` call -- stops forward Day View navigation from certain-failing not-yet-reached period goals
- [x] `lib/presentation/screens/week_view.dart` -- compute `final today = todayDateOnly();` once in `_WeekBody.build`, pass `today: today` into its `evaluate()` call -- same fix for the Week grid
- [x] `lib/presentation/screens/month_view.dart` -- pass the existing `today` field into `_dayCell`'s `evaluate()` call -- same fix for the Month grid
- [x] `test/domain/evaluator/evaluate_test.dart` -- add cases: future-date-within-period no longer certain-fails; a past, already-concluded period shows one uniform final status across all its cells; omitted `today` unchanged
- [x] `test/presentation/week_view_test.dart` -- updated 3 pre-existing tests whose "expected" computation called `evaluate()` without `today`, out of sync with the widget's now-corrected behavior

**Acceptance Criteria:**
- Given a Weekly, weekend-only-eligible goal with an "at least 1x/week" target and no logs yet, when Day View is navigated forward to a future Sunday while real today is mid-week, then that Sunday's row shows Pending, not Fail.
- Given the same goal, when Month View renders cells for a week that hasn't started yet, then no cell in that not-yet-reached period shows Fail.
- Given a goal whose period has already fully concluded in the past, when any date within that period is queried, then every cell in that period shows the same, single final outcome.
- Given any goal queried with `today` omitted, when `evaluate()` runs, then its output is unchanged from before this fix.

## Spec Change Log

## Design Notes

Every existing test treats `date` as an implicit stand-in for "today" (e.g. `certain_failure_test.dart`'s comments like "Saturday — all workdays passed") — none of them actually validate per-day historical snapshots. That was never a deliberate feature; it was the same underlying bug, just unnoticed for past dates because a fully-elapsed period's outcome rarely gets re-inspected. So the fix does not try to preserve a "day-by-day snapshot" for past dates — it removes the fictional-vantage concept entirely. `today` is always the sole reference for "has this day happened yet"; `date` only ever selects which period window to look at and which row to label. Net effect: every cell within the same not-yet-concluded period will show that period's one live current status, and every cell within an already-concluded period will show its one final outcome — consistent across every day in the period, rather than flickering per cell.

## Verification

**Commands:**
- `flutter test test/domain/evaluator/evaluate_test.dart` -- expect all pass, including new cases
- `flutter test test/domain/evaluator/certain_failure_test.dart` -- expect all pass unmodified (regression check)
- `flutter test` -- expect full suite green
