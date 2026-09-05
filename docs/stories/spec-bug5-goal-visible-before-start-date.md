---
title: 'Bug 5: Goal cells visible on dates before the goal''s start date'
type: 'bugfix'
created: '2026-08-31'
status: 'done'
review_loop_iteration: 0
context: []
baseline_commit: 'NO_VCS'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** A goal with a future/recent `startDate` still shows up on calendar dates before it started. Day View and the Goals List "today" row render `0/0` (Counter) because `evaluate()` returns `DayStatusValue.empty` with no `targetValue`, and `GoalRow` falls back to `target ?? 0`. Week View, Month View, and the home-screen widgets (week/month scopes) similarly render an "empty" status cell for that goal on those dates instead of omitting it. Every one of these call sites already has a precedent for suppressing a (goal, date) pair entirely before evaluating — an `isPausedOn` check — but none of them also check `date < goal.startDate`.

**Approach:** Add a `date < goal.startDate` guard at every call site that already has the `isPausedOn` guard, using the exact same suppression the paused check already produces there (skip the widget/list entry, `null` status-cell entry, or `continue` in a loop) — never introduce a new suppression mechanism.

## Boundaries & Constraints

**Always:**
- Compare using `formatDateOnly(date)` (or the already-materialized `dateStr`) against `goal.startDate` via string `compareTo` — both are naive `YYYY-MM-DD` strings, consistent with how each file already normalizes dates. Do not introduce `DateTime.parse`-based comparison.
- Place the new guard directly alongside the existing `isPausedOn` check at each site, producing the exact same "excluded" result that check already produces there (see Code Map/Tasks for the specific shape per file).

**Ask First:** Nothing — this is the same narrow guard clause, mechanically repeated at every site that already guards on `isPausedOn`.

**Never:**
- Do not modify `evaluate()`, `_findGoverningVersion`, or any `EligibleDaysPattern.isEligible` implementation in `lib/domain/evaluator/` or `lib/domain/entities/eligible_days_rule.dart` — AD-4 makes `evaluate()` the single evaluator entry point; this fix stays at the presentation/bridge-level visibility gate, matching the existing paused precedent.
- Do not suppress based on `DayStatus.status == empty` generically — that status is also returned for ineligible weekdays, blackout days, and paused versions (all legitimate, still-visible states); the guard must compare dates directly, not status.
- Do not change `StatsService` (`lib/domain/services/stats_service.dart`) — it already walks forward from `goal.startDate` and is unaffected.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Day View, date before start | Goal `startDate: '2026-09-05'`, viewing `2026-09-01` | No row rendered for that goal | N/A |
| Goals List, startDate in future | Goal `startDate` later than today | Goal omitted from "today" list | N/A |
| Week View, date before start | Same goal, week grid includes `2026-09-01` | That day's cell renders no color (same as a paused cell) | N/A |
| Month View, date before start | Same goal, month grid includes `2026-09-01` | Goal excluded from that day's aggregated cell | N/A |
| Widget bridge, date before start | Week/month widget scope range includes `2026-09-01` | No cell emitted for that (goal, date) | N/A |
| Any surface, date on/after start | `2026-09-05` or later | Renders exactly as before this change | N/A |

</frozen-after-approval>

## Code Map

- `lib/presentation/screens/day_view.dart` -- `_GoalRowForDate.build`, guard next to its `isPausedOn` check (~line 202).
- `lib/presentation/screens/goals/goals_list_screen.dart` -- "today" row builder, guard before its direct `evaluate()` call (~line 198).
- `lib/presentation/screens/week_view.dart` -- `_WeekBody`'s `statusesByGoal` list comprehension (~line 160), guard alongside its `isPausedOn` ternary.
- `lib/presentation/screens/month_view.dart` -- `_dayCell`'s `statuses` list comprehension (~line 411-423), guard alongside its `isPausedOn` condition.
- `lib/data/widget_bridge/widget_bridge_writer_impl.dart` -- `_writeScope`'s per-date/per-goal loop (~line 158), guard alongside its `isPausedOn` continue; `_EligibleGoal.goal.startDate` (line 217-218) is the field to read.
- `lib/domain/entities/goal.dart:28` -- `Goal.startDate`, the naive `YYYY-MM-DD` string being compared everywhere above.

## Tasks & Acceptance

**Execution:**
- [x] `lib/presentation/screens/day_view.dart` -- add `if (formatDateOnly(date).compareTo(goal.startDate) < 0) return const SizedBox.shrink();` before `evaluate()` -- suppresses the row like the paused check does.
- [x] `lib/presentation/screens/goals/goals_list_screen.dart` -- add the same guard using `today` before its `evaluate()` call -- omits the goal from the list.
- [x] `lib/presentation/screens/week_view.dart` -- extend the `isPausedOn(...)` ternary condition with `|| formatDateOnly(day).compareTo(goal.startDate) < 0` so the list entry is `null` (same as paused) instead of an evaluated status.
- [x] `lib/presentation/screens/month_view.dart` -- extend the `!isPausedOn(...)` condition with `&& dateStr.compareTo(goal.startDate) >= 0` so the goal is excluded from that day's aggregated `statuses` list (same as paused).
- [x] `lib/data/widget_bridge/widget_bridge_writer_impl.dart` -- add `if (dateStr.compareTo(entry.goal.startDate) < 0) continue;` alongside the existing `isPausedOn` continue in `_writeScope`.
- [x] `test/presentation/day_view_test.dart` -- goal with future `startDate` renders no row before it, renders normally on/after it.
- [x] `test/presentation/goals_list_screen_test.dart` -- goal with future `startDate` omitted from "today".
- [x] `test/presentation/week_view_test.dart` -- goal's cell for a pre-start date renders no color, same as a paused cell.
- [x] `test/presentation/month_view_test.dart` -- goal excluded from a pre-start date's aggregated cell.
- [x] `test/data/widget_bridge/widget_bridge_writer_impl_test.dart` -- no cell emitted for a (goal, date) pair before `goal.startDate` in week/month scopes.

**Acceptance Criteria:**
- Given a goal with `startDate` in the future relative to the viewed date, when Day View or Goals List renders that date, then no row/entry for that goal appears.
- Given the same goal, when Week View, Month View, or a widget scope renders that date, then that goal contributes nothing to that date's cell (same treatment as a paused date).
- Given the same goal, when any surface renders `startDate` itself or a later date, then rendering is unchanged from current behavior.

## Spec Change Log

- Widened from Day View + Goals List only to also cover Week View, Month View, and the widget bridge (week/month scopes), per human request to apply the same guard everywhere the `isPausedOn` precedent already exists, rather than only where a numeric count is shown.

## Design Notes

## Verification

**Commands:**
- `flutter test test/presentation/day_view_test.dart test/presentation/goals_list_screen_test.dart test/presentation/week_view_test.dart test/presentation/month_view_test.dart` -- expected: all pass, including new pre-start-date cases.
- `flutter test test/data/widget_bridge/widget_bridge_writer_impl_test.dart` -- expected: all pass, including new pre-start-date case.
- `flutter analyze` -- expected: no new warnings/errors.

## Suggested Review Order

**Pre-start-date guard (the core fix)**

- Entry point: the row-suppression guard, right next to the existing paused-date guard it mirrors.
  [`day_view.dart:206`](../../lib/presentation/screens/day_view.dart#L206)
- Same guard on the Goals List's own direct `evaluate()` call site.
  [`goals_list_screen.dart:205`](../../lib/presentation/screens/goals/goals_list_screen.dart#L205)
- Week View: folded into the existing paused-day ternary so the cell renders `null` (no color) instead of an evaluated status.
  [`week_view.dart:160`](../../lib/presentation/screens/week_view.dart#L160)
- Month View: folded into the existing paused-day aggregation filter.
  [`month_view.dart:414`](../../lib/presentation/screens/month_view.dart#L414)
- Widget bridge: same `continue` shape as the existing paused-pair skip, applied per (goal, date) in the shared write loop.
  [`widget_bridge_writer_impl.dart:160`](../../lib/data/widget_bridge/widget_bridge_writer_impl.dart#L160)

**Review follow-through (adversarial-review patch)**

- A future-start goal now defaults into the "Active" lifecycle bucket with no visible row — excluded from grouping entirely so its header never renders empty.
  [`goals_list_screen.dart:121`](../../lib/presentation/screens/goals/goals_list_screen.dart#L121)

**Tests**

- Confirms the row disappears before `startDate` and reappears once it's reached.
  [`day_view_test.dart:313`](../../test/presentation/day_view_test.dart#L313)
- Confirms omission plus no dangling group header, and the on/after-start boundary.
  [`goals_list_screen_test.dart:96`](../../test/presentation/goals_list_screen_test.dart#L96)
- Confirms all-cells-hidden before start and all-cells-restored at the boundary.
  [`week_view_test.dart:487`](../../test/presentation/week_view_test.dart#L487)
- Confirms aggregate exclusion before start and inclusion at the boundary.
  [`month_view_test.dart:616`](../../test/presentation/month_view_test.dart#L616)
- Confirms week/month scopes exclude the cell too, isolating this from the pre-existing Empty-status filter.
  [`widget_bridge_writer_impl_test.dart:226`](../../test/data/widget_bridge/widget_bridge_writer_impl_test.dart#L226)
