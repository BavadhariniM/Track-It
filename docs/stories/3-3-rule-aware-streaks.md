---
baseline_commit: NO_VCS
---

# Story 3.3: Rule-Aware Streaks

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want a non-daily goal's streak to count consecutive successful weeks/months, not consecutive days, and a Rolling Window goal to show its current pace instead of a streak,
so that the number I see actually means what I think it means.

## Acceptance Criteria

1. **Given** a Weekly "3x/week" goal, **when** its Streak is computed, **then** it counts consecutive successful Evaluation Periods (weeks), not consecutive days (FR-29)
2. **Given** a Daily goal, **when** its Streak is computed, **then** it counts consecutive successful days, as before — Daily is the one case where period equals day (FR-29)
3. **Given** a Rolling Window goal, **when** Panda views its stats, **then** no Streak stat is shown at all — only current pace/status (FR-29 consequence)
4. **And** since `StatsService` (AD-8) is the sole streak/rollup computer, the Dashboard and Goal Detail show the identical streak value for the same goal — neither computes it independently

## Tasks / Subtasks

- [x] Task 1: Finish the rule-aware streak algorithm in `StatsService` (AC: 1, 2, 3)
  - [x] Subtask 1.1: In `lib/domain/services/stats_service.dart` (created Story 3.1), replace/extend the Daily-only streak implementation with a period-aware algorithm: walk backward through the goal's Evaluation Periods (as bounded per the goal's `GoalVersion` history and AD-5's version-boundary period splitting), counting consecutive periods whose `evaluate()`/cached result is Success, stopping at the first non-Success (Fail) period
  - [x] Subtask 1.2: For Daily goals, a "period" is a single day, so the algorithm degenerates to counting consecutive successful days — verify this is literally the same code path with period-length = 1 day, not a separate branch, to avoid two divergent implementations for what AD-4/AD-8 treat as one concept
  - [x] Subtask 1.3: For Rolling Window goals, make `StatsService`'s streak method return an explicit "not applicable" result (e.g. `null` or a sealed `NoStreak` case) rather than a computed number — callers (Dashboard, Goal Detail) must branch on this and render "current pace/status" instead, never a fabricated streak of 0 or 1
  - [x] Subtask 1.4: Handle the case where a `GoalVersion` boundary falls inside the walked-back range: each period is evaluated against its own governing Version (already true of `evaluate()` per AD-5); when a Version change also changes the goal's Evaluation Period *type* itself (e.g. Weekly → Monthly), treat that as a streak-continuity break (confirmed product behavior — see Dev Notes), since "3 consecutive weeks" and "2 consecutive months" are not the same unit and cannot be concatenated into one count
  - [x] Subtask 1.5: Ensure `evaluate()` remains the single source of pass/fail truth for each period walked — `StatsService` reads cached `DayStatus`/period outcomes first and falls back to `evaluate()` for any uncached period, per Story 3.1's established fallback pattern; it must not reimplement pass/fail logic itself, only the consecutive-counting loop around `evaluate()`'s output

- [x] Task 2: Longest-streak tracking alongside current streak (AC: 1, 2)
  - [x] Subtask 2.1: Extend the same walk-backward-through-history logic to also track the longest historical run of consecutive successful periods (needed for the `stat-card` "longest Streak" value introduced in Story 3.2) — implement as one pass over history producing both current and longest streak, not two separate walks

- [x] Task 3: Update callers to the finalized contract (AC: 3, 4)
  - [x] Subtask 3.1: In `dashboard_screen.dart` (Story 3.1) and `goal_detail_screen.dart` (Story 3.2), branch on the Rolling Window "no streak" result: render the goal's current pace/status text instead of a streak `stat-card`/row value — do not silently show a blank or zero
  - [x] Subtask 3.2: Confirm neither screen was, prior to this story, computing any part of the streak locally as a stopgap — if Story 3.1's Daily-only implementation left any Dashboard-side special-casing, remove it now that `StatsService` is complete (no screen may compute a streak independently, per AD-8 and this story's AC4)

- [x] Task 4: Testing — this is the correctness-critical story (AC: 1, 2, 3, 4)
  - [x] Subtask 4.1: `test/domain/` unit tests: a Weekly "3x/week" goal with 4 consecutive successful weeks then 1 failed week reports current streak 0 and longest streak 4 (or current streak continuing correctly if the failed week is not the most recent — cover both orderings)
  - [x] Subtask 4.2: Unit test: a Daily goal's streak matches counting consecutive successful days exactly (regression check against Story 3.1's original Daily implementation)
  - [x] Subtask 4.3: Unit test: a Rolling Window goal's streak query returns the "not applicable" result, never a number
  - [x] Subtask 4.4: Unit test: a goal edited mid-history from Weekly to Monthly (Evaluation Period type change via Epic 2's versioning) — verify the confirmed continuity-break behavior from Subtask 1.4 is what's actually implemented (test the decision, not just its absence of a crash)
  - [x] Subtask 4.5: Unit test: a goal with a Paused segment (Epic 2 Story 2.2) in its history — the paused range produces no Eligible Days and therefore no evaluated periods to break or extend the streak; verify pausing does not itself count as a "failed period"
  - [x] Subtask 4.6: Integration/widget test: render the same goal on both `DashboardScreen` and `GoalDetailScreen` and assert the displayed streak values are byte-for-byte identical (AC4)

## Dev Notes

- **This story is the correctness core of Epic 3 — treat it with the same rigor NFR-6 demands of the Epic 1 evaluator.** FR-29's "consecutive successful Evaluation Periods, not consecutive days" is easy to get subtly wrong at Version boundaries; lean on `evaluate()`'s existing AD-5 version-boundary period-splitting rather than re-deriving period boundaries inside `StatsService`.
- **No new evaluation logic — only counting logic.** `StatsService` must not decide pass/fail itself; it only counts consecutive Success outcomes that `evaluate()` (via cache or direct fallback) already produced. This keeps the single-evaluator guarantee (AD-4) intact: two different streak computations for the same goal are impossible if both ultimately trace back to the same `evaluate()` calls.
- **Contract stability:** Story 3.1 established `StatsService`'s streak method signature so Dashboard and Goal Detail could call it before this story finished the algorithm. This story fills in the implementation behind that same signature — no caller-side changes should be needed beyond the Rolling-Window "no streak" branch (Task 3), which Story 3.1's Daily-only stub did not yet need to handle.
- **Rolling Window "no streak" is a first-class result, not an edge case to special-case per screen.** Both Dashboard (Story 3.1) and Goal Detail (Story 3.2) must handle it identically — if one screen was built assuming streak is always a number, fix it here.
- **UX-DR alignment:** UX-DR19 (voice/tone) still applies — "Streak: 5 weeks," a plain number with unit, never "🔥 5 week streak!". No new UX-DR is introduced by this story; it is a correctness-only story behind the `stat-card`/goal-row surfaces built in 3.1/3.2.
- **Testing standards (explicit, per the parent task's quality bar):** correctness of period-based (not day-based) streak counting for every non-Daily Evaluation Period type is the primary bar — Weekly is the example given in epics.md, but the same consecutive-period logic must hold for Biweekly/Monthly/Quarterly/Yearly/Custom (all built in Epic 1 Story 1.3/1.5). Paused-time exclusion (Epic 2 Story 2.2) must not be mistaken for a failed period. Cache-fallback correctness (a streak computed partly from cache and partly from a live `evaluate()` fallback for missing days) must produce the same answer as if the entire range had been live-evaluated.

**Streak continuity across a period-type change (confirmed):** when a `GoalVersion` change alters the Evaluation Period *type itself* (e.g., a goal edited from Weekly to Monthly mid-history), the streak resets — continuity breaks at that boundary, since "3 consecutive weeks" and "consecutive months" are non-comparable units and cannot be concatenated into one count. This is consistent with AD-5's "no cross-Version blending" and is confirmed product behavior, not an open interpretation.

### Project Structure Notes

- Modifies existing files only: `lib/domain/services/stats_service.dart` (Story 3.1), `lib/presentation/screens/dashboard_screen.dart` (Story 3.1), `lib/presentation/screens/goal_detail_screen.dart` (Story 3.2). No new files, no new Drift tables, no new components — this is a pure domain-logic completion story.
- No conflicts with the structural seed; all changes stay inside `lib/domain/services/` and the two existing presentation screens.

### References

- [Source: docs/epics.md#Story 3.3: Rule-Aware Streaks]
- [Source: docs/epics.md#Requirements Inventory] FR-29
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-8] StatsService sole streak/rollup computer
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-5] Version-boundary period splitting (no pro-rating) — reused for period walk-back
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4] Pure evaluator contract — StatsService counts evaluate() outputs, does not reimplement them
- [Source: docs/prd/3-glossary.md] Streak definition ("consecutive successful Evaluation Periods... Not applicable to Rolling Window Goals")
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Voice and Tone] plain-number streak copy convention
- [Source: docs/stories/3-1-dashboard-todays-goals-and-progress-rollups.md] Previous story: StatsService/CacheWriter introduced, streak method contract, Daily-only initial implementation
- [Source: docs/stories/3-2-goal-detail-screen-with-version-timeline.md] Previous story: stat-card grid, Goal Detail calls same StatsService method as Dashboard

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- A throwaway debug harness (`test/domain/services/_debug_streak_test.dart`, deleted before completion) traced a fixture bug: leaving the in-progress current week/month completely unlogged does not reliably resolve to `Pending` — `evaluate()`'s certain-failure math can already declare a certain `Fail` late in a period (e.g. the suite happened to run on a Sunday, the last day of the week). Fixed by having every period-based test fixture explicitly `Pause` the still-in-progress current period (same Evaluation Period type, `isPaused: true`), which the streak walk always skips regardless of what day/weekday the suite runs on.
- `flutter analyze` and `flutter test` (full suite, 250 tests) both clean after implementation.

### Completion Notes List

- Replaced `StatsService`'s Daily-only `currentStreak()`/`goalStats()` streak logic with a single period-aware forward walk (`_streakWalk`), producing current + longest streak in one pass (Subtask 2.1) over the goal's Evaluation Periods from `Goal.startDate` through today. Daily goals degenerate to the exact same code path with period-length = 1 day (Subtask 1.2) — verified against the pre-existing Daily-only tests, which pass unchanged.
- `_streakWalk` returns `null` for a Rolling Window goal (AC 3) and treats a mid-history switch into/out of Rolling Window as a boundaryless gap (skipped day-by-day, no streak concept applies).
- Added `_isFullyPausedOrUngoverned` so a period that is Paused (or not yet governed) for its entire span is skipped without asking `evaluate()` at all — `evaluate()`'s own FR-5 "zero eligible days ⇒ Fail" rule would otherwise misclassify a fully-Paused period as a failed one; a period that is only *partially* Paused is left to `evaluate()`'s own AD-5 rule-window aggregation unchanged (Subtask 4.5).
- Added `_clipToTypeWindow` so a period's query date never crosses into a later Version with a *different* Evaluation Period type — without this, asking `evaluate()` about (e.g.) a Weekly period whose raw calendar boundary extends past a Weekly→Monthly Version switch would silently evaluate the wrong period type. This also anchors the Subtask 1.4 continuity-break: `previousType` is compared per period and a type change resets `running` to 0.
- `GoalStats.currentStreak`/`longestStreak` are now `int?` (`null` = not applicable, Rolling Window only) — `goalStats()`'s pre-existing day-by-day completion-percentage loop is unchanged (still Daily-only-correct; Story 3.4 owns period-aware completion %, out of scope here).
- `dashboard_screen.dart` needed no changes at all: `GoalRow.streak` was already `int?` and already renders nothing when `null`, and the row's existing progress trailing already doubles as "current pace" (Subtask 3.1/3.2 — no local streak computation existed on either screen to remove).
- `goal_detail_screen.dart`'s `_StatCardRow` now branches on `null` and renders a new `_CurrentPaceCard` (`goal-detail-current-pace-card`) in place of the two streak cards for Rolling Window goals — a numeric current/target fraction for Counter goals (the common case), or a status word for Boolean.
- Regenerated `stats_providers.g.dart` via `dart run build_runner build` after widening `currentStreak`'s return type to `Future<int?>`.

### File List

- `lib/domain/services/stats_service.dart`
- `lib/presentation/providers/stats_providers.dart`
- `lib/presentation/providers/stats_providers.g.dart`
- `lib/presentation/screens/goal_detail_screen.dart`
- `test/domain/services/stats_service_test.dart`
- `test/presentation/streak_consistency_test.dart`

## Change Log

- 2026-08-30: Story implemented — `StatsService` streak computation replaced with a period-aware algorithm (FR-29): consecutive successful Evaluation Periods for non-Daily goals, `null` (no Streak stat) for Rolling Window goals. Goal Detail substitutes a "Current Pace" stat-card for Rolling Window goals; Dashboard needed no changes. Status set to `review`.
