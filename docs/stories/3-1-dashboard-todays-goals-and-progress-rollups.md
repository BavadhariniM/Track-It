---
baseline_commit: NO_VCS
---

# Story 3.1: Dashboard — Today's Goals and Progress Rollups

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to open the app to a Dashboard showing today's eligible goals with progress, current streaks, and this week's/month's rollups,
so that I can see everything at a glance without navigating anywhere.

## Acceptance Criteria

1. **Given** one or more goals eligible today, **when** Panda opens the Today tab, **then** each appears as a `goal-row` with progress (e.g. "3/5 complete" for period goals, done/not-done for daily) (FR-26)
2. **Given** the same Dashboard, **when** it renders, **then** it also shows a rollup of this week's and this month's in-progress goals for a glance (FR-26)
3. **Given** a reminder time is configured, **when** the Dashboard renders, **then** the next scheduled reminder time (a single global time) is shown (FR-26)
4. **Given** a GoalLog or GoalVersion commits, **when** the write completes, **then** `CacheWriter` (AD-7) writes the resulting `DayStatus` inside the same transaction, and the Dashboard's rollups read from this cache — never a live `evaluate()` call for the rollup surface (AD-7, AD-8)
5. **Given** the cache is deleted or corrupted, **when** `StatsService` needs a value not present in cache, **then** it falls back to calling `evaluate()` directly for that range, with no error state and no data loss (AD-8 consequence)
6. **And** the bottom tab bar (UX-DR12) shows Today as the active tab among the 4 tabs (Today/Calendar/Goals/Settings)

## Tasks / Subtasks

- [x] Task 1: Define the `CacheWriter` and `StatsService` domain contracts (AC: 4, 5)
  - [x] Subtask 1.1: In `lib/domain/services/cache_writer.dart`, define abstract `CacheWriter` with a method to write a single `DayStatus` row and a method to wholesale-recompute/rebuild the cache for a goal or date range (AD-7's "fully recomputable" guarantee) — no concrete Drift code here, domain stays Flutter/Drift-free (AD-1)
  - [x] Subtask 1.2: Confirm/extend the `DayStatus` entity in `lib/domain/entities/day_status.dart` (built in Epic 1 for the evaluator's return type) is reused unchanged as the cache row shape — AD-7 mandates "bare `DayStatus` only," no additional cached rollup fields
  - [x] Subtask 1.3: In `lib/domain/services/stats_service.dart`, define `StatsService` with methods for: today's eligible-goal progress, this-week rollup, this-month rollup, and current streak per goal (the streak method's full rule-aware algorithm is completed in Story 3.3 — see Dev Notes; this story only needs a working Daily-goal-correct implementation plus the method signature all callers will use permanently)
  - [x] Subtask 1.4: Every `StatsService` method reads cached `DayStatus` via the domain repository interface first; for any date/goal combination with no cache row, it calls `evaluate()` (from Epic 1's `lib/domain/evaluator/`) directly as fallback — never a second evaluation implementation (AD-4, AD-8)

- [x] Task 2: Implement the Drift-backed cache and wire it into existing commit paths (AC: 4, 5)
  - [x] Subtask 2.1: Add a `status_cache` Drift table in `lib/data/drift/` with columns matching bare `DayStatus` (goalId, date, status, plus whatever minimal fields `DayStatus` already carries from Epic 1) — no extra denormalized rollup columns (AD-7)
  - [x] Subtask 2.2: Implement `DriftCacheWriter implements CacheWriter` in `lib/data/cache/cache_writer_impl.dart`, upserting by `(goalId, date)`
  - [x] Subtask 2.3: **Modify** `GoalService`'s existing log-write path (`lib/domain/services/goal_service.dart`, built in Epic 1 Story 1.1 and extended in Epic 1 Story 1.2/1.11 and Epic 2 Story 2.1) so that after a `GoalLog` or `GoalVersion` commits, it invokes `CacheWriter` to recompute and store the affected date's `DayStatus` **inside the same Drift transaction** — do not add a second, separate write step outside the transaction (AD-7, Transaction atomicity convention)
  - [x] Subtask 2.4: **Modify** the midnight-rollover job (Epic 1 Story 1.11, FR-20) so that after its full data reload it also invokes `CacheWriter` for the rolled-over date, inside the same transaction as the rollover's auto-commit write (AD-7)
  - [x] Subtask 2.5: Provide a wholesale-recompute entry point (e.g. `CacheWriter.rebuildAll()`) that iterates all goals/dates and calls `evaluate()` fresh for each — proves the cache is "provably re-derivable" per AD-7; expose it for use if the cache is ever found empty/corrupted (does not need its own UI trigger in this story, just the capability)

- [x] Task 3: Riverpod providers for Dashboard data (AC: 1, 2, 3, 4, 5)
  - [x] Subtask 3.1: Add `@riverpod` providers in `lib/presentation/providers/` exposing `StatsService`'s today/week/month rollup reads and per-goal streak, composed via DI (AD-2) — no `BuildContext`-coupled access
  - [x] Subtask 3.2: Add a provider reading the global reminder time from `shared_preferences` (AD-3 settings exception) for display only — see Dev Notes on the Epic 4 dependency ordering issue

- [x] Task 4: Build the Dashboard screen (AC: 1, 2, 3, 6)
  - [x] Subtask 4.1: Implement `lib/presentation/screens/dashboard_screen.dart` rendering today's eligible goals using the existing `goal-row` component (built in Epic 1 Story 1.1/1.7, `lib/presentation/components/`) — do not build a second row component for the Dashboard
  - [x] Subtask 4.2: Render each goal-row's progress fraction ("3/5 complete") and, for Boolean daily goals, the done/not-done label, per UX-DR7 — reuse the component's existing variants, do not fork it
  - [x] Subtask 4.3: Add a "This Week" / "This Month" rollup section below the today list, using `spacing.5`–`spacing.6` to visually separate it as a major section break (DESIGN.md Layout & Spacing)
  - [x] Subtask 4.4: Render each goal-row's current streak value using the `numeric` tabular-figure typography token (UX-DR2) so digits don't jitter — plain number + unit only, no streak-cheerleading copy/emoji (UX-DR19, EXPERIENCE.md Voice and Tone)
  - [x] Subtask 4.5: Display the next scheduled reminder time (read-only) if a value exists in `shared_preferences`; if no reminder time has been set yet (expected until Epic 4 Story 4.1 ships the settings UI), render nothing for that field rather than an error or a placeholder string
  - [x] Subtask 4.6: Confirm the bottom tab bar (already scaffolded in Epic 1 Story 1.1 per UX-DR12's 4-tab IA — Today/Calendar/Goals/Settings) marks Today as the active/selected tab when Dashboard is shown

- [x] Task 5: Testing (AC: 1-6)
  - [x] Subtask 5.1: `test/domain/` unit tests for `StatsService`: cache-hit path returns cached values without calling `evaluate()`; cache-miss path falls back to `evaluate()` and returns a correct value with no thrown error
  - [x] Subtask 5.2: Unit tests for `CacheWriter`/`DriftCacheWriter`: writing after a `GoalLog` commit produces a matching cache row; `rebuildAll()` reproduces identical `DayStatus` values to a fresh `evaluate()` call for the same inputs (cache is provably re-derivable, AD-7)
  - [x] Subtask 5.3: Widget tests for `DashboardScreen`: renders goal-rows for eligible goals, renders week/month rollup section, renders reminder time when present and omits it gracefully when absent, Today tab shows as active

## Dev Notes

- **Cache vs. live-evaluation split (AD-7) — the single most important rule in this story:** the Dashboard is a cache-reading surface, never a live-evaluation surface. Only the Day/Week/Month calendar views (FR-21–23, built in Epic 1) call `evaluate()` directly at render time. Every Dashboard rollup, progress fraction, and streak value must be sourced from `StatsService`, which itself reads cached `DayStatus` and falls back to `evaluate()` only for cache misses (AD-8). If a developer is tempted to call `evaluate()` directly from `dashboard_screen.dart` or a Dashboard-specific provider, that is a violation of AD-7/AD-8 — route it through `StatsService` instead.
- **This story introduces `CacheWriter` and `StatsService` for the whole app** (per epics.md's Epic 3 implementation note). Because Epic 1 and Epic 2 already established `GoalService` as the sole writer of `GoalVersion`/`GoalLog` (AD-6) and already built the midnight-rollover job (Epic 1 Story 1.11), this story's data-layer work is primarily **modifying those existing write paths** to additionally invoke `CacheWriter` inside the same transaction — not building a new write path from scratch. Read the existing `GoalService` commit methods and the rollover job before touching them; preserve their existing behavior (correction floor at 0, one-Version-per-`(goalId, versionStartDate)`, single-transaction atomicity) and only add the `CacheWriter` invocation.
- **`StatsService` is the sole streak/rollup computer for the entire app, starting now (AD-8).** Story 3.1 only needs the Daily-goal case of streak counting to be correct (consecutive successful days); Story 3.3 completes the rule-aware algorithm for non-Daily and Rolling Window goals. Regardless, the **method signature and calling contract** established here (`StatsService.currentStreak(goalId)` or equivalent) must not change in Story 3.3 — that story upgrades the implementation behind the same interface so the Dashboard and Goal Detail (Story 3.2) never need to change how they call it.
- **Reminder-time display dependency note:** FR-26 requires the Dashboard to show "the next scheduled reminder time," but the settings UI to configure that global reminder time is Epic 4 Story 4.1, which has not been built when this story is implemented (Epic 3 precedes Epic 4). Implement the Dashboard's reminder-time display defensively: read whatever value (if any) exists at the `shared_preferences` key reserved for it, and render nothing if unset — do not block this story on Epic 4, and do not fabricate a settings UI here. This is a known forward-reference; flagged as an open question below.
- **UX-DR requirements this story delivers:**
  - UX-DR7 (`goal-row`): reused as-is from Epic 1, not re-implemented.
  - UX-DR2 (`numeric` typography): required for the streak number and any "3/5" fraction so digits don't shift width.
  - UX-DR12 (bottom tab bar, 4 tabs): Today must show as active; the tab bar itself is not built here (already scaffolded Epic 1 Story 1.1).
  - UX-DR19 (voice/tone): no exclamation points, no streak-cheerleading language/emoji anywhere in Dashboard copy.
  - Spacing scale (UX-DR4): use `spacing.5`–`spacing.6` between the "Today" list and the week/month rollup section (DESIGN.md Layout & Spacing guidance for major section breaks).
- **Anti-duplication guidance:** do not create a new row/list-item component for the Dashboard — reuse `goal-row` (Epic 1). Do not implement rollup math or streak math inside `dashboard_screen.dart` or a Dashboard-only provider — all of it lives in `StatsService`. Do not create a second Drift table or writer for cached status beyond the single `status_cache` table and single `CacheWriter` implementation (AD-7 mandates exactly one writer).
- **Testing standards:** verify cache-hit vs. cache-fallback behavior explicitly (AD-8 consequence — no error state, no data loss on a missing/corrupted cache). Do not test streak correctness for non-Daily period types in this story's test suite beyond "not broken" — full period-based streak correctness is Story 3.3's testing responsibility; this story's tests only need to confirm Daily-goal streak correctness and the cache-hit/fallback mechanics.

### Project Structure Notes

- New domain files: `lib/domain/services/cache_writer.dart`, `lib/domain/services/stats_service.dart` — matches the structural seed's `lib/domain/services/` note: "GoalService (AD-6), StatsService (AD-8), repository + CacheWriter interfaces."
- New data files: `lib/data/drift/` (new `status_cache` table + generated DAO), `lib/data/cache/cache_writer_impl.dart` — matches the seed's `lib/data/cache/ # CacheWriter implementation (AD-7)`.
- New presentation files: `lib/presentation/screens/dashboard_screen.dart`, new providers under `lib/presentation/providers/`.
- Modified existing files (from Epic 1/2, expected to already exist by the time this story is implemented): `GoalService`'s log/version commit methods, the midnight-rollover job, and the existing bottom-tab-bar scaffold to mark Today active.
- No conflicts detected with the structural seed; no files created outside the documented `lib/domain`, `lib/data`, `lib/presentation` split (AD-1).

### References

- [Source: docs/epics.md#Story 3.1: Dashboard — Today's Goals and Progress Rollups]
- [Source: docs/epics.md#Epic 3: Goal Detail, Streaks & Stats] (implementation notes: "Introduces the read-optimization status cache (AD-7, `CacheWriter`) and `StatsService` (AD-8)")
- [Source: docs/epics.md#Requirements Inventory] FR-26
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-7] Status cache: read-optimization only, single writer, fully recomputable
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-8] StatsService owns Streaks and rollups
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4] Pure evaluator contract (evaluate() reused by StatsService)
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6] GoalService owns all Version and Log writes (existing write path this story extends)
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components] goal-row, numeric typography
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Information Architecture] bottom tab bar (UX-DR12)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Voice and Tone] UX-DR19 copy constraints
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Stack] flutter_riverpod ^3.4.2, drift + drift_flutter 2.32.0+ (seed, re-verify at build time per architecture doc's own caveat)

## Dev Agent Record

### Agent Model Used

claude-sonnet-5

### Debug Log References

- `flutter analyze` — 0 errors (20 pre-existing-style `prefer_initializing_formals` infos, same constructor-injection convention every existing repository/service in this codebase already uses).
- `flutter test` — 235/235 passing (223 pre-existing + 12 new for this story), no regressions.

### Completion Notes List

- Introduced `CacheWriter`/`StatsService`/`StatusCacheRepository` (domain, Drift-agnostic) plus their Drift-backed implementations (`DriftCacheWriter`, `DriftStatusCacheRepository`, new `status_cache` table, `schemaVersion` 1 → 2 with an additive `onUpgrade`).
- `GoalService` now takes a required `CacheWriter` and calls a private `_refreshCache(goalId, date)` helper — inside the same transaction — after every `GoalLog`/`GoalVersion` write path (`createGoal`, `logBoolean`, `logCounter`, `markDnf`, and both branches of `_writeVersionSegment`, which backs `editGoalVersion`/`pauseGoal`/`resumeGoal`). Only the single "affected date" is recomputed per write, per the story's literal AC 4 wording — not a full period re-derivation; any other date served from cache stays stale until its own write or a `rebuildAll()`. `markBlackoutDate`/`markCheatDay` are intentionally left out of scope: AC 4 only names `GoalLog`/`GoalVersion` commits.
- Story 1.11's midnight-rollover watcher (`midnight_rollover_provider.dart`) needed **no code change** for Subtask 2.4: its auto-commit is a plain call to `GoalService.logCounter`, which already refreshes the cache for the rolled-over date as part of the change above.
- **Orientation-notes discrepancy found and resolved:** the story's Dev Notes/Task 4.6 assume the bottom tab bar was "already scaffolded in Epic 1 Story 1.1," but it does not exist in the codebase — `goals_list_screen.dart`'s own header comment confirms this explicitly ("No persistent tab bar exists yet ... out of this story's scope"), and `main.dart` went straight to `MonthViewScreen`. Built the tab bar now (new `app_shell.dart`, a lazy single-active-tab shell — Today/Calendar/Goals/Settings, Today default) since AC 6 requires it and nothing else in the codebase provides it; a minimal `Settings` placeholder screen backs the fourth tab since Epic 4/6 own its real content. Updated `main.dart`'s `home` to `AppShell`. This is a legitimate landing-screen change (`EXPERIENCE.md`'s IA table already specifies Today as the "App open (cold start)" tab), not a regression — updated `month_view_test.dart`'s one `TrackerApp()`-level test accordingly (Month View is now reached via the Calendar tab, not the app root).
- Extended `GoalRow` with an optional `streak` field (defaults `null`, fully backward compatible) rather than forking the component, per the story's anti-duplication guidance — renders "Streak: N" in `numeric` typography only when non-null.
- `StatsService.currentStreak` is intentionally simple per the story's scoping: correct for Daily goals (walks backward from the most recently *resolved* day, `cheat` continues the streak, `empty`/non-eligible days are skipped, `fail`/unresolved-`pending` stop it); not asserted correct for period-based goals — Story 3.3's responsibility.
- Added the `shared_preferences` package (not previously a dependency) for `reminderTimeProvider`, reading a documented key (`reminderTimeKey` in `reminder_time_provider.dart`) that Epic 4 Story 4.1's settings UI must write to; renders nothing when unset.
- **Mechanical test-fixture change across the existing suite:** since `GoalService` now requires a `CacheWriter` and `goalServiceProvider` composes one via a new `cacheWriterProvider` (itself composed from the already-overridden repository providers), every widget test that overrides the repository providers needed one more override (`statusCacheRepositoryProvider.overrideWithValue(InMemoryStatusCacheRepository(store))`) to keep using in-memory fakes instead of a real database; applied identically across 8 existing test files plus the 4 test files that construct `GoalService` directly (added `cacheWriter: InMemoryCacheWriter(store)`). Added `InMemoryStatusCacheRepository`/`InMemoryCacheWriter` fakes and a `statusCache` map to `InMemoryStore` (including in its transactional snapshot/restore) in `test/domain/services/fakes.dart`.
- Self-caught and fixed a tooling mistake mid-session: a PowerShell `Get-Content`/`Set-Content` round-trip (used to insert the mechanical override above across 8 files) silently mis-decoded UTF-8 as Windows-1252, corrupting em-dashes and other non-ASCII characters into mojibake. Caught it immediately via a follow-up read, repaired all 8 files with a CP1252→UTF-8 reinterpretation pass, and verified with a grep for leftover mojibake markers before proceeding.

### Change Log

- Story 3.1 implemented: `CacheWriter`/`StatsService`/status cache (AD-7/AD-8), Dashboard screen with Today/Week/Month rollups and streak display, and the previously-missing bottom tab bar (Today/Calendar/Goals/Settings) wired in as the app's landing shell.

### File List

**New**
- `lib/domain/services/cache_writer.dart`
- `lib/domain/services/status_cache_repository.dart`
- `lib/domain/services/stats_service.dart`
- `lib/data/repositories/drift_status_cache_repository.dart`
- `lib/data/cache/cache_writer_impl.dart`
- `lib/presentation/providers/reminder_time_provider.dart` (+ generated `reminder_time_provider.g.dart`)
- `lib/presentation/providers/stats_providers.dart` (+ generated `stats_providers.g.dart`)
- `lib/presentation/screens/dashboard_screen.dart`
- `lib/presentation/screens/app_shell.dart`
- `test/domain/services/cache_writer_test.dart`
- `test/domain/services/stats_service_test.dart`
- `test/presentation/dashboard_screen_test.dart`
- `test/presentation/app_shell_test.dart`

**Modified**
- `lib/data/drift/tables.dart` (new `StatusCaches` table)
- `lib/data/drift/database.dart` (+ regenerated `database.g.dart`; `schemaVersion` 1 → 2, additive `onUpgrade`)
- `lib/domain/services/goal_service.dart` (required `CacheWriter`; cache refresh wired into every `GoalLog`/`GoalVersion` write path)
- `lib/presentation/providers/repository_providers.dart` (+ regenerated `.g.dart`; new `statusCacheRepositoryProvider`, `cacheWriterProvider`)
- `lib/presentation/providers/goal_service_provider.dart` (+ regenerated `.g.dart`; wires `cacheWriter`)
- `lib/presentation/components/goal_row.dart` (optional `streak` field)
- `lib/main.dart` (`home` is now `AppShell`, not `MonthViewScreen`)
- `pubspec.yaml` / `pubspec.lock` (added `shared_preferences`)
- `test/domain/services/fakes.dart` (`InMemoryStatusCacheRepository`, `InMemoryCacheWriter`, `InMemoryStore.statusCache`)
- `test/domain/services/goal_service_test.dart`
- `test/domain/evaluator/pause_resume_evaluation_test.dart`
- `test/domain/evaluator/goal_service_multi_version_test.dart`
- `test/domain/evaluator/goal_service_cheat_day_test.dart`
- `test/presentation/day_view_test.dart`
- `test/presentation/week_view_test.dart`
- `test/presentation/month_view_test.dart` (also: landing-screen test updated for `AppShell`)
- `test/presentation/midnight_rollover_test.dart`
- `test/presentation/goals_list_screen_test.dart`
- `test/presentation/goal_edit_wizard_test.dart`
- `test/presentation/goal_detail_screen_test.dart`
- `test/presentation/goal_creation_wizard_test.dart`
