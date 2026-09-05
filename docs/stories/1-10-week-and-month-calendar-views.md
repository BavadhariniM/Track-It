# Story 1.10: Week and Month Calendar Views

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to browse a week grid or a full month calendar and see every goal's status at a glance,
so that I can check my progress over time, not just today.

## Acceptance Criteria

1. **Given** any goal and date range **When** Panda opens Week View **Then** a 7-day grid shows each goal's per-day status and the week's overall progress (FR-22)
2. **Given** Panda opens the app with no other view last active **When** the app loads **Then** Month View is shown by default, with each day rendered via `status-cell` (FR-23)
3. **Given** Month View is open **When** Panda swipes horizontally **Then** the view moves to the adjacent month, and a persistent "jump to today" affordance is available regardless of how far they've navigated (FR-23, UX-DR23)
4. **Given** Week-Start is set to Monday (default) or Sunday **When** either calendar view renders **Then** the grid's first column matches that setting (FR-24)
5. **And** long-press is reserved for contextual actions (Cheat Day/Blackout) so no row-level swipe-to-reveal action competes with month/week swipe navigation (UX-DR23)

## Tasks / Subtasks

- [x] Task 1: Week View screen (AC: #1, #4)
  - [x] Subtask 1.1: Build `lib/presentation/screens/week_view.dart`: a 7-day grid showing, for each active goal, its per-day `status-cell` across the week plus a week-level overall progress summary — for every day cell, call `evaluate()` fresh (Story 1.1–1.8's finalized function) per goal per day; the live calendar never reads a cache (AD-7 — not yet built until Epic 3, but the principle "live calendar always calls `evaluate()` fresh" applies from the very first calendar screen built, so this story must not introduce any caching shortcut even informally)
  - [x] Subtask 1.2: Week grid's first column is determined by the Week-Start setting (Sunday or Monday, FR-24, default Monday) — reuse Story 1.3's Week-Start-aware period-boundary logic conceptually (the calendar rendering and the evaluator's Weekly-period boundary calculation must agree on the same first-day-of-week value, sourced from the same setting, so the visual week grid and the evaluated Weekly period never disagree about where a week starts)
  - [x] Subtask 1.3: Render each goal's per-day status as a `status-cell` per Story 1.8's completed five-state vocabulary; render the week's overall progress (e.g. a rollup like "4/7" or per-goal weekly summaries) — for goals whose Evaluation Period is itself Weekly (not Daily), the "per-day status" for days within an in-progress week should reasonably reflect the *period's* current Pending/Success/Fail state rather than inventing a separate per-day sub-status the evaluator doesn't produce; use whatever `DayStatus` `evaluate()` actually returns for that date, without a Week-View-specific reinterpretation
- [x] Task 2: Month View screen (AC: #2, #3, #4)
  - [x] Subtask 2.1: Build `lib/presentation/screens/month_view.dart` as the app's default calendar surface (FR-23) — confirm the app's initial route/tab-bar default routes here when "no other view last active" (first launch, or app relaunch with no persisted last-view state)
  - [x] Subtask 2.2: Render each day of the month as a `status-cell`, using the same live `evaluate()` per goal per day as Week View — reuse the same per-day status-cell rendering logic/component between Week View and Month View rather than duplicating it (both are grids of the same `status-cell` atomic unit, just different grid shapes/densities)
  - [x] Subtask 2.3: Month grid's first column also honors the Week-Start setting (FR-24) — the month grid's weekday-column headers and day placement must use the same Week-Start value as Week View
  - [x] Subtask 2.4: Implement horizontal swipe to move to the adjacent month (UX-DR23) and a persistent "jump to today" affordance visible/reachable regardless of navigation depth (FR-23, UX-DR23) — this affordance must remain accessible whether Panda has swiped 1 month or 20 months away from today
- [x] Task 3: Filter-goal display when multiple goals exist across Week/Month (AC: #1, #2)
  - [x] Subtask 3.1: This story's ACs describe rendering "each Goal's per-day status" (Week View) and each day's Derived Status (Month View) — for Month View specifically, where multiple goals exist, epics.md/FR-23 describes "each day shows Derived Status" (singular per day, implying an aggregate or a single-goal focus), while FR-22/Week View explicitly calls for "each Goal's per-day status" (plural, per-goal rows). Implement Month View showing one day cell per date reflecting an aggregate/summary Derived Status when no goal filter is applied (full multi-goal filtering by category/single-goal is Epic 3 Story 3.5's scope — until then, Month View may reasonably default to "all goals" and needs a defined aggregation rule for a single day's combined status across multiple goals); document the chosen aggregation rule (e.g. worst-status-wins: if any goal Failed that day, the day shows Fail; else if any is Pending, Pending; else Success/Empty as appropriate) since epics.md does not specify one explicitly — flagged as an open question below
  - [x] Subtask 3.2: Week View, by contrast, explicitly shows a grid with "each Goal's per-day status" — implement this as a per-goal row (or per-goal section) within the week grid, consistent with FR-22's literal wording, rather than a single aggregated row
- [x] Task 4: Interaction primitives — swipe vs. long-press non-conflict (AC: #5)
  - [x] Subtask 4.1: Confirm no row-level swipe-to-reveal gesture exists anywhere in Week/Month View that would compete with the month/week horizontal swipe-to-navigate gesture (UX-DR23, EXPERIENCE.md Interaction Primitives: "no swipe-to-reveal actions on rows, since combined with month-swipe gestures that would create gesture ambiguity")
  - [x] Subtask 4.2: Confirm long-press on a day cell/goal row within Week/Month View is reserved exclusively for the Cheat Day/Blackout Date sheet (Story 1.6's `cheat_blackout_sheet.dart` component, reused here) — tapping a day cell opens Day View for that date (FR-21), long-press opens the contextual sheet; no other gesture is defined for a calendar cell
- [x] Task 5: Tap-through to Day View (AC: implicit via FR-21 cross-reference)
  - [x] Subtask 5.1: Tapping any day cell in Week or Month View opens Day View for that date (FR-21, already built in Story 1.1) — reuse Story 1.1's Day View screen, passing the tapped date as a parameter (Story 1.1's Dev Notes already anticipated this: "build the screen to accept an arbitrary date parameter since Story 1.10 will add full calendar navigation into it")
- [x] Task 6: Testing (AC: all)
  - [x] Subtask 6.1: Widget-test Week View renders a 7-day grid with correct per-goal per-day status-cells and a week progress summary, for both Week-Start settings
  - [x] Subtask 6.2: Widget-test Month View is the default landing view on fresh app load, renders correct status-cells for every day of the month, and honors Week-Start for its column layout
  - [x] Subtask 6.3: Widget-test horizontal swipe navigation moves to the adjacent month and that "jump to today" is reachable after navigating multiple months away
  - [x] Subtask 6.4: Widget-test that a day cell tap opens Day View for that date, and that long-press opens the Cheat Day/Blackout sheet, with no swipe-to-reveal row action present anywhere in either view
  - [x] Subtask 6.5: Unit-test (or widget-test, since this touches presentation-layer aggregation) the Month View multi-goal aggregation rule chosen in Task 3.1, since it's a judgment call not explicitly specified upstream

## Dev Notes

- **This story is purely presentation-layer** — it introduces no new domain/evaluator logic beyond confirming Week-Start plumbing (already built in Story 1.3) reaches the calendar UI consistently. Both Week View and Month View must call the single `evaluate()` function fresh per cell; **do not** read from any cache — the read-optimization cache (`CacheWriter`, AD-7) does not exist until Epic 3, and even once it exists, AD-7 explicitly states "the live calendar never reads the cache — always calls `evaluate()` fresh." This story is establishing that pattern for the first time and it must not be violated even informally (e.g. no ad hoc in-memory memoization that silently becomes a stale-data risk later).
- **FR-24 (Week-Start) consistency is critical:** the calendar grid's visual first-column and the evaluator's Weekly-period boundary calculation (Story 1.3) must derive from the exact same Week-Start value. A bug where the UI shows Monday-first while the evaluator computes Sunday-first boundaries would make Week View's rendered per-day statuses inconsistent with what a Weekly goal's actual period boundaries are — verify this explicitly with a test that constructs a Weekly goal and confirms its evaluated period boundary matches the rendered week grid's boundary for both Week-Start settings.
- **UX-DR23 (swipe + jump-to-today + no row-swipe conflict):** horizontal swipe for month/week navigation, persistent "jump to today," and the explicit prohibition on row-level swipe-to-reveal actions (which would conflict with the swipe-navigation gesture) are all one coherent interaction-design decision — implement all three together, not swipe-navigation alone.
- **UX-DR6 (`status-cell`) reuse:** both Week View and Month View render the same `status_cell.dart` component built in Story 1.1 and completed in Story 1.8 (all five states). Do not create separate cell-rendering logic for Week vs. Month — they differ only in grid layout/density, not in what a cell looks like or how its status is computed.
- **Month View's multi-goal aggregation is an open design question** epics.md/architecture do not resolve explicitly (see Task 3.1) — FR-22 (Week View) explicitly says "each Goal's per-day status" (per-goal), while FR-23 (Month View) says "each day shows its Derived Status" (singular, ambiguous when multiple goals exist and no filter is applied). Full goal filtering (all/single/category) is Epic 3 Story 3.5's scope, so this story must make a reasonable, documented default choice for the interim "all goals, no filter" Month View state. The Dev Notes above propose a worst-status-wins aggregation rule as the most defensible default (a Fail anywhere is more informationally important to surface than hiding it behind a Success elsewhere) — this is a judgment call, not a directive from any source document, and is flagged as an open question for confirmation.
- **Anti-duplication guidance:** reuse `status_cell.dart` (Story 1.1/1.8), the Day View screen (Story 1.1, now receiving a date parameter), and the Cheat Day/Blackout sheet (Story 1.6) as-is. The only new components are the Week View and Month View screen shells and their grid-layout logic.
- **Testing standards:** Week-Start consistency between UI rendering and evaluator boundary calculation is a correctness-adjacent concern (NFR-6-relevant, since a mismatch would make displayed statuses wrong even though the evaluator itself is correct) — test it explicitly, not just visually.

### Project Structure Notes

- New files: `lib/presentation/screens/week_view.dart`, `lib/presentation/screens/month_view.dart` — within the existing `presentation/screens/` folder from the Story 1.1 seed.
- No new domain/data files required.
- One open question flagged above regarding Month View's multi-goal-no-filter aggregation rule, deferred to a documented default pending confirmation, since full filtering doesn't land until Epic 3 Story 3.5.

### References

- [Source: docs/epics.md#Story 1.10: Week and Month Calendar Views]
- [Source: docs/epics.md#Requirements Inventory] (FR-22, FR-23, FR-24)
- [Source: docs/prd/4-features.md#FR-22: Week View]
- [Source: docs/prd/4-features.md#FR-23: Month View]
- [Source: docs/prd/4-features.md#FR-24: Week-Start Setting]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-7 — Status Cache: Read-Optimization Only, Single Writer, Fully Recomputable] (live calendar always calls evaluate() fresh — principle established here even before the cache exists)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Interaction Primitives] (UX-DR23 — swipe navigation, jump to today, no row-swipe conflict)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components] (status-cell reused across calendar views)
- [Source: docs/stories/1-1-scaffold-the-app-and-track-a-simple-daily-goal.md] (previous story intelligence — Day View built to accept a date parameter for this story, status-cell component)
- [Source: docs/stories/1-3-evaluate-all-evaluation-period-types.md] (previous story intelligence — Week-Start-aware period-boundary logic this story's UI must agree with)
- [Source: docs/stories/1-6-blackout-dates.md] (previous story intelligence — Cheat Day/Blackout sheet reused via long-press here)
- [Source: docs/stories/1-8-pending-certain-failure-red-and-the-zero-eligible-days-signal.md] (previous story intelligence — completed five-state status-cell vocabulary rendered here)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- Initial `_MonthGrid` implementation used `GridView.builder` with a `SliverGridDelegateWithFixedCrossAxisCount`, which only builds cells currently within the viewport (lazy sliver rendering). A widget test asserting "one `StatusCell` per grid day" found only 28 of 42 expected cells for a 6-row month on the default test surface. Fixed by replacing `GridView.builder` with an eagerly-built `Column` of `Row`s (7 cells each) — a month grid is small (max 6 rows), so there's no lazy-loading benefit, and every day's cell (and its `evaluate()` call) now genuinely exists in the tree on every build regardless of scroll position, which also matches AD-7's "always evaluate fresh" spirit more literally than a lazy list would.
- No Riverpod "modify provider during build" issues were hit — `MonthViewScreen`'s page/month navigation state is plain `State`/`PageController` local state (not a provider), so the Story 1.9 `initState`-mutates-a-provider trap noted in the task brief didn't apply here; `weekStartSettingProvider` is only ever read via `ref.watch`, never mutated from `build()`/`initState()`.

### Completion Notes List

- **Week-Start plumbing**: added `lib/presentation/providers/week_start_provider.dart`, a `@riverpod class WeekStartSetting extends _$WeekStartSetting` (Riverpod 3.x codegen, matching `GoalWizard`'s pattern) defaulting to `WeekStart.monday`. No Settings UI exists yet (out of scope for this story) — both Week View and Month View read it via `ref.watch(weekStartSettingProvider)` and pass the same value into `evaluate()`'s `weekStart` parameter. Both views also derive their grid's first/last column by calling the evaluator's own `periodBoundaryFor(evaluationPeriod: EvaluationPeriod.weekly, ...)` directly (not a reimplementation) — this makes the "UI first-column must agree with evaluate()'s Weekly-period boundary" requirement true by construction rather than by convention, and `week_view_test.dart`'s "Week-Start consistency" test group asserts this explicitly for both Monday and Sunday, for a Weekly-period goal.
- **Month View multi-goal aggregation rule** (Task 3.1, open question): implemented **worst-status-wins**, precedence `Fail > Pending > Cheat > Success > Empty`, as the public `aggregateDayStatus()` function in `lib/presentation/screens/month_view.dart`. Rationale documented in that function's doc comment: a Fail anywhere is the most actionable signal and must never be hidden behind an unrelated goal's Success; Empty only wins when every goal is non-eligible or no goals exist. This is a documented default per the story's Dev Notes, not a directive from any source document, and is expected to be superseded by real goal filtering in Epic 3 Story 3.5. Week View's "N/7 days on track" rollup reuses the same function (imported from `month_view.dart`) so both views agree on what "a day's combined status" means.
- **Month View long-press with multiple goals**: since Month View's day cell is a single aggregate across all goals (unlike Week View's per-goal rows, which are unambiguous), long-press on a day with exactly one goal opens the Cheat/Blackout sheet directly; with multiple goals it first shows a lightweight goal-picker bottom sheet, then opens the existing `showCheatBlackoutSheet` for the chosen goal+date. No new sheet component was built — this reuses Story 1.6's sheet unchanged.
- **Month View swipe navigation**: implemented with a plain `PageView.builder` over a large-but-finite page range (2401 pages, anchored at page 1200 = "today's month"), giving roughly 100 years of navigation in each direction without the complexity of a truly unbounded `PageView`. "Jump to today" (`Icons.today` app-bar action) animates back to the anchor page and is always present in the app bar regardless of navigation depth.
- **Month grid layout**: switched from `GridView.builder` to an eagerly-built `Column` of `Row`s per the Debug Log entry above.
- **Navigation between views**: Month View's app bar gained a "Week View" action (`Icons.view_week`) that pushes `WeekViewScreen` for the currently displayed month (using today's date if the displayed month is the current month, otherwise the 1st of the displayed month) — this is the "minimal in-story navigation" the task brief asked for; no persistent tab bar/bottom-nav was built (out of scope).
- **main.dart**: changed `home` from `DayViewScreen(date: DateTime.now())` to `const MonthViewScreen()` per AC #2. `day_view.dart` itself was not modified — Day View already accepted a `date` parameter from Story 1.1, so both Week View and Month View reuse it unchanged for their tap-through.
- **Testing**: added `test/presentation/month_view_test.dart` and `test/presentation/week_view_test.dart` covering Subtasks 6.1–6.5, plus the Dev Notes' explicit Week-Start-vs-evaluator-boundary consistency check. Full suite: 146/146 passing (126 pre-existing + 20 new), `dart analyze` clean (only the 5 pre-existing `goal_service.dart` infos remain).

### File List

- `lib/presentation/providers/week_start_provider.dart` (new)
- `lib/presentation/providers/week_start_provider.g.dart` (new, generated)
- `lib/presentation/screens/month_view.dart` (new)
- `lib/presentation/screens/week_view.dart` (new)
- `lib/main.dart` (modified — `home` now `MonthViewScreen`)
- `test/presentation/month_view_test.dart` (new)
- `test/presentation/week_view_test.dart` (new)
