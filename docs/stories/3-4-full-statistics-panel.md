---
baseline_commit: NO_VCS
---

# Story 3.4: Full Statistics Panel

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want a goal's detail screen to show its full statistical history — success/failure counts, cheat days used, average and total values, and completion percentage that fairly excludes paused time,
so that I can see the whole picture, not just the current streak.

## Acceptance Criteria

1. **Given** any goal, **when** Panda views its stats, **then** they include current Streak, longest Streak, completion percentage (daily/weekly/monthly), counts of successful and failed periods, Cheat Day count, and, for Counter goals, average and total value (FR-28)
2. **Given** a goal was Paused for part of its history, **when** completion percentage is computed, **then** the Paused date range is excluded from the calculation, consistent with Epic 2's "Paused produces no Eligible Days" (FR-28 consequence)
3. **Given** the `stat-card` component (UX-DR8), **when** any of these numbers render, **then** they use tabular figures with no icons (UX-DR8)
4. **And** the complete Goal history is available when Panda scrolls Goal Detail, not truncated to a recent window (FR-28)

## Tasks / Subtasks

- [x] Task 1: Extend `StatsService` with the remaining FR-28 statistics (AC: 1, 2)
  - [x] Subtask 1.1: Add methods to `lib/domain/services/stats_service.dart` for: completion percentage at daily/weekly/monthly granularity, successful-period count, failed-period count, Cheat Day count (reading `CheatDay` records via the existing Epic 2 repository), and — for Counter goals only — average and total logged value across history
  - [x] Subtask 1.2: Completion percentage must exclude any date range covered by a Paused `GoalVersion` segment (Epic 2 Story 2.2 established "Paused produces no Eligible Days" — a Paused range contributes zero to both the numerator and denominator of the percentage, not zero-to-numerator-only, since it was never an Eligible Day at all)
  - [x] Subtask 1.3: Successful/failed period counts must use the same period-boundary logic as Story 3.3's streak walk (AD-5 version-boundary splitting) — reuse that period-iteration helper rather than writing a second period-walking loop; a period counts as failed only once `evaluate()` (or its cached result) actually returned a Fail/Red outcome, never merely "not yet successful" (Pending periods are excluded from both counts until they resolve)
  - [x] Subtask 1.4: Average/total value for Counter goals sums/averages the `GoalLog.value` field across all logged days in the goal's history (excluding Paused ranges per Subtask 1.2's same exclusion) — for Boolean goals, these two stats are not applicable and must not render (see Task 2)
  - [x] Subtask 1.5: All new methods follow Story 3.1's established cache-first-with-`evaluate()`-fallback pattern (AD-8) — no exceptions for the "harder" aggregate stats; a corrupted/missing cache must still produce correct results via fallback

- [x] Task 2: Extend the Goal Detail `stat-card` grid (AC: 1, 3)
  - [x] Subtask 2.1: Add additional `stat-card` instances (built in Story 3.2, `lib/presentation/components/stat_card.dart`) to `goal_detail_screen.dart` for: completion % (with a period-granularity selector or a fixed default — see Dev Notes), successful-period count, failed-period count, Cheat Day count
  - [x] Subtask 2.2: For Counter goals, add average-value and total-value `stat-card`s; for Boolean goals, omit these two cards entirely rather than rendering a zero or N/A card (Boolean goals have no numeric value to average)
  - [x] Subtask 2.3: Every new card uses the same `stat-card` component instance/styling as Story 3.2's original three cards — tabular figures (`numeric` typography token), no icons, `card-surface` tokens — do not introduce a visually different stat presentation for the "new" stats

- [x] Task 3: Ensure full, untruncated history (AC: 4)
  - [x] Subtask 3.1: Verify the historical calendar and any list/scroll view backing these stats is not paginated or windowed to "recent" data only — the underlying repository query for a goal's full `GoalLog`/`GoalVersion` history must not apply a default date-range limit
  - [x] Subtask 3.2: If performance requires lazy-loading the historical calendar's visual rendering (e.g. virtualized scroll for a multi-year goal), the underlying stats computation (counts, percentages, averages) must still run over the complete history regardless of what's currently rendered on screen — the AC is about data completeness, not about un-virtualized rendering

- [x] Task 4: Testing (AC: 1-4)
  - [x] Subtask 4.1: Unit tests for each new `StatsService` stat: successful/failed period counts on a goal with a mix of Success/Fail/Pending periods (Pending must not be counted either way until resolved); Cheat Day count against a fixture with known Cheat Day records (Epic 2 Story 2.4); average/total value on a Counter-goal fixture with known logged values
  - [x] Subtask 4.2: Unit test: completion percentage on a goal with a Paused segment mid-history — assert the Paused range's days are excluded from both numerator and denominator, not just subtracted from the numerator
  - [x] Subtask 4.3: Unit test: a Boolean goal's average/total value methods either are not called by the UI or return an explicit not-applicable result — assert `GoalDetailScreen` does not render average/total cards for a Boolean-goal fixture
  - [x] Subtask 4.4: Widget test: a goal fixture with several years of history renders all stats correctly and the screen scrolls to reveal full history without truncation
  - [x] Subtask 4.5: Widget test: all `stat-card`s (original three from 3.2 plus this story's additions) render with consistent styling (tabular figures, no icon widgets present in the tree)

## Dev Notes

- **This story extends, not replaces, Story 3.2's `stat-card` grid.** The `stat-card` component itself was built in Story 3.2 for Streak/longest Streak/completion %; this story adds more cards to the same Goal Detail screen using the identical component. Do not create a second "full stats panel" screen or a different visual treatment — FR-27 (Goal Detail) and FR-28 (Statistics) both describe one screen's content, split across two stories only for delivery sequencing.
- **Completion percentage granularity (daily/weekly/monthly):** FR-28 lists all three granularities as available stats. Neither epics.md nor the architecture spine specifies whether the UI shows all three simultaneously, a toggle, or a single default — implement a sensible default (e.g. show the granularity matching the goal's own Evaluation Period, since that's the period completion already means for the goal) and treat the multi-granularity display as an open question if a specific UI treatment is later required; do not block delivery on this ambiguity.
- **Paused-range exclusion is the trickiest correctness requirement in this story.** Reuse the exact same "Paused produces no Eligible Days" logic `evaluate()` already implements (Epic 2 Story 2.2) — do not reimplement pause-range detection in `StatsService`; ask the evaluator/cache what days were actually Eligible, and only compute percentages over that Eligible-day set.
- **Reuse Story 3.3's period-walking logic for successful/failed counts** — that story already had to solve "walk backward through Version-bounded periods, evaluating each one." Extract that as a shared internal helper in `StatsService` if it isn't already, rather than writing a second, possibly-diverging period iterator here.
- **UX-DR8 (`stat-card`) is fully delivered by the combination of Story 3.2 + this story** — this story's AC3 is the final confirmation that every stat number in the app (not just the original three) follows the tabular-figure, no-icon rule.
- **Anti-duplication guidance:** no new component is introduced in this story — everything renders through Story 3.2's `stat_card.dart`. No new Drift tables or repositories — all new stats are aggregate reads over existing `GOAL_LOG` / `CHEAT_DAY` / `GOAL_VERSION` tables (established Epic 1/Epic 2 schema) plus the `status_cache` table (Story 3.1).
- **Testing standards:** paused-time exclusion from completion % is the single highest-value test in this story (explicitly called out by the parent epic's quality bar) — write it as an unambiguous fixture-based unit test, not just an assertion of "doesn't crash." Verify Pending periods are excluded from both success and failure counts (a common off-by-one class of bug: don't let an in-progress period silently count as a failure).

### Project Structure Notes

- Modifies existing files: `lib/domain/services/stats_service.dart` (Story 3.1/3.3), `lib/presentation/screens/goal_detail_screen.dart` (Story 3.2). Reuses `lib/presentation/components/stat_card.dart` (Story 3.2) without modification to its public API (only more instances of it).
- No new Drift tables; reads existing `GOAL_LOG`, `CHEAT_DAY`, `GOAL_VERSION` tables (Epic 1/2 schema) and the `status_cache` table (Story 3.1).
- No conflicts with structural seed.

### References

- [Source: docs/epics.md#Story 3.4: Full Statistics Panel]
- [Source: docs/epics.md#Requirements Inventory] FR-28
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-8] StatsService sole rollup computer
- [Source: docs/prd/4-features.md#fr-28-statistics] Completion percentage exclusion of Paused periods
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components] stat-card definition (numeric-heavy, no icons)
- [Source: docs/stories/3-2-goal-detail-screen-with-version-timeline.md] Previous story: stat-card component and initial 3-card grid established
- [Source: docs/stories/3-3-rule-aware-streaks.md] Previous story: period-walking logic for successful/failed period counting, reused here

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5

### Debug Log References

### Completion Notes List

Ultimate context engine analysis completed - comprehensive developer guide created

- Extended `StatsService.goalStats()` and its shared period walk (`_streakWalk`, renamed in spirit but same identifier — now returns `successCount`/`failCount` alongside `current`/`longest` from one pass) to add: successful/failed period counts, Cheat Day count, and Counter-goal average/total value. `_streakWalk` now takes `versions` as a parameter (fetched once by each caller) instead of re-querying internally, avoiding a duplicate repository call between `currentStreak()` and `goalStats()`.
- `completionPercentage` is now derived from the same `successCount`/`failCount` the period walk produces for every non-Rolling-Window goal (`successCount / (successCount + failCount) * 100`), replacing the old always-day-based computation — this automatically inherits the period walk's existing Paused-period exclusion (`_isFullyPausedOrUngoverned`, from Story 3.3) rather than needing a second exclusion mechanism. Rolling Window goals (which return `null` from the period walk) keep a day-based fallback (`_dayBasedCompletionPercentage`), now also excluding Paused days via the existing `isPausedOn` helper (`paused_range_helper.dart`) rather than reimplementing pause-range detection, per Dev Notes guidance.
- Average/total value sum/average `GoalLog.value` across the goal's history, excluding any date `isPausedOn` reports as Paused; `null` (not 0) when the goal's latest `GoalVersion.trackingType` isn't Counter, so `GoalDetailScreen` can omit the cards entirely for a Boolean goal.
- `GoalDetailScreen`'s `_StatCardRow` changed from a fixed 3-card `Row` to a `Wrap`-based 2-column grid (`LayoutBuilder` computing card width) since the card count now varies by goal shape (Rolling Window vs. period-based, Counter vs. Boolean) — every card still renders through the unmodified `StatCard` widget (Story 3.2), so styling stays identical.
- Task 3 (untruncated history) required no code changes: `historicalStatuses()` and the historical-calendar `Wrap` already walk/render the complete `[Goal.startDate, today]` range with no pagination; verified via a new 800-day-history widget test.
- Updated a pre-existing Story 3.2 widget test (`goal_detail_screen_test.dart`) whose `find.text('3')` assertion became ambiguous once the new Successful Periods card could also read "3" for the same fixture — scoped it to each card's own `Key` instead of a bare text count.

### File List

- lib/domain/services/stats_service.dart
- lib/presentation/screens/goal_detail_screen.dart
- test/domain/services/stats_service_test.dart
- test/presentation/goal_detail_screen_test.dart

## Change Log

- 2026-08-30: Story implemented — `StatsService` extended with successful/failed period counts, Cheat Day count, and Counter-goal average/total value (FR-28), all sharing Story 3.3's period walk so completion percentage now excludes Paused periods for every goal shape (AC 2). Goal Detail's `stat-card` grid extended to a `Wrap` layout carrying the new cards through the unmodified `StatCard` component (AC 1, AC 3). Full-history rendering verified unchanged (AC 4). Status set to `review`.
