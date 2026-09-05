---
baseline_commit: NO_VCS
---

# Story 3.5: Goal Filtering by Category

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to filter the calendar to all goals, a single goal, or a category of goals,
so that I can focus on one part of my life without the rest cluttering the view.

## Acceptance Criteria

1. **Given** multiple goals exist, some assigned to categories, **when** Panda applies a filter, **then** the calendar can show all Goals, a single Goal, or an entire category (FR-25)
2. **Given** a goal is created or edited, **when** Panda assigns it a category, **then** that assignment persists and is usable as a real filter, not a schema placeholder (FR-25, confirmed MVP scope)
3. **And** when no filter is applied, the calendar defaults to showing all Goals (FR-25 default behavior)
4. **And** the Goals list orders goals by Evaluation Period frequency — Daily, Weekly, Biweekly, Monthly, Quarterly, Yearly, then Rolling Window and Custom last — alphabetical by name within each group; this is a computed sort, not a stored `Priority` field, and resolves the goal-list ordering question Architecture and UX both left open

## Tasks / Subtasks

- [x] Task 1: Category assignment in creation and edit flows (AC: 2)
  - [x] Subtask 1.1: The `GOAL.category` column already exists in the Drift schema (established Epic 1 Story 1.1 per the architecture ER diagram) but is not yet surfaced in any UI — add a category field/selector to the guided creation wizard (Epic 1 Story 1.9, `lib/presentation/screens/` wizard steps) as an optional field, without disrupting the existing 7-step order (name → tracking type → schedule → target → dates → reminders → review) mandated by FR-6/UX-DR15; the simplest compliant placement is on the name step alongside the goal name, since category is goal-identity metadata, not a scheduling/target axis
  - [x] Subtask 1.2: Add the same category field to the goal-edit flow (Epic 2 Story 2.1) — **note:** changing a goal's category is metadata-only and must NOT create a new `GoalVersion` (AD-6 only mandates versioning for rule/schedule/target/lifecycle changes, not for the `category`/`name` fields on `GOAL` itself, which live outside `GOAL_VERSION` per the architecture ER diagram); route this write through `GoalService` as a direct `GOAL` row update, not a version-creating edit path — confirm this distinction explicitly since it's easy to conflate "editing a goal" (versioned) with "editing the Goal's category" (not versioned)
  - [x] Subtask 1.3: Support free-text or simple list-managed categories (e.g. a lightweight "manage categories" affordance in Settings) — epics.md/architecture do not specify a separate category-management screen; the minimum compliant implementation is a text field or a simple picker sourced from categories already used by existing goals, plus the ability to type a new one

- [x] Task 2: Filter query support (AC: 1, 3)
  - [x] Subtask 2.1: Add a repository query parameter (or a dedicated method) supporting "all goals" / "single goal by id" / "goals in category X" scoping, backing both the Calendar (Day/Week/Month, Epic 1) and any goal-scoped stats reads
  - [x] Subtask 2.2: Default state (no filter applied) must resolve to "all Goals" — verify this is the actual default on cold start and after clearing a filter, not merely the visual default with a lingering stale filter underneath
  - [x] Subtask 2.3: The live calendar (FR-21–23) continues to call `evaluate()` fresh per goal in the filtered set — filtering changes *which* goals are evaluated/displayed, never *how* they're evaluated, and must not be implemented by pre-filtering against the cache (AD-7's "live calendar never reads cache" still applies; the filter is applied to the list of goals passed into the existing live-evaluation loop, not as a cache lookup)

- [x] Task 3: Filter UI (AC: 1, 3)
  - [x] Subtask 3.1: Add a filter control to the Calendar surface (Day/Week/Month tab, Epic 1 Story 1.10) offering "All," each individual Goal, and each category — placement/style should reuse existing `button-secondary`/selector patterns, not introduce a new interactive primitive beyond the two established button tiers (UX-DR10)
  - [x] Subtask 3.2: Persist the last-applied filter across navigation within a session (not necessarily across app restarts, since this isn't specified) so switching tabs and returning doesn't silently reset to "All" — reasonable UX default, not an explicit AC, implement simply

- [x] Task 4: Goals list computed sort order (AC: 4)
  - [x] Subtask 4.1: On the Goals tab (scaffolded Epic 1 Story 1.1, per EXPERIENCE.md's IA table as a top-level tab surface), implement the sort: group by Evaluation Period type in the fixed order Daily, Weekly, Biweekly, Monthly, Quarterly, Yearly, Rolling Window, Custom (Rolling Window and Custom both sort last, per AC4's exact wording — treat them as a combined final group, alphabetical by name within it, unless further ordering between those two is later specified)
  - [x] Subtask 4.2: Within each Evaluation Period group, sort alphabetically by goal name (case-insensitive)
  - [x] Subtask 4.3: Implement as a pure sort/comparator function over already-loaded goal data — no stored `Priority`/order field is written anywhere (explicitly ruled out by AC4); this is a presentation-layer computed sort, not a domain/data concern
  - [x] Subtask 4.4: A goal's current Evaluation Period type (for sort-grouping purposes) is read from its current/active `GoalVersion`, consistent with how every other "current schedule" read works (Story 3.2's Goal Detail summary) — a goal that changed Evaluation Period type via a mid-history edit sorts by its *current* type, not any historical one

- [x] Task 5: Testing (AC: 1-4)
  - [x] Subtask 5.1: Unit test: category assignment persists through `GoalService` and does not create a spurious `GoalVersion` row
  - [x] Subtask 5.2: Unit test: filter query returns correct goal sets for "all," "single goal," and "category" scopes, including a goal with no category assigned (must appear under "all," never under any category filter)
  - [x] Subtask 5.3: Unit test: default (unset) filter state resolves to all Goals
  - [x] Subtask 5.4: Unit test: Goals-list comparator produces the exact documented group order (Daily…Yearly, then Rolling Window/Custom last) with correct alphabetical sub-ordering, including a mixed fixture set covering every Evaluation Period type
  - [x] Subtask 5.5: Widget test: applying a category filter on the Calendar updates the displayed goal set without altering any individual goal's displayed status (i.e., filtering doesn't accidentally trigger a different evaluation path)

## Dev Notes

- **This story is the first to surface the `category` field that already exists in the Drift schema** (per the architecture ER diagram's `GOAL.category` column, established Epic 1 Story 1.1) — there is no new Drift migration needed for the column itself, only for wiring it into the creation/edit UI and query layer. Do not add a second category column or a separate categories table unless a "manage categories" list needs its own lookup table for consistency of spelling/casing (a reasonable enhancement, but not mandated by epics.md/architecture — keep it minimal: e.g. derive the available category list from distinct values already in use).
- **Category is goal metadata, not a versioned rule.** AD-6 mandates `GoalVersion` creation only for edits to target/eligible-days/evaluation-period/lifecycle state — the `category` field lives on the `GOAL` row itself (per the ER diagram), not on `GOAL_VERSION`, so changing it must be a direct metadata update through `GoalService`, never a version-creating edit. Getting this wrong (accidentally versioning a category change) would pollute the Version Timeline (Story 3.2) with meaningless segments that don't represent a rule change — flagged explicitly because it's an easy mistake to make by pattern-matching on "any goal edit creates a Version."
- **Filtering does not touch AD-7's cache/live-evaluation split.** The Calendar (FR-21–23) still always calls `evaluate()` fresh for whatever goals are in the filtered set — a filter is a change to the *input list* of goals evaluated, never a switch to reading cached/precomputed data for the filtered view. Do not implement the category filter by querying the `status_cache` table (Story 3.1) directly for the live calendar surface.
- **Goals-list sort order resolves an explicitly-flagged open item.** Both UX and Architecture left goal-list ordering unresolved (no `Priority` field exists or is planned — architecture's Deferred section says this stays open unless a story needs it). This story is that story: implement the computed sort exactly as AC4 specifies, and do not introduce a `Priority` field or any other stored ordering mechanism — that would contradict AC4's explicit "computed sort, not a stored field" framing.
- **UX-DR alignment:** no new UX-DR is introduced by this story. Filter control UI should reuse the existing two-tier button system (UX-DR10: `button-primary`/`button-secondary`, no tertiary/ghost tier) — likely a `button-secondary`-styled selector/chip row, not a new interactive component class.
- **Anti-duplication guidance:** reuse the existing Calendar screen (Epic 1 Story 1.10) and Goals-list screen (scaffolded Epic 1 Story 1.1) — this story adds a filter control and a sort comparator to existing screens, it does not rebuild either screen. Reuse existing repository read methods, extended with a scoping parameter, rather than writing parallel "filtered" versions of every query.
- **Testing standards:** verify a goal with no category behaves correctly under "all" and is correctly excluded from every category-specific filter (a common edge case: null/empty category must not silently match every filter or crash the query). Verify the sort comparator against the full period-type list from Epic 1 Story 1.3 (Daily, Weekly, Biweekly, Monthly, Quarterly, Yearly, Rolling Window, Custom) — not just Daily/Weekly, since this story is the first to require sorting across every type built in that earlier story.

### Project Structure Notes

- Modifies existing files: creation wizard steps (Epic 1 Story 1.9), goal-edit flow (Epic 2 Story 2.1), Calendar screens (Epic 1 Story 1.10), Goals-list screen (Epic 1 Story 1.1 scaffold). Extends existing repository interfaces/implementations with filter-scoping parameters.
- No new Drift tables required for the `category` column itself (already present per Epic 1's schema); an optional lightweight categories lookup is a judgment call, not mandated.
- No conflicts with structural seed; all changes stay within existing `lib/domain`, `lib/data/repositories`, `lib/presentation` locations.

### References

- [Source: docs/epics.md#Story 3.5: Goal Filtering by Category]
- [Source: docs/epics.md#Requirements Inventory] FR-25
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Core-entity relationships] `GOAL.category` column already in schema
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6] GoalService as sole writer; category is non-versioned metadata
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-7] Cache/live-evaluation split preserved under filtering
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Deferred] Priority field left explicitly open; resolved here via computed sort per AC4
- [Source: docs/prd/4-features.md#fr-25-goal-filtering]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Information Architecture] Goals tab and Calendar tab surfaces
- [Source: docs/stories/3-1-dashboard-todays-goals-and-progress-rollups.md] Cache/live split established
- [Source: docs/stories/3-2-goal-detail-screen-with-version-timeline.md] Version Timeline — category changes must not appear here

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5

### Debug Log References

### Completion Notes List

Ultimate context engine analysis completed - comprehensive developer guide created

- **Task 1 (category assignment):** `Goal.copyWith` gained a `clearCategory` flag (mirroring the wizard's existing `clear*` pattern) since the prior implementation's `category ?? this.category` could never null out an assigned category. `GoalService.updateGoalCategory` is the new direct, non-versioned `GOAL` metadata write; `ReviewStep._saveEdit` calls it before `editGoalVersion` so the category persists independent of whether the rule edit succeeds or is rejected as `versionLocked`. The category field/suggestion-chip picker lives on the wizard's `NameStep`, sourced from `distinctCategories(allGoalsProvider)` — no separate categories table or Settings screen, per Dev Notes' "keep it minimal."
- **Task 2 (filter query support):** `domain/services/goal_filter.dart` adds a pure `GoalFilter` sealed type (`all`/`single`/`category`) and `filterGoals`/`distinctCategories` functions — no new repository method, since goals are already fully loaded via `watchAllGoals()`'s reactive stream and filtering is a computed scoping over that list (consistent with AD-4's "computed, not stored" spirit already established for the Task 4 sort). `filteredGoalsProvider` composes `allGoalsProvider` with the new `selectedGoalFilterProvider`, and the Day/Week/Month calendar screens now pass its filtered list into their existing `evaluate()` loops instead of `allGoalsProvider`'s raw list — the loading/error `AsyncValue` states pass straight through unchanged, and each screen still uses `allGoalsProvider` separately to distinguish "no goals at all" (empty state) from "no goals match this filter."
- **Task 3 (filter UI):** `GoalFilterBar` (a horizontal chip row, `button-secondary`-styled with an accent-filled selected state) is mounted above the goal list/grid on Day View, Week View, and Month View, all sharing one `keepAlive` `selectedGoalFilterProvider` so the selection persists across navigation between the three calendar screens within a session (Subtask 3.2) without persisting across app restarts.
- **Task 4 (Goals list sort):** `domain/services/goal_list_sort.dart`'s `sortGoalsByEvaluationPeriod` is a pure comparator (Evaluation Period group rank, then case-insensitive name) applied inside each existing lifecycle-status group on the Goals tab (Story 2.3's Active/Paused/Archived/Expired grouping is unchanged) — Rolling Window and Custom both fall through to the same unmatched final rank, satisfying AC 4's "combined final group" without special-casing either.
- **Regression note:** adding `GoalFilterBar` to the calendar screens means each goal's name now also renders as a chip label on-screen, which made several pre-existing widget tests' bare `find.text(goalName)` calls ambiguous. Fixed by scoping those finders to the actual goal row (`find.widgetWithText(GoalRow, name)` on Day/Month View; a new `Key('week-goal-row-${goal.id}')` on Week View's `_WeekGoalRow`, which renders its name as a raw `Text` with no wrapping `GoalRow`) in `day_view_test.dart`, `week_view_test.dart`, `month_view_test.dart`, and `midnight_rollover_test.dart`. No production behavior changed by these test fixes — confirmed via full-suite regression run (273 tests, 0 failures).

### File List

- `lib/domain/entities/goal.dart` (modified — `copyWith` gained `clearCategory`)
- `lib/domain/services/goal_service.dart` (modified — added `updateGoalCategory`)
- `lib/domain/services/goal_filter.dart` (new)
- `lib/domain/services/goal_list_sort.dart` (new)
- `lib/presentation/providers/goal_filter_provider.dart` (new)
- `lib/presentation/providers/goal_filter_provider.g.dart` (generated)
- `lib/presentation/providers/goal_data_providers.dart` (modified — added `filteredGoalsProvider`)
- `lib/presentation/providers/goal_data_providers.g.dart` (generated)
- `lib/presentation/providers/goal_wizard_provider.dart` (modified — added `category` field/`setCategory`)
- `lib/presentation/providers/goal_wizard_provider.g.dart` (generated)
- `lib/presentation/components/wizard/name_step.dart` (modified — category field + suggestion chips)
- `lib/presentation/components/wizard/review_step.dart` (modified — wires category into create/edit save paths)
- `lib/presentation/components/goal_filter_bar.dart` (new)
- `lib/presentation/screens/day_view.dart` (modified — filter bar + filtered goal list)
- `lib/presentation/screens/week_view.dart` (modified — filter bar + filtered goal list; added `Key` to `_WeekGoalRow`)
- `lib/presentation/screens/month_view.dart` (modified — filter bar + filtered goal list)
- `lib/presentation/screens/goals/goals_list_screen.dart` (modified — applies the computed sort within each lifecycle group)
- `test/domain/services/goal_filter_test.dart` (new)
- `test/domain/services/goal_list_sort_test.dart` (new)
- `test/domain/services/goal_service_test.dart` (modified — `updateGoalCategory` tests)
- `test/presentation/goal_filter_bar_test.dart` (new)
- `test/presentation/day_view_test.dart` (modified — scoped `find.text` regressions to `GoalRow`)
- `test/presentation/week_view_test.dart` (modified — scoped `find.text` regression to the new `Key`)
- `test/presentation/month_view_test.dart` (modified — scoped one `find.text` regression to `GoalRow`)
- `test/presentation/midnight_rollover_test.dart` (modified — scoped `find.text` regressions to `GoalRow`)

## Change Log

- 2026-08-30: Story 3.5 implemented — category assignment (creation/edit wizard + suggestion picker), Calendar goal filtering (all/single/category, `GoalFilterBar` on Day/Week/Month, session-persistent selection), and the Goals-list computed Evaluation-Period sort. Fixed pre-existing widget-test finder ambiguity caused by the new filter chips. Full regression suite: 273 tests passing.
