---
baseline_commit: NO_VCS
---

# Story 3.2: Goal Detail Screen with Version Timeline

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to open a goal and see its schedule, target, streak, completion percentage, historical calendar, and a timeline of how its rules changed over time,
so that I understand not just where a goal stands but how it got there.

## Acceptance Criteria

1. **Given** any goal, **when** Panda taps into its Goal Detail screen, **then** it shows the goal's current schedule and target, current and longest Streak, completion percentage, a historical calendar, and edit/archive actions (FR-27)
2. **Given** a goal has been edited or paused/resumed (Epic 2), **when** Panda views its Version Timeline, **then** it shows the dated rule-change segments (e.g. "3x/week Jan 1–Mar 14, then 5x/week Mar 15–present") as a horizontal strip distinct from the historical calendar below it (FR-27 consequence, UX-DR17)
3. **Given** Panda taps a Version Timeline segment, **when** it opens, **then** that Version's rules are shown as plain text, not a raw diff (UX-DR17)
4. **And** if a goal is Archived, its Goal Detail still renders correctly from history (FR-2 consequence)

## Tasks / Subtasks

- [x] Task 1: Domain read model for Goal Detail (AC: 1, 2, 4)
  - [x] Subtask 1.1: Add a `StatsService` method (or extend Story 3.1's rollup methods) returning a single goal's current streak, longest streak, and completion percentage together — Goal Detail must call this, not compute any of the three itself (AD-8)
  - [x] Subtask 1.2: Add a repository read for a goal's full `GoalVersion` history ordered by `versionStartDate`, to drive the Version Timeline — this is a pure data read, no new write path (repositories already exist from Epic 1/2, AD-6 governs writes only)
  - [x] Subtask 1.3: Confirm the existing goal repository read works unchanged for an Archived goal (state does not gate whether its Versions/Logs can be read) — verify no query filters out Archived goals by accident when reached via Goal Detail navigation (FR-2 consequence)

- [x] Task 2: Historical calendar data source (AC: 1)
  - [x] Subtask 2.1: Implement the Goal Detail historical calendar's data source reading `DayStatus` via `StatsService`/the cache repository (built in Story 3.1), falling back to `evaluate()` for any uncached date — see Dev Notes for why this is a cache-reading surface, distinct from the live Day/Week/Month calendar (FR-21–23)
  - [x] Subtask 2.2: Render the historical calendar reusing the existing `status-cell` component (Epic 1, UX-DR6) at whatever grid density fits Goal Detail — do not build a second calendar-cell component

- [x] Task 3: `stat-card` component and Goal Detail layout (AC: 1)
  - [x] Subtask 3.1: Build the `stat-card` component (UX-DR8) in `lib/presentation/components/stat_card.dart`: numeric-heavy, `numeric` tabular-figure typography, no icons, using `card-surface` tokens (background/border/radius per DESIGN.md components table)
  - [x] Subtask 3.2: **Extend** `lib/presentation/screens/goal_detail_screen.dart` — this file already exists from Epic 2 (Story 2.1 created it with a schedule/target summary and Edit action; Story 2.2 added Pause/Resume; Story 2.3 added Archived-state handling). Do not recreate it. Add: a row of `stat-card`s for current Streak / longest Streak / completion %, and the historical calendar, positioned alongside the existing schedule/target summary and existing Edit/Pause-Resume/Archive action buttons (already `button-secondary` per UX-DR10) — preserve all of Epic 2's existing wiring and Archived-state conditionals unchanged; this story only adds new sections to the layout.
  - [x] Subtask 3.3: This story establishes the `stat-card` grid pattern that Story 3.4 extends with additional cards (success/failure counts, Cheat Day count, average/total value) on the same screen — do not build a separate stats layout; Story 3.4 adds cards to this same component/grid

- [x] Task 4: Version Timeline component (AC: 2, 3)
  - [x] Subtask 4.1: Build `lib/presentation/components/version_timeline.dart`: a horizontal, dated-segment strip, visually distinct from (positioned separately from, not merged into) the historical calendar per UX-DR17 — one segment per `GoalVersion`, labeled with its effective date range
  - [x] Subtask 4.2: Implement tap-on-segment behavior opening a sheet/panel showing that Version's rules restated as plain text (e.g. "At least 3 times a week, workdays only, effective Mar 15") — mirror the Review-step plain-language sentence pattern established in Epic 1 Story 1.9's wizard (UX-DR15), not a raw field-by-field diff
  - [x] Subtask 4.3: For a goal with only one Version (never edited/paused), render the Version Timeline as a single full-width segment — do not hide the component entirely, so its presence is consistent across all goals

- [x] Task 5: Archived-goal rendering (AC: 4)
  - [x] Subtask 5.1: Story 2.3 already implements the Archived-state conditional on this screen (Edit disabled/hidden, no re-activation flow). Verify it still functions correctly once this story adds the `stat-card` row/historical calendar/Version Timeline above/around it — an Archived goal must remain reachable from historical/stats surfaces and render every new section (stats, calendar, timeline) from its full history, not just the pre-existing summary. Do not modify Story 2.3's Archived-state logic itself unless this story's layout changes genuinely require it.

- [x] Task 6: Testing (AC: 1-4)
  - [x] Subtask 6.1: Widget tests for `GoalDetailScreen`: renders schedule/target, three initial `stat-card`s, historical calendar, Version Timeline, edit/archive actions
  - [x] Subtask 6.2: Widget tests for `VersionTimeline`: multiple segments render in date order; tapping a segment shows that Version's rules as plain text; single-Version goal renders one segment
  - [x] Subtask 6.3: Test Goal Detail renders correctly (no crash, all sections populate from history) for an Archived goal fixture with multiple past Versions and logs
  - [x] Subtask 6.4: Unit test confirming Goal Detail's streak/longest-streak/completion % values come from the same `StatsService` call the Dashboard (Story 3.1) uses for the same goal, and are identical — no divergent computation

## Dev Notes

- **This story introduces the `stat-card` component (UX-DR8).** DESIGN.md's Components section defines `stat-card` as used "on the Goal Detail screen for Streak, longest Streak, and completion percentage" — that is exactly this story's AC1 requirement, so `stat-card` is built here, not deferred. Story 3.4 ("Full Statistics Panel") reuses this exact component to add more cards (success/failure counts, Cheat Day count, average/total value) to the same Goal Detail screen — it must not introduce a second stat-display pattern. Treat `stat_card.dart` as a shared, extensible component from the moment it's created.
- **Historical calendar is a cache-reading surface, not the live calendar.** AD-7's rule "the live calendar never reads the cache — always calls `evaluate()` fresh" is explicitly scoped to FR-21–23 (the Day/Week/Month tab-bar calendar). Goal Detail's historical calendar (FR-27) is a distinct, per-goal historical review surface that can span a goal's entire lifetime — exactly the "long-range stats" case AD-8 describes for `StatsService`'s cache-with-fallback pattern. This story therefore routes the historical calendar through `StatsService`/the cache repository (same as Dashboard rollups), falling back to `evaluate()` only for uncached dates. This is a documented interpretation, not a verbatim architecture citation — flagged as an open question below for confirmation, but implement it this way so the story is actionable now.
- **No independent streak/completion-% computation.** Per AD-8, Goal Detail must call the identical `StatsService` method Story 3.1's Dashboard uses for a given goal — same signature, same result. Do not add a second streak algorithm "for Goal Detail's more detailed view." Story 3.3 will still be the story that finishes the rule-aware algorithm's correctness for non-Daily/Rolling-Window goals; this story only needs to call the (already-Daily-correct) service.
- **Version Timeline (UX-DR17) is a read-only projection of `GoalVersion` history** already written by `GoalService` in Epic 2 (AD-6) — this story adds no new write path. Reuse the plain-language rule-restatement pattern from the wizard's Review step (Epic 1 Story 1.9, UX-DR15) for consistency of voice (UX-DR19: no exclamation points, factual tone) when rendering a tapped segment's rules.
- **UX-DR requirements this story delivers:** UX-DR8 (`stat-card`), UX-DR17 (Version Timeline as a distinct horizontal strip, plain-text segment detail), UX-DR6 (reused `status-cell` for the historical calendar), UX-DR10 (button-secondary for Edit/Archive, since neither is the screen's single primary forward action).
- **Anti-duplication guidance:** reuse `status-cell` (Epic 1) for the historical calendar grid — do not build a new calendar-cell renderer. Reuse `StatsService` for every numeric stat — do not compute streak/completion % locally. Reuse the wizard's plain-language rule-sentence formatting logic (Epic 1 Story 1.9) for Version Timeline segment detail rather than writing a second rule-to-text formatter — extract it to a shared helper if it isn't already.
- **Testing standards:** verify Goal Detail and Dashboard produce identical streak/completion-% values for the same goal (proves AD-8's single-computer guarantee). Verify Archived-goal rendering explicitly — this is a common regression point since many queries default to filtering out Archived goals (Epic 2 Story 2.3 established that Archived goals must remain visible on historical/stats surfaces).

### Project Structure Notes

- New presentation files: `lib/presentation/components/stat_card.dart`, `lib/presentation/components/version_timeline.dart` — matches structural seed's `lib/presentation/components`. `lib/presentation/screens/goal_detail_screen.dart` is **not** a new file — it's the existing screen from Epic 2 Stories 2.1/2.2/2.3, extended here with the sections above.
- Reuses existing domain/data from Epic 1 (`evaluate()`, `status-cell`), Epic 2 (`GoalVersion` history via `GoalService`/repositories, and the `goal_detail_screen.dart` file itself with its Edit/Pause-Resume/Archive wiring), and Story 3.1 (`StatsService`, `CacheWriter`-populated cache).
- No new Drift tables required — this story is read-only against existing schema (`GOAL`, `GOAL_VERSION`, `GOAL_LOG`, plus the `status_cache` table from Story 3.1).
- No conflicts with structural seed; layer boundaries preserved (presentation depends on domain only, never imports Drift directly — AD-1).

### References

- [Source: docs/epics.md#Story 3.2: Goal Detail Screen with Version Timeline]
- [Source: docs/epics.md#Requirements Inventory] FR-27, FR-2
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-7] Status cache scope (live calendar = FR-21–23 only)
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-8] StatsService sole streak/rollup computer
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6] GoalService/GoalVersion history (read-only reuse here)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components] stat-card, status-cell, button-secondary
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Component Patterns] Version Timeline description
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Information Architecture] Goal Detail IA entry
- [Source: docs/stories/3-1-dashboard-todays-goals-and-progress-rollups.md] Previous story: `StatsService`/`CacheWriter` introduced, streak method contract established, goal-row/status-cell reuse pattern

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

None — no failing test runs required debugging beyond one self-corrected domain-logic mismatch, noted in Completion Notes.

### Completion Notes List

- Added `StatsService.goalStats(goalId)` (bundled current/longest streak + completion %) and `StatsService.historicalStatuses(goalId)`, plus their `goalStatsProvider`/`historicalStatusesProvider` Riverpod wrappers, following the exact `currentStreak`/`currentStreakProvider` pattern from Story 3.1. `currentStreak` was refactored (behavior-preserving) to share a new `_lastResolvedDay` helper with `goalStats`, rather than duplicating the "today unless still Pending/Empty" cursor rule.
- **Correctness finding during TDD (Subtask 1.1):** `evaluate()`'s Boolean-Daily branch returns `Pending` — never `Fail` — for an eligible day with no log at all, forever (only an explicit `completed: false` log ever produces `Fail`); there is no midnight-rollover or cache-rebuild path that auto-converts an unlogged past day to `Fail`. `currentStreak`'s existing backward walk already treats `Pending` as a stop signal identical to `Fail`. My first `goalStats` draft grouped `Pending` with `Empty` (skip without breaking the run) instead, which a unit test caught (expected longest streak of 7, got 9 — two separate streaks had silently merged across an unlogged gap). Fixed by grouping `Pending` with `Fail` for streak-breaking purposes (but still excluded from the completion-percentage denominator, since it isn't "resolved"), matching `currentStreak`'s own precedent. Flagging this here since it's a real, non-obvious domain-evaluator semantic future stories should know about, not just a test-fixture mistake.
- Built `stat_card.dart` (UX-DR8) and `version_timeline.dart` (UX-DR17) as new shared components, and extended `goal_detail_screen.dart` (unchanged: Epic 2's summary text, Edit/Pause-Resume/Archive buttons and their wiring) with a `stat-card` row, the Version Timeline, and a `status-cell`-based historical calendar (wrapped the body in a `SingleChildScrollView` since the screen now has materially more content).
- Extracted the wizard-state-from-version builder (previously a private `_wizardStateFor` inside `goal_detail_screen.dart`) into a new public `wizardStateForVersion` in `review_sentence.dart`, per the story's own Dev Notes ("extract it to a shared helper if it isn't already") — now reused by both the current-Version summary and the Version Timeline's tapped-segment detail sheet, so there is exactly one plain-language rule-sentence builder in the app.
- **Scope note on Subtask 5.1:** its premise — "Story 2.3 already implements the Archived-state conditional on this screen (Edit disabled/hidden, no re-activation flow)" — does not hold against the current codebase: `goal_detail_screen.dart` has no Archived-state conditional at all (Edit/Pause-Resume/Archive all render unconditionally regardless of `goal.archived`), even though sprint-status.yaml also lists 2-3-archive-expire-and-delete-archive as not yet done. Since this story's actual AC 4 only requires that Goal Detail "still renders correctly from history" for an Archived goal — not that Edit be hidden — I left that gap alone rather than building Story 2.3's own scope preemptively, and verified AC 4 directly instead (Subtask 6.3's test: an Archived goal with 2 Versions and a log renders every new section with no crash). Whoever picks up Story 2.3 will still need to add the Edit-hiding conditional.
- All new/changed code passes `flutter analyze` (no new issues beyond pre-existing `prefer_initializing_formals` infos) and the full test suite (243 tests, 0 failures).

### File List

- `lib/domain/services/stats_service.dart` (modified — added `GoalStats`, `goalStats()`, `historicalStatuses()`, `_lastResolvedDay()`; refactored `currentStreak()` to use `_lastResolvedDay()`)
- `lib/presentation/providers/stats_providers.dart` (modified — added `goalStatsProvider`, `historicalStatusesProvider`)
- `lib/presentation/providers/stats_providers.g.dart` (generated)
- `lib/presentation/components/wizard/review_sentence.dart` (modified — added public `wizardStateForVersion`)
- `lib/presentation/components/stat_card.dart` (new)
- `lib/presentation/components/version_timeline.dart` (new)
- `lib/presentation/screens/goal_detail_screen.dart` (modified — added stat-card row, Version Timeline, historical calendar; wrapped body in `SingleChildScrollView`; switched to shared `wizardStateForVersion`)
- `test/domain/services/stats_service_test.dart` (modified — added `goalStats`/`historicalStatuses` coverage)
- `test/presentation/version_timeline_test.dart` (new)
- `test/presentation/goal_detail_screen_test.dart` (modified — added stat-card/timeline/calendar rendering test and Archived-multi-Version fixture test)

## Change Log

- 2026-08-30: Story implemented — Goal Detail extended with the Streak/longest-Streak/completion % stat-card row, the Version Timeline, and the historical calendar; `StatsService` extended with `goalStats`/`historicalStatuses`. Status set to `review`.
