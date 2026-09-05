---
title: 'Bug 8: Today tab cannot modify goal completion, only Day View can'
type: 'bugfix'
created: '2026-08-31'
status: 'done'
review_loop_iteration: 0
context: []
baseline_commit: 'NO_VCS'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Today (`dashboard_screen.dart`) and Day View (`day_view.dart`) render goal rows through the shared `GoalRow` component, but only Day View wires it to write actions (boolean toggle, counter stepper, Cheat Day/Blackout). On Today, tapping anywhere only navigates to Goal Detail — no way to log today's completion without going via a calendar date.

**Approach:** Split each Today row into two tap zones: name/streak still navigates to Goal Detail (unchanged), right-side status area becomes tappable to toggle completion or open the counter stepper — mirroring `_GoalRowForDate`'s existing logic, incl. the Bug 4 undo guard, scoped to today. Long-press anywhere opens Cheat Day/Blackout. `GoalRow` gains an optional `onNameTap`; when omitted (Day View, Goals List, Week View), it keeps today's single whole-row-tap behavior exactly. Extract Day View's private `_CounterStepperDialog` into a shared widget. Status display keeps coming from `StatsService`/`todayProgressProvider` (AD-7/AD-8) — no `evaluate()` call added in `dashboard_screen.dart`.

## Boundaries & Constraints

**Always:**
- `GoalRow`: add optional `onNameTap`. `null` → unchanged single `InkWell` over the whole row (Day View/Goals List/Week View unaffected). Non-null → two `InkWell` zones: left (dot+name/streak) uses `onNameTap`, right (trailing area) uses `onTap`; both get `onLongPress`.
- Today passes `onNameTap` = Goal Detail nav (today's current behavior), `onTap` = new toggle/stepper logic.
- Reuse `GoalService.logBoolean`/`undoBooleanLog`/`logCounter`, `showCheatBlackoutSheet`, and the extracted dialog verbatim.
- Mirror `_GoalRowForDate`'s Bug 4 gate: undo only when today's own log (`goalLogsProvider`) has `completed == true`; when period resolved via another date, right-side `onTap` is `null`.
- All writes target `date: DateTime.now()` — Today has no date picker.
- Apply the split to every `_DashboardGoalRow` (main list + rollups) — writes always target today regardless of section.
- Keep status display sourced from `todayProgressProvider` only; no `evaluate()` in `dashboard_screen.dart`.

**Ask First:** Nothing — Day View's write logic applied to a second screen, plus a backward-compatible opt-in row split.

**Never:**
- Do not change `GoalRow`'s behavior for callers that skip `onNameTap` (Day View/Goals List/Week View stay identical).
- Do not add a date picker or let Today edit any date but today.
- Do not touch `StatsService`/`todayProgress`/`weekRollup`/`monthRollup`.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Tap name/streak | Any Today row | Navigates to Goal Detail (unchanged) | N/A |
| Tap right side, unlogged boolean | No log for today | `logBoolean`; row flips to Success | N/A |
| Tap right side, logged boolean | Today's log `completed: true` | `undoBooleanLog`; row reverts | N/A |
| Tap right side, period resolved elsewhere | Success via another date, today untouched | No-op (`onTap: null`) | N/A |
| Tap right side, counter goal | Any counter row | Opens shared stepper dialog; deltas call `logCounter` | N/A |
| Long-press, either zone | Any eligible row | Opens Cheat Day/Blackout, scoped to today | N/A |
| Day View / Goals List / Week View row | `onNameTap` not passed | Identical to pre-change behavior | N/A |

</frozen-after-approval>

## Code Map

- `lib/presentation/components/goal_row.dart` -- add optional `onNameTap`; split into two `InkWell` zones when set, else keep current single-zone structure.
- `lib/presentation/components/counter_stepper.dart` -- add public `CounterStepperDialog`, moved verbatim from `day_view.dart`'s private `_CounterStepperDialog`.
- `lib/presentation/screens/day_view.dart` -- remove `_CounterStepperDialog`; point `_GoalRowForDate`'s counter `onTap` at the shared widget (no `onNameTap` passed).
- `lib/presentation/screens/dashboard_screen.dart` -- `_DashboardGoalRow` (lines 124-151): watch `goalLogsProvider(goalStatus.goal.id)`, compute `logForDate`/`ownLogCompleted`/`periodResolvedElsewhere` mirroring `day_view.dart` lines 249-286; pass `onNameTap`, `onTap`, `onLongPress` per Boundaries, all scoped to `date: DateTime.now()`.
- `lib/presentation/components/cheat_blackout_sheet.dart` -- read-only reference; already self-contained on `(goal, date)`.
- `lib/presentation/providers/goal_data_providers.dart` -- read-only reference; `goalLogsProvider` already exists.
- `test/presentation/goal_row_test.dart` (new) -- covers the `onNameTap` split vs. legacy single-zone behavior.
- `test/presentation/dashboard_screen_test.dart` -- extend with name-tap-navigates, right-tap-toggle, long-press coverage.

## Tasks & Acceptance

**Execution:**
- [x] `lib/presentation/components/goal_row.dart` -- add `onNameTap` and the two-zone split -- enables Today's split interaction without touching other callers.
- [x] `lib/presentation/components/counter_stepper.dart` -- add public `CounterStepperDialog` (moved from `day_view.dart`) -- shared reuse point.
- [x] `lib/presentation/screens/day_view.dart` -- delete private `_CounterStepperDialog`; use the shared widget -- avoids duplication.
- [x] `lib/presentation/screens/dashboard_screen.dart` -- wire `_DashboardGoalRow`'s `onNameTap`/`onTap`/`onLongPress` per Boundaries -- closes Bug 8.
- [x] `test/presentation/goal_row_test.dart` -- new: `onNameTap` null renders one legacy zone; set renders two independent zones; long-press fires from either.
- [x] `test/presentation/dashboard_screen_test.dart` -- add: name tap navigates; right-tap toggles/undoes/no-ops per state; right-tap on counter opens stepper; long-press opens sheet.

**Acceptance Criteria:**
- Given any Today row, when the name/streak area is tapped, then Goal Detail opens, unchanged from today.
- Given an unlogged boolean goal, when the right-side status area is tapped, then it's marked done for today in place.
- Given a boolean goal already logged done today, when the right-side area is tapped, then today's log is undone.
- Given a counter goal, when the right-side area is tapped, then the same stepper dialog Day View uses opens and persists via `logCounter`.
- Given any Today row, when long-pressed (either zone), then the Cheat Day/Blackout sheet opens scoped to today.
- Given Day View, Goals List, or Week View, when used, then behavior is unchanged from before this fix.

## Design Notes

`_GoalRowForDate` already implements every write interaction correctly, including the Bug 4 fix — Today just needs it wired in, plus a way to keep its existing stats navigation alongside the new toggle. Splitting `GoalRow` behind an optional, opt-in `onNameTap` avoids a second row component while guaranteeing every other caller is untouched — they never pass the new parameter, so the widget falls back to its current single-zone path unchanged.

## Verification

**Commands:**
- `flutter test test/presentation/goal_row_test.dart test/presentation/dashboard_screen_test.dart test/presentation/day_view_test.dart test/presentation/goals_list_screen_test.dart test/presentation/week_view_test.dart` -- expected: all pass, non-Today screens unchanged.
- `flutter analyze` -- expected: no new issues.

**Manual checks (if no CLI):**
- Open Today: tap a goal's name (still opens Goal Detail), tap the right side of a boolean goal (marks/unmarks done), tap the right side of a counter goal (adjusts it), long-press a row (opens Cheat Day/Blackout). Confirm Day View and Goals List behave exactly as before.

## Suggested Review Order

**Split-zone interaction (the core mechanism)**

- Entry point: branches legacy single-`InkWell` (unaffected callers) vs. the new two-zone layout.
  [`goal_row.dart:77`](../../lib/presentation/components/goal_row.dart#L77)

- The two-zone layout itself — `IntrinsicHeight` lets both zones share one height without needing a bounded parent (a first attempt using `CrossAxisAlignment.stretch` alone crashed inside the scrolling list with "BoxConstraints forces an infinite height"; wrapping in `IntrinsicHeight` fixed it).
  [`goal_row.dart:91`](../../lib/presentation/components/goal_row.dart#L91)

- New optional callback and its doc comment explaining the split contract.
  [`goal_row.dart:54`](../../lib/presentation/components/goal_row.dart#L54)

**Today's write wiring (closes Bug 8)**

- `_DashboardGoalRow`: watches today's own log, mirrors Day View's Bug 4 undo-guard, and wires `onNameTap`/`onTap`/`onLongPress`.
  [`dashboard_screen.dart:141`](../../lib/presentation/screens/dashboard_screen.dart#L141)

- The three-way tap decision (counter dialog vs. boolean toggle/undo vs. no-op when period resolved elsewhere).
  [`dashboard_screen.dart:162`](../../lib/presentation/screens/dashboard_screen.dart#L162)

**Shared counter dialog (dedup, avoids a second copy of Day View's logic)**

- `CounterStepperDialog` promoted to public, moved verbatim from Day View's former private class.
  [`counter_stepper.dart:17`](../../lib/presentation/components/counter_stepper.dart#L17)

- Day View's call site updated to use the shared widget; everything else in this file is unchanged.
  [`day_view.dart:268`](../../lib/presentation/screens/day_view.dart#L268)

**Tests**

- Legacy-vs-split-zone coverage for `GoalRow`, including the "tap the status dot, not just the two text labels" regression guard added during review.
  [`goal_row_test.dart:1`](../../test/presentation/goal_row_test.dart#L1)

- Today-tab coverage: name-tap navigation, mark/undo, counter dialog (now asserts the dialog's date, not just its type), the period-resolved-elsewhere no-op (added during review), and the Cheat/Blackout long-press.
  [`dashboard_screen_test.dart:117`](../../test/presentation/dashboard_screen_test.dart#L117)
