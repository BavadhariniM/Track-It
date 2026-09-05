---
baseline_commit: NO_VCS
---

# Story 1.1: Scaffold the App and Track a Simple Daily Goal

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to create a simple daily Boolean goal and log it done/not-done each day,
so that I can start using the app for my most basic commitments while the rest of the engine is built out.

## Acceptance Criteria

1. **Given** the app is freshly installed **When** Panda opens it for the first time **Then** no login/account step is shown and the Dashboard area shows an empty state prompting Goal creation (UX-DR26)
2. **Given** Panda fills in a goal name, Boolean tracking type, Daily evaluation period, "every day" eligible-days, and target "Exactly 1" **When** they save **Then** a Goal plus one GoalVersion is persisted via GoalService (AD-6) in a single Drift transaction (AD-3), with a UUIDv4 id and an ISO-8601 date-only start date
3. **Given** a goal exists and today is an eligible day **When** Panda opens Day View **Then** the goal appears as a `goal-row` (UX-DR7) with its current status rendered via the `status-cell`/badge vocabulary (UX-DR6), and this Day View is itself the surface FR-21 requires (FR-21)
4. **Given** Panda taps the goal row **When** they mark it done **Then** a GoalLog is written through GoalService inside one transaction and the row's status updates to Success (green) immediately, computed by the pure `evaluate()` function (AD-4) — no separately stored "done" flag drives the color (FR-13)
5. **Given** the app is killed immediately after a tap but before the write commits **When** Panda reopens the app **Then** at most that one in-flight entry is lost and all previously committed data is intact (FR-19)
6. **And** the base color/typography/spacing/button component tokens (UX-DR1–5, UX-DR10) are the only styling used on every screen in this story — no ad hoc colors or spacing

## Tasks / Subtasks

- [x] Task 1: Scaffold Flutter project and structural seed (AC: #1, #2)
  - [x] Subtask 1.1: Create Flutter project targeting current stable Flutter/Dart channel (record exact `flutter --version` output in Completion Notes; this seed table is explicitly "re-verify at build time" per Architecture Stack table)
  - [x] Subtask 1.2: Create the exact folder seed under `lib/`: `domain/{entities,evaluator,services}`, `data/{drift,repositories,cache,io,widget_bridge}`, `presentation/{screens,components,providers}`, `platform/{android,ios}`, and `test/domain/` at repo root — no other top-level source layout is permitted (Architecture Structural Seed)
  - [x] Subtask 1.3: Add pinned-seed dependencies to `pubspec.yaml`: `flutter_riverpod ^3.4.2`, `riverpod_generator`/`riverpod_annotation ^4.0.8`/`^4.0.6`, `drift`+`drift_flutter 2.32.0+`; do not add `flutter_local_notifications` or `home_widget` yet (Epic 4/5 concern, not Epic 1) — re-verify each version against current `pub.dev` at `flutter pub add` time per the Stack table's own "re-verify at build time" caveat, and record actual resolved versions in Completion Notes / File List (`pubspec.lock`)
  - [x] Subtask 1.4: Configure Riverpod code-gen (`build_runner`, `riverpod_generator`) and confirm a trivial `@riverpod` provider builds end-to-end before writing real providers
- [x] Task 2: Domain entities (AC: #2, #4)
  - [x] Subtask 2.1: Create `lib/domain/entities/goal.dart` — `Goal` entity: `id` (UUIDv4 string), `name`, `description`, `category` (nullable string; full category *filtering* is Epic 3 Story 3.5, but the field must exist on the entity now per the ER diagram), `archived` (bool), `startDate` (ISO-8601 date-only string)
  - [x] Subtask 2.2: Create `lib/domain/entities/goal_version.dart` — `GoalVersion` entity per the ER diagram: `id`, `goalId`, `versionStartDate`, `evaluationPeriod`, `eligibleDaysRule`, `targetComparison`, `targetValue`, `trackingType`, `cheatDayQuota` (default 0; Cheat Day *usage* is Epic 2 Story 2.4, but the quota field must exist on Version now), `isPaused` (bool, default `false`; pause/resume *UI and writing* is Epic 2 Story 2.2, but `evaluate()` must read this field from day one — see Task 3 and AD-4's pause-awareness rule)
  - [x] Subtask 2.3: Create `lib/domain/entities/goal_log.dart` — `GoalLog` entity: `id`, `goalId`, `date`, `timestamp`, `value` (float), `completed` (bool), `dnfMarked` (bool; display-only, DNF *marking UI* is Epic 2 Story 2.5, but field must exist now), `note`. Deliberately **no** `versionId`/`goalVersionId` field — per architecture, which Version governs a log is resolved at evaluation time by matching `date` against Version windows, never stored (Architecture ER notes)
  - [x] Subtask 2.4: Create `lib/domain/entities/day_status.dart` — `DayStatus` entity: `date`, `status` (enum: success/fail/cheat/empty/pending — the five-state vocabulary, UX-DR1/UX-DR6), plus whatever minimal fields `evaluate()` needs to return for this story's Daily/Boolean/"every day"/"Exactly 1" case (`goalId`, `completed`/count context) — keep the shape extensible since Story 1.3 onward will exercise many more period types against this same entity, not a new one
  - [x] Subtask 2.5: Define minimal placeholder entities `CheatDay` and `BlackoutDate` are **not** created in this story — they belong to Story 1.6 (`BlackoutDate`) and Epic 2 Story 2.4 (`CheatDay`) respectively, per "no table is created before the story that needs it." The `evaluate()` signature (Story 1.3) will still declare `List<CheatDay> cheatDays` and `List<BlackoutDate> blackoutDates` parameters once those stories land: for this story, only build the minimal evaluator entry point needed for a Daily Boolean goal (see Task 3) and do not attempt to construct the full AD-4 signature prematurely
- [x] Task 3: Minimal pure evaluator entry point (AC: #4)
  - [x] Subtask 3.1: Create `lib/domain/evaluator/evaluate.dart` implementing a function that, for this story's narrow case (Daily period, "every day" eligible-days, Boolean type, Exactly-1 target, single Version, no cheat days/blackout dates yet), returns the correct `DayStatus` for a given date from `{goal, versions, logs, date}`. Write it so its signature and internals can grow into the full AD-4 contract `evaluate({Goal goal, List<GoalVersion> versions, List<GoalLog> logs, List<CheatDay> cheatDays, List<BlackoutDate> blackoutDates, DateTime date})` in Story 1.3 without a rewrite — accept empty lists for `cheatDays`/`blackoutDates` now rather than omitting the parameters, so Story 1.3 only has to widen behavior, not change the call sites this story creates
  - [x] Subtask 3.2: Enforce purity from day one: zero Flutter imports, zero Drift imports, no I/O, fully deterministic (AD-1, AD-4) — this file lives in `domain` and must never import `data` or `presentation`
  - [x] Subtask 3.3: Sort any list inputs (`versions`, `logs`) internally before use, even though this story only ever has one version and at most one log per day — establishes the AD-4 ordering-independence guarantee from the start rather than retrofitting it
  - [x] Subtask 3.4: When resolving which Version governs a date, check that Version's `isPaused` field: if `true`, the date contributes zero eligible days (AD-4's pause-awareness rule). This story's own goal is never paused (no UI to pause it yet), so this branch is unreachable in practice here, but the check must exist now — Epic 2 Story 2.2 starts setting `isPaused = true` and depends on `evaluate()` already handling it correctly rather than retrofitting this logic later.
- [x] Task 4: GoalService — sole writer (AC: #2, #4, #5)
  - [x] Subtask 4.1: Create `lib/domain/services/goal_service.dart` — `GoalService` with a `createGoal(...)` use-case that constructs one `Goal` + one `GoalVersion` and persists both via the domain-defined `GoalRepository`/`GoalVersionRepository` interfaces inside a single transaction (AD-6, AD-3, Transaction atomicity)
  - [x] Subtask 4.2: Add a `logBoolean(goalId, date, completed)` use-case on `GoalService` that writes one `GoalLog` via `GoalLogRepository` inside a transaction — this is the **only** entry point presentation code may call to write a log; no repository is called directly from `presentation` (AD-6)
  - [x] Subtask 4.3: Return `Result`/`Either`-style values from every `GoalService` use-case, never throw for expected domain failures (Data conventions)
  - [x] Subtask 4.4: Generate UUIDv4 ids for `Goal`/`GoalVersion`/`GoalLog` at creation time inside `GoalService`, not in presentation or data layers (Data conventions)
- [x] Task 5: Domain repository interfaces (AC: #2, #4)
  - [x] Subtask 5.1: Define `GoalRepository`, `GoalVersionRepository`, `GoalLogRepository` abstract interfaces in `lib/domain/services/` (or a `repositories`-named file within `domain/services/` — the Structural Seed places repository interfaces under `domain/services/`, not a separate `domain/repositories/` folder), each domain-level, Drift-agnostic
- [x] Task 6: Drift schema and data-layer implementation (AC: #2, #5)
  - [x] Subtask 6.1: Create `lib/data/drift/` — define Drift tables for `GOAL`, `GOAL_VERSION`, `GOAL_LOG` exactly matching the ER diagram's columns, including `GOAL_VERSION.isPaused` (`BOOLEAN NOT NULL DEFAULT FALSE`) (id, goalId FK, dates as `TEXT` ISO-8601 date-only, no timezone-aware `DateTime` column types) (AD-3, Data conventions, NFR-3)
  - [x] Subtask 6.2: Do **not** create `CHEAT_DAY` or `BLACKOUT_DATE` tables in this story — those arrive in Story 1.6 and Epic 2 Story 2.4 respectively
  - [x] Subtask 6.3: Implement `DriftGoalRepository`, `DriftGoalVersionRepository`, `DriftGoalLogRepository` in `lib/data/repositories/` implementing the domain interfaces, using Drift transactions for every multi-statement write GoalService requests (Transaction atomicity)
  - [x] Subtask 6.4: Wire the generated Drift database as a singleton accessible only via a Riverpod provider (never a global/static accessor) (AD-2)
- [x] Task 7: Riverpod provider wiring — composition root (AC: #2, #3, #4)
  - [x] Subtask 7.1: Create `lib/presentation/providers/` providers (using `@riverpod` code-gen) exposing: the Drift database instance, each repository implementation bound to its domain interface, `GoalService`, and the `evaluate()` function's call sites needed by Day View
  - [x] Subtask 7.2: Ensure no `BuildContext`-coupled domain access anywhere and no singleton/service-locator pattern (AD-2)
- [x] Task 8: Presentation — first-run empty state, Day View, goal-row (AC: #1, #3, #4, #6)
  - [x] Subtask 8.1: Build the Dashboard/Today screen's first-run empty state per UX-DR26: no login/account step, straight to an empty state prompting Goal creation
  - [x] Subtask 8.2: Build `lib/presentation/screens/day_view.dart` (or equivalent) satisfying FR-21: tap any calendar date to view/log that day's eligible goals; for this story only "today" needs to be reachable, but build the screen to accept an arbitrary date parameter since Story 1.10 will add full calendar navigation into it
  - [x] Subtask 8.3: Build the reusable `lib/presentation/components/goal_row.dart` implementing the `goal-row` component spec exactly: status dot + goal name + "Done" label for Boolean goals (UX-DR7); no inline Cheat Day/Blackout iconography at row level (not applicable yet, but keep the component shape clean for later stories to extend)
  - [x] Subtask 8.4: Build the reusable `lib/presentation/components/status_cell.dart` (or `status_badge.dart`) implementing `status-cell`/`status-badge` tokens: fixed-size square, `rounded.sm`, one status-color fill, compact glyph (✓ for success at minimum in this story; other glyphs land as later stories introduce those states), screen-reader label (UX-DR6)
  - [x] Subtask 8.5: Wire tap-to-mark-done on the goal row to call `GoalService.logBoolean` via its Riverpod provider, and have the row's status re-render from a fresh `evaluate()` call, not a locally toggled boolean (AD-4, FR-13)
  - [x] Subtask 8.6: Apply only the base tokens from DESIGN.md — colors (`bg-base`, `bg-surface`, `text-primary/secondary/muted`, `border-hairline`, `accent`, the five status colors), typography roles, the spacing scale (`spacing.1`–`spacing.7`), `button-primary`/`button-secondary` — no ad hoc hex colors or one-off spacing values anywhere in this story's screens (UX-DR1–5, UX-DR10)
- [x] Task 9: Data-loss bound verification (AC: #5)
  - [x] Subtask 9.1: Confirm the `GoalService.logBoolean` write path is a single Drift transaction such that a process kill before commit leaves zero partial rows, and a kill after commit leaves the row fully intact (Transaction atomicity, FR-19, NFR-7)
  - [x] Subtask 9.2: Add a widget/integration test or documented manual test procedure simulating a kill-before-commit to confirm no partial GoalLog/GoalVersion row is ever persisted
- [x] Task 10: Testing (AC: all)
  - [x] Subtask 10.1: Unit-test `evaluate()`'s narrow Story-1.1 case in `test/domain/evaluator/evaluate_test.dart`: Daily + every-day + Boolean + Exactly-1, covering not-yet-logged (Pending or Empty per this story's scope — note: full Pending/Red certainty semantics are Story 1.8; for this story a logged day is Success and an unlogged eligible day should not be misrepresented as Success) and logged-done (Success)
  - [x] Subtask 10.2: Unit-test `GoalService.createGoal` and `GoalService.logBoolean` including the single-transaction guarantee (mock/fake repository verifying no partial writes)
  - [x] Subtask 10.3: Widget-test the empty-state Dashboard, the Day View goal-row rendering, and the tap-to-mark-done interaction end-to-end against a fake/in-memory repository

## Dev Notes

- **This is the foundation story for the entire epic and app.** Every later Epic 1 story builds directly on the entities, `evaluate()` skeleton, `GoalService`, Drift schema, and component library this story creates. Do not diverge from the class/file names chosen here — later stories reference them by these exact names.
- **AD-1 (layering):** `domain/` (entities, evaluator, services) must have zero imports of Flutter or Drift packages. `data/` and `presentation/` depend on `domain/`; `domain/` depends on neither. Only provider-wiring code in `presentation/providers/` may reference concrete `data/` implementations (the composition root).
- **AD-2 (Riverpod):** every cross-layer dependency (repositories, `GoalService`, the Drift database instance) must be exposed via `@riverpod` code-gen providers. No `BuildContext`-coupled domain access; no singleton/service-locator anywhere, including no static `Database.instance`-style accessors.
- **AD-3 (Drift):** Drift is the only persistence for Goal/Version/Log data. Do not reach for `shared_preferences` for anything in this story — that's reserved for week-start/reminder settings (not touched until later epics/stories).
- **AD-4 (pure evaluator contract):** build the evaluator function now as the seed of the eventual signature `DayStatus evaluate({Goal goal, List<GoalVersion> versions, List<GoalLog> logs, List<CheatDay> cheatDays, List<BlackoutDate> blackoutDates, DateTime date})`. This story only needs to correctly handle Daily/every-day/Boolean/Exactly-1, but the function must already: take no I/O, import nothing from Flutter/Drift, be fully deterministic, and sort any list inputs internally rather than trusting caller order. Story 1.3 will substantially expand this function's period-type handling — do not scatter a second evaluation code path anywhere in `presentation` or `data` "just for this story's simple case." There must be exactly one evaluator entry point from day one.
- **AD-6 (GoalService as sole writer):** all Goal/Version/Log writes in this story — goal creation and boolean logging — must route through `GoalService`. No screen, provider, or repository call in `presentation` writes a `GoalVersion` or `GoalLog` directly. This rule holds even though this story has no editing/versioning UI yet: `GoalService.createGoal` is still the only path that inserts the first `GoalVersion`.
- **Data conventions:** ids are UUIDv4 strings, generated inside `GoalService`. Dates are naive ISO-8601 date-only strings (`YYYY-MM-DD`) end to end — in entities, in Drift columns, and as `evaluate()`'s `date` input conceptually (represent as a date-only value; do not introduce timezone-aware `DateTime` anywhere in domain or Drift schema, consistent with NFR-3). Domain/use-case failures are `Result`/`Either`-style returns, not thrown exceptions.
- **Transaction atomicity:** the `createGoal` write (Goal + GoalVersion) and the `logBoolean` write (GoalLog) must each be single Drift transactions. This is what backs FR-19/NFR-7's "only the one in-flight entry can ever be lost" guarantee — verify explicitly with a test, don't just assume Drift's transaction API is sufficient without confirming usage.
- **UX-DR1–5 (tokens):** use only the color/typography/rounded/spacing tokens defined in `DESIGN.md`'s front-matter and Components section. Do not introduce any new color, radius, or spacing value not already named there.
- **UX-DR6 (`status-cell`):** fixed-size square, `rounded.sm`, one status-color fill, a compact glyph, and a screen-reader label. This story only needs the Success glyph (✓) rendering correctly; the other four states (fail/cheat/empty/pending glyphs ✕/C/dash/ellipsis) are exercised by later stories (1.4, 1.8) but the component should be built generically over the whole `DayStatus.status` enum now rather than hardcoding a single-state renderer that must be rewritten later.
- **UX-DR7 (`goal-row`):** status dot + goal name + "Done" label for Boolean goals; no inline Cheat Day/Blackout iconography at row level. Build this as the one shared row component — Stories 1.2 onward (Counter goals) extend it with a progress bar + fraction variant rather than creating a second row component.
- **UX-DR10 (buttons):** exactly two button tiers exist system-wide, `button-primary` and `button-secondary`. Whatever "create a goal" affordance this story needs on the empty-state screen must use `button-primary` — do not invent a third tier.
- **UX-DR26 (first-run empty state):** no login/account step at all; straight to Dashboard showing an empty-state prompt. This is the very first screen a fresh install shows.
- **Structural seed compliance:** folder names must be exactly `lib/domain/{entities,evaluator,services}`, `lib/data/{drift,repositories,cache,io,widget_bridge}`, `lib/presentation/{screens,components,providers}`, `lib/platform/{android,ios}`, `test/domain/`. Even though `data/cache`, `data/io`, `data/widget_bridge`, and `lib/platform/*` have no content yet in this story, create the empty directories (or a `.gitkeep`/placeholder) now so the seed is visibly complete and later epics don't have to invent folder names — Epic 1 Story 1 is explicitly named as the story that establishes this seed (Architecture Structural Seed intro line).
- **Stack versions:** the Architecture's Stack table is a seed, not a lockfile — re-verify `flutter_riverpod ^3.4.2`, `riverpod_generator`/`riverpod_annotation ^4.0.8`/`^4.0.6`, `drift`/`drift_flutter 2.32.0+` against current `pub.dev` at `flutter pub add` time and record the actually-resolved versions in this story's Completion Notes / File List (`pubspec.lock`). Do not add `flutter_local_notifications` or `home_widget` in this story — they belong to Epic 4 and Epic 5 respectively and have no purpose yet.
- **Anti-duplication guidance:** this story is the *first* implementation of `evaluate()`, `GoalService`, the Drift schema, and the `status-cell`/`goal-row` components — there is nothing earlier to reuse. But be deliberate about building these as the single reusable implementation every later Epic 1/2/3 story will extend, not as a "quick and dirty daily-only version" that gets thrown away. In particular: do not hardcode "Daily period" logic directly into a screen or provider — route everything through the one `evaluate()` function, even for this simple case, so Story 1.3's period-type expansion is additive.
- **Testing standards:** `evaluate()` is exactly the kind of correctness-critical logic NFR-6 calls out — it must be unit-tested in `test/domain/evaluator/`, independent of any Flutter/widget test harness (pure Dart unit tests only, per AD-4's "no Flutter" constraint — the test itself should not need `flutter_test`'s widget harness, just plain `test` package or `flutter_test`'s non-widget assertions). `GoalService` use-cases are unit-tested against a fake/in-memory repository implementation to verify transactional behavior. Widget tests cover the empty state, Day View rendering, and the tap-to-log interaction.

### Project Structure Notes

- This story **creates** the structural seed; there is no pre-existing structure to align with or deviate from. All folder names above must match the Architecture's Structural Seed block verbatim.
- `domain/services/` is the correct location for both `GoalService` and the repository/`CacheWriter` interface definitions per the Structural Seed comment ("`GoalService` (AD-6), `StatsService` (AD-8), repository + CacheWriter interfaces") — do not create a separate `domain/repositories/` folder; the seed explicitly nests these under `services/`.
- `data/cache/`, `data/io/`, `data/widget_bridge/`, and `platform/{android,ios}` should exist as empty/placeholder directories after this story even though no story populates them yet — this keeps the seed structurally complete from Story 1.1 forward per the architecture's framing of Epic 1 Story 1 as the seed-establishing story.
- No conflicts detected between epics.md, architecture, and UX for this story's scope.

### References

- [Source: docs/epics.md#Story 1.1: Scaffold the App and Track a Simple Daily Goal]
- [Source: docs/epics.md#Requirements Inventory] (FR-1, FR-4, FR-13, FR-19, FR-21)
- [Source: docs/prd/4-features.md#FR-13: Boolean Entry]
- [Source: docs/prd/4-features.md#FR-19: Data-Loss Bound]
- [Source: docs/prd/4-features.md#FR-21: Day View]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-1 — Layered/Hexagonal Paradigm]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-2 — Riverpod for State & Dependency Injection]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-3 — Drift as Sole Local Persistence]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4 — Pure Evaluator Contract]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6 — GoalService Owns All Version and Log Writes]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Consistency Conventions]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Stack]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Core-entity relationships]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Colors] (UX-DR1)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Typography] (UX-DR2)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Shapes] (UX-DR3)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Layout & Spacing] (UX-DR4)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Elevation & Depth] (UX-DR5)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components] (UX-DR6, UX-DR7, UX-DR10 — status-cell, goal-row, button-primary/secondary)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Foundation] (UX-DR26 — first-run, no login)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#State Patterns] (empty states)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `flutter --version`: Flutter 3.47.2 • channel stable • Dart 3.13.2
- Resolved pinned-seed dependency versions (re-verified against pub.dev at `flutter pub add` time, recorded in `pubspec.lock`): `flutter_riverpod: 3.4.2`, `riverpod_annotation: 4.0.6`, `riverpod_generator: 4.0.8` (dev), `build_runner: 2.16.0` (dev), `drift: ^2.34.3`, `drift_flutter: ^0.3.1` (Architecture Stack table's "2.32.0+" referred to `drift` itself; `drift_flutter` is versioned independently), `drift_dev: 2.34.5` (dev), `path_provider: ^2.1.6`, `path: ^1.9.1`, `uuid: 4.6.0`.
- Environment blockers hit and resolved during this story (none are code defects; noted here since they'll recur for future stories on this machine):
  1. Flutter SDK was installed at `D:\Program Files\flutter_windows_3.47.2-stable` — the space in "Program Files" broke `build_runner`'s native-asset hook invocation and `flutter test`'s package resolution. Fixed by moving the SDK to `D:\flutter_windows_3.47.2-stable` (no space) and re-running `flutter pub get`.
  2. Windows "Smart App Control" blocked first-run execution of freshly-built native binaries (`gen_snapshot.exe` for AOT build scripts, and a freshly-built `sqlite3.dll` under `build/native_assets` for a real-Drift-database integration test). Worked around AOT via `build_runner`'s `--force-jit` flag for gen_snapshot; the native-SQLite integration test was not achievable in this environment and was replaced with an in-memory fake-based test plus a documented manual procedure (see Subtask 9.2 below).
  3. This project lives inside a OneDrive-synced folder; OneDrive intermittently locks `.dart_tool/build/generated` while `build_runner` is deleting it. Workaround: `rm -rf .dart_tool/build/generated` immediately before each `dart run build_runner build --force-jit` invocation.
- `flutter build windows --debug` succeeds; the built `tracker.exe` was run and manually verified end-to-end by the user (empty state → Create Goal → name entry → goal-row renders with "Done" label → tap marks it Success/green).

### Completion Notes List

- Implemented the full structural seed (`lib/domain/{entities,evaluator,services}`, `lib/data/{drift,repositories,cache,io,widget_bridge}`, `lib/presentation/{screens,components,providers}`, `lib/platform/{android,ios}`, `test/domain/`) plus `test/presentation/`.
- Domain layer: `Goal`, `GoalVersion`, `GoalLog`, `DayStatus` entities (`rule_values.dart` centralizes the string constants for this story's Daily/every-day/Boolean/Exactly-1 case); pure `evaluate()` covering the narrow case plus pause-awareness and version-boundary lookup, sorted internally; `GoalService` as sole writer with `Result`/`Failure` returns; `GoalRepository`/`GoalVersionRepository`/`GoalLogRepository`/`TransactionRunner` domain interfaces.
- Data layer: Drift tables (`Goals`/`GoalVersions`/`GoalLogs`, row classes suffixed `Row` to avoid colliding with same-named domain entities) wired through `drift_flutter`'s `driftDatabase()`; `Drift*Repository` implementations converting between Drift rows and domain entities; `DriftTransactionRunner` wrapping `db.transaction()`.
- Presentation: Riverpod composition root (`database_provider`, `repository_providers`, `goal_service_provider`, `goal_data_providers`); design tokens ported verbatim from `DESIGN.md`; `StatusCell` built generically over all five `DayStatusValue` states (only `success`/`pending`/`empty` are exercised by this story's data, but `fail`/`cheat` render correctly already); `GoalRow`; a deliberately minimal `CreateGoalScreen` (name field only, since Boolean/Daily/every-day/Exactly-1 is the only supported combination until Story 1.9's guided wizard); `DayViewScreen` doubling as the first-run empty-state Dashboard (no separate Dashboard/Calendar split exists yet).
- Data-loss bound (AC5): both `createGoal` and `logBoolean` route through `TransactionRunner.run(...)`. Automated proof is `goal_service_test.dart`'s "a kill mid-transaction leaves zero partial rows" test (fake `TransactionRunner` that snapshots/restores on throw). A real-Drift-transaction integration test was attempted (`NativeDatabase.memory()`) but blocked by this machine's Smart App Control policy (see Debug Log). Documented manual procedure in its place: run `tracker.exe`, create a goal, tap its row to log it, force-kill the process (Task Manager / `taskkill /F /IM tracker.exe`) at varying points immediately after the tap, relaunch, and confirm the log is either fully present or fully absent — never partial — and all previously-committed data (the goal, its version) survives regardless.
- All 12 automated tests pass (`test/domain/evaluator/evaluate_test.dart` ×5, `test/domain/services/goal_service_test.dart` ×4, `test/presentation/day_view_test.dart` ×3). `dart analyze lib test` is clean except 4 pre-existing `prefer_initializing_formals` info-level suggestions in `goal_service.dart` that don't apply (constructor parameter names are intentionally public while backing fields are private). `flutter build windows --debug` succeeds and the app was manually run and verified end-to-end.

### File List

- `pubspec.yaml`, `pubspec.lock` — scaffolded project + pinned dependencies
- `lib/main.dart` — app entry point, `ProviderScope`, light/dark theme from design tokens
- `lib/domain/entities/goal.dart`
- `lib/domain/entities/goal_version.dart`
- `lib/domain/entities/goal_log.dart`
- `lib/domain/entities/day_status.dart`
- `lib/domain/entities/rule_values.dart`
- `lib/domain/evaluator/evaluate.dart`
- `lib/domain/evaluator/date_format.dart`
- `lib/domain/services/goal_service.dart`
- `lib/domain/services/goal_repository.dart`
- `lib/domain/services/goal_version_repository.dart`
- `lib/domain/services/goal_log_repository.dart`
- `lib/domain/services/transaction_runner.dart`
- `lib/domain/services/result.dart`
- `lib/data/drift/tables.dart`
- `lib/data/drift/database.dart`, `lib/data/drift/database.g.dart` (generated)
- `lib/data/repositories/drift_goal_repository.dart`
- `lib/data/repositories/drift_goal_version_repository.dart`
- `lib/data/repositories/drift_goal_log_repository.dart`
- `lib/data/repositories/drift_transaction_runner.dart`
- `lib/presentation/providers/database_provider.dart` (+ `.g.dart`)
- `lib/presentation/providers/repository_providers.dart` (+ `.g.dart`)
- `lib/presentation/providers/goal_service_provider.dart` (+ `.g.dart`)
- `lib/presentation/providers/goal_data_providers.dart` (+ `.g.dart`)
- `lib/presentation/components/design_tokens.dart`
- `lib/presentation/components/status_cell.dart`
- `lib/presentation/components/goal_row.dart`
- `lib/presentation/components/primary_button.dart`
- `lib/presentation/screens/day_view.dart`
- `lib/presentation/screens/create_goal_screen.dart`
- `lib/data/cache/.gitkeep`, `lib/data/io/.gitkeep`, `lib/data/widget_bridge/.gitkeep`, `lib/platform/android/.gitkeep`, `lib/platform/ios/.gitkeep` — structural seed placeholders
- `test/domain/evaluator/evaluate_test.dart`
- `test/domain/services/fakes.dart`
- `test/domain/services/goal_service_test.dart`
- `test/presentation/day_view_test.dart`
- `test/widget_test.dart` — deleted (flutter-create counter-app boilerplate, superseded by the tests above)
