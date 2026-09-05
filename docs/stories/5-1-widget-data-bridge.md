---
baseline_commit: NO_VCS
---

# Story 5.1: Widget Data Bridge

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want the app to keep a shared data container updated with each goal's precomputed status,
so that native home-screen widgets always have fresh data to render without the app needing to be open.

## Acceptance Criteria

1. **Given** a GoalLog or GoalVersion commits and `CacheWriter` (AD-7) writes the resulting `DayStatus`
   **When** the write completes
   **Then** `widget_bridge` (data layer) serializes the relevant `DayStatus` records (date, goalId/scope, status) to `home_widget`'s shared container as part of that same commit path (AD-7, FR-31)

2. **Given** the midnight-rollover job runs (FR-20) and recomputes cached status
   **When** it completes
   **Then** `widget_bridge` also updates the shared container, so widgets reflect the new day without the app needing to be reopened

3. **Given** `widget_bridge` lives in the `data` layer
   **When** it serializes `DayStatus`
   **Then** it depends only on domain-defined interfaces and contains no Flutter widget-tree code, respecting the layer boundary (AD-1)

4. **Given** zero goals are eligible today for a given widget scope
   **When** `widget_bridge` writes for that scope
   **Then** it writes an explicit empty/no-data state rather than leaving stale data from a previous day

5. **And** no widget-bridge write ever triggers a live `evaluate()` call — it only serializes what `CacheWriter` already computed (AD-7, Caching Policy — widgets are cache-only, never live evaluation)

## Tasks / Subtasks

- [x] Task 1: Define the domain-layer bridge interface (AC: 1, 2, 3, 5)
  - [x] 1.1 In `lib/domain/services/`, define an abstract `WidgetBridgeWriter` interface (mirroring the `CacheWriter` inversion pattern from AD-7/AD-3): methods to (re)write the Today/Week/Month shared-container payloads, taking only already-computed `DayStatus` values (read via the existing cache repository interface) as input — never `Goal`/`GoalLog`/`GoalVersion` raw entities and never a call into `evaluate()`.
  - [x] 1.2 Confirm the interface's method signatures accept a date/range and return `Future<void>` (or a `Result`-style type per Data conventions) with no Flutter or `home_widget` imports in `domain`.
- [x] Task 2: Implement the bridge in `lib/data/widget_bridge/` (AC: 1, 3, 4, 5)
  - [x] 2.1 Implement `WidgetBridgeWriter` using the `home_widget` package (0.9.3, data-bridging only — re-verify exact version at `flutter pub add` time per the Stack table's own caveat).
  - [x] 2.2 For each of the three scopes (today/week/month), build the JSON envelope defined in Dev Notes below by reading `DayStatus` rows from the existing cache repository (the same repository `CacheWriter`/`StatsService` already read from) for every non-archived, currently-eligible goal in that scope's date range, joined with a plain name lookup via the existing `GoalRepository` (read-only, `id` → `name` only — a metadata lookup, not a computation). Never read `GoalLog`/`GoalVersion` rows and never call `evaluate()` — the *status* for every cell must come exclusively from the cache; only the display `goalName` string is looked up from the `Goal` entity itself, since `DayStatus` does not carry a name.
  - [x] 2.3 Each write is a full replace of that scope's shared-container key (not an incremental patch) — read the full current scope's cache state, build a fresh envelope, and overwrite the key each time, so no stale per-goal entries can survive from a previous day or a since-archived goal.
  - [x] 2.4 When a scope's cell set is empty (zero eligible goals for the range), still write a valid envelope with `"isEmpty": true` and `"cells": []` — never skip the write and never leave the previous payload in place.
  - [x] 2.5 After each successful `HomeWidget.saveWidgetData` call for a scope, call `HomeWidget.updateWidget(androidName: ..., iOSName: ...)` to request an OS-level widget refresh. This call is a safe no-op until Story 5.2 registers the native widget providers — implement it now so 5.2/5.3 don't need to touch this write path again.
- [x] Task 3: Wire the bridge into existing commit/rollover paths (AC: 1, 2)
  - [x] 3.1 Locate the existing domain use-case(s) that invoke `CacheWriter` after a `GoalLog` write commits and after a `GoalVersion` write commits (established in Epic 3 Story 3.1 / AD-7). Immediately after each successful `CacheWriter` invocation, invoke `WidgetBridgeWriter` for all three scopes (today/week/month), rebuilding each fully per Task 2.3.
  - [x] 3.2 Locate the midnight-rollover job (FR-20, Epic 1 Story 1.11) and, immediately after it recomputes cached status via `CacheWriter`, invoke `WidgetBridgeWriter` for all three scopes the same way.
  - [x] 3.3 Do **not** wrap the `WidgetBridgeWriter` calls inside the same Drift transaction as the triggering `GoalLog`/`GoalVersion`/cache write — `home_widget`'s shared container (Android `SharedPreferences`, iOS `UserDefaults` App Group suite) is not Drift-backed and cannot participate in a SQL transaction. Invoke it as a best-effort step immediately after the transaction commits successfully; a failure to update the shared container must never roll back or block the already-committed domain write.
- [x] Task 4: Guardrail tests (AC: 3, 5)
  - [x] 4.1 Unit-test `WidgetBridgeWriter`'s data-layer implementation against fixture `DayStatus` cache rows (mock the cache repository), asserting the exact JSON envelope shape per scope, including the empty-state case.
  - [x] 4.2 Add a test/fake double for the domain evaluator that throws if invoked, and exercise the full bridge write path through it to prove no code path in `widget_bridge` (or the use-cases that call it) reaches `evaluate()`.
  - [x] 4.3 Mock the `home_widget` platform channel in tests (no real device/simulator required) to verify `saveWidgetData`/`updateWidget` are called with the expected keys and payloads.
- [x] Task 5 (native, Android — prerequisite only, no widget UI in this story): Confirm shared storage access (AC: 1, 2)
  - [x] 5.1 Confirm `home_widget`'s default Android storage (a `SharedPreferences` file the plugin manages, conventionally readable by an `AppWidgetProvider`/Glance widget via the same file name) requires no additional `AndroidManifest.xml` entries for the data-bridging side alone. Do not add an `AppWidgetProvider`/Glance widget class yet — that is Story 5.2's scope.
- [x] Task 6 (native, iOS — prerequisite only, no widget UI in this story): Configure the App Group (AC: 1, 2)
  - [x] 6.1 Add an App Group capability + entitlement to the main app's Xcode target (e.g. `group.com.<bundleid>.tracker`) so a future WidgetKit extension (Story 5.2) can read the same `UserDefaults` suite `home_widget` writes to. This is Xcode project/entitlement configuration only — do not create a Widget Extension target in this story.
  - [x] 6.2 Call `HomeWidget.setAppGroupId('<the App Group id>')` once during app/Dart-side bridge initialization so all `saveWidgetData`/`updateWidget` calls target the shared App Group container.

## Dev Notes

- **Cache-only rule (the rule most likely to be broken by accident):** `widget_bridge` is a pure serializer. Every `status` value it writes comes exclusively from `DayStatus` rows that `CacheWriter` already computed and persisted (via the existing cache repository interface) — it must never call `evaluate()` and never read `GoalLog`/`GoalVersion` rows to derive a status itself, and it never re-derives a streak/rollup (that's `StatsService`'s job, AD-8, and out of scope here). The one permitted read outside the cache is a plain `id → name` lookup via the existing `GoalRepository`, needed only because `DayStatus` doesn't carry a display name and UX-DR18 requires the goal's name in the widget — this is metadata lookup, not evaluation, and does not weaken the cache-only guarantee: the *status* is never anything but a direct cache read. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-7] [Source: docs/addendum/caching-policy-requirements-v2md-231.md]
- **Layer boundary (AD-1):** `widget_bridge` lives in `lib/data/widget_bridge/`. It depends only on domain-defined interfaces (the cache repository interface, the new `WidgetBridgeWriter` interface which domain defines and data implements — same inversion pattern AD-3 uses for persistence and AD-7 uses for `CacheWriter`). It must contain zero Flutter widget-tree code — this story produces no UI, only data serialization. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Design Paradigm] [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-1]
- **Structural seed locations:** `lib/data/widget_bridge/` (the implementation), `lib/domain/services/` (the new `WidgetBridgeWriter` interface, alongside `GoalService`/`StatsService`/`CacheWriter` interface). `lib/platform/android/` and `lib/platform/ios/` are the native widget UI locations reserved for Story 5.2 — this story does not add any widget UI files there, only the minimal native prerequisite config in Tasks 5–6 (Android: none needed; iOS: App Group entitlement). [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed]
- **Trigger points (exactly three, no others):** (1) after a `GoalLog` commit + its `CacheWriter` write, (2) after a `GoalVersion` commit + its `CacheWriter` write, (3) after the midnight-rollover job recomputes cache (FR-20). All three are existing hook points from Epic 3 Story 3.1 (`CacheWriter` invocation) and Epic 1 Story 1.11 (midnight rollover) — this story adds a `WidgetBridgeWriter` call immediately following each, it does not introduce new commit paths. [Source: docs/epics.md#Story 5.1] [Source: docs/epics.md#Story 3.1] [Source: docs/epics.md#Story 1.11]
- **Not transactional with Drift:** the shared container is platform-native storage (Android `SharedPreferences`, iOS `UserDefaults` App Group suite), not a Drift table, so it cannot be included in the same SQL transaction as the triggering write. Treat the bridge write as best-effort immediately after commit — never block or roll back the already-committed domain write if the bridge write fails.
- **Full-scope-rebuild rule:** because a single log/version commit can shift status across many cells (e.g. a rolling-window goal, or a Version boundary affecting a whole period), every trigger rebuilds and fully overwrites all three scope payloads (today/week/month) from current cache state — never an incremental patch to previously-written JSON. This is also what makes AC4's empty-state guarantee correct: a scope that becomes empty (e.g. the day's only goal gets archived) is always freshly rewritten with `isEmpty: true`, never left stale.
- **No-data-state requirement (AC4):** a scope with zero relevant cells still gets a full envelope write (`isEmpty: true`, `cells: []`), never a skipped write. Stale data from a previous day rendering in a widget is an explicit failure mode this story must prevent.
- **The exact shared-container data shape — this is the contract Story 5.2 and 5.3 consume, do not diverge from it.** Architecture mandates only the minimum field set (`date`, `goalId`/scope, `status`) and explicitly defers the exact serialization format to implementation [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Deferred]. This story fixes that format as follows, and it is binding for 5.2/5.3:

  Three `home_widget` shared-container keys, each holding a JSON-encoded string value (write via `HomeWidget.saveWidgetData<String>(key, jsonEncode(envelope))`):
  - `today_widget_data`
  - `week_widget_data`
  - `month_widget_data`

  Common envelope shape for all three keys:
  ```json
  {
    "scope": "today",
    "generatedAt": "2026-08-29",
    "rangeStart": "2026-08-29",
    "rangeEnd": "2026-08-29",
    "isEmpty": false,
    "cells": [
      {
        "date": "2026-08-29",
        "goalId": "3f1b2c4a-...-uuid",
        "goalName": "Drink Water",
        "status": "success"
      }
    ]
  }
  ```
  - `scope` is one of `"today" | "week" | "month"`, fixed per key.
  - `generatedAt` is the naive ISO-8601 date-only string (per Data conventions) for the local day the bridge computed this payload on — the widget's own freshness marker.
  - `rangeStart`/`rangeEnd`: for `today_widget_data` both equal `generatedAt`; for `week_widget_data` they are the Week-Start-Setting-aware week boundary (FR-24) containing `generatedAt`; for `month_widget_data` they are the first/last date of the calendar month containing `generatedAt`.
  - `isEmpty` is `true` iff `cells` is `[]` — an explicit, unambiguous no-data signal distinct from "the field is merely absent."
  - `cells` is a flat array, one entry per `(date, goalId)` pair relevant to the scope: for `today_widget_data`, one entry per goal eligible today; for `week_widget_data`/`month_widget_data`, one entry per goal per eligible date in the range (mirroring in-app Week/Month's per-goal-per-day status per FR-22/FR-23). Native widget code (Story 5.2) selects/truncates which cells it actually renders based on its size class — the bridge always writes the full set, it does not pre-truncate for a guessed widget size.
  - `status` is exactly one of the five `DayStatus` values, spelled `"success" | "fail" | "cheat" | "empty" | "pending"` — the same five states as the in-app `status-cell` vocabulary (UX-DR6), no widget-only renaming or a 6th state.
  - `goalName` is the raw goal name string; no truncation happens in the bridge (that is a rendering/native-layer concern for whatever the widget's density allows, Story 5.2).
- **`HomeWidget.updateWidget` call:** made once per scope after each successful `saveWidgetData` for that scope, using whatever Android/iOS provider names Story 5.2 will register. Passing names for widget providers that don't exist yet (this story) is a safe no-op in `home_widget`; do not defer adding this call to Story 5.2 — wiring it here means 5.2 only needs to register the receiving provider, not touch this write path.
- **Testing standards:** domain-layer interface has no I/O to test directly (it's an abstract contract) but its shape should be covered by a compile-time usage test from the data-layer implementation. The data-layer `WidgetBridgeWriter` implementation is unit-tested with fixture cache rows (via a fake/mock cache repository), asserting exact JSON shape per scope including the empty-state envelope, and with the `home_widget` platform channel mocked (standard Flutter plugin test pattern — no physical device or simulator needed). A dedicated test proves the bridge path never reaches a throwing fake `evaluate()`, guarding AC5 structurally rather than just by code review. Mirrors NFR-6's "correctness as core quality bar" applied to this story's own narrow contract. [Source: docs/epics.md#Requirements Inventory (NFR-6)]

### Project Structure Notes

- Matches the structural seed exactly: `lib/domain/services/widget_bridge_writer.dart` (interface, new) alongside existing `lib/domain/services/` (`GoalService`, `StatsService`, cache/`CacheWriter` interfaces); `lib/data/widget_bridge/` (implementation, new — the folder already exists as an empty structural-seed placeholder per Epic 1 Story 1's scaffolding). [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed]
- No `lib/platform/android/` or `lib/platform/ios/` widget-UI files are created in this story — only the Task 5/6 native prerequisite configuration (Android: none; iOS: App Group entitlement in the Xcode project, not a new source file under `lib/platform/ios/`). Actual native widget UI source files land in Story 5.2. No variance from the structural seed detected.
- No new Drift tables are introduced by this story — it reads existing cache rows via the existing cache repository, it does not define new persistence.

### References

- [Source: docs/epics.md#Story 5.1]
- [Source: docs/epics.md#Epic 5]
- [Source: docs/epics.md#Epic 3] (CacheWriter/StatsService context this story builds on)
- [Source: docs/epics.md#Requirements Inventory] (FR-31, AD-1, AD-3, AD-7, AD-8, Data conventions, Transaction atomicity, Structural seed, Stack)
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-1]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-7]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Stack] (home_widget 0.9.3, data-bridging only — re-verify at build time)
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Deferred] (shared-container serialization format explicitly left open, fixed by this story)
- [Source: docs/addendum/caching-policy-requirements-v2md-231.md]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components] (status-cell five-state vocabulary, reused verbatim in the `status` field)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5

### Debug Log References

### Completion Notes List

Ultimate context engine analysis completed - comprehensive developer guide created

- Added the `home_widget: ^0.9.3` dependency (`flutter pub add home_widget`), matching the Stack table's pinned version exactly.
- Defined `WidgetBridgeWriter` (domain interface, `lib/domain/services/widget_bridge_writer.dart`) with a single `writeAll(DateTime today)` entry point — one call always rebuilds all three scopes together, which structurally enforces the "full-scope-rebuild rule" (a caller can never accidentally request a partial rebuild).
- Implemented `WidgetBridgeWriterImpl` (`lib/data/widget_bridge/widget_bridge_writer_impl.dart`). It depends only on `GoalRepository`, `GoalVersionRepository`, and `StatusCacheRepository` — no `GoalLogRepository`/`BlackoutDateRepository`/`CheatDayRepository` and no import of `evaluate.dart`, which makes calling `evaluate()` from this class structurally impossible (Task 4.2's guardrail), not just a code-review convention.
  - Goal eligibility per scope mirrors the existing Week View/Month View precedent exactly: excludes `archived`/`expired` lifecycle goals (`resolveLifecycleStatus`), and excludes any `(goal, date)` cell that falls under a paused `GoalVersion` (`isPausedOn`) — both read from the same helpers those screens already use, so the widget can never disagree with the in-app calendar about which cells exist.
  - `today_widget_data` additionally excludes `DayStatusValue.empty` cells (mirrors `StatsService.todayProgress`'s "eligible today" filter); `week_widget_data`/`month_widget_data` do not (mirrors Week/Month View, which render every non-paused day regardless of status, including Empty). This asymmetry is intentional and documented inline — see Dev Notes discussion in this record.
  - A cache miss (`StatusCacheRepository.getStatus` returns `null`) is skipped, never falling back to a live `evaluate()` call — satisfies AC5 for the (expected-rare) case of a date `CacheWriter` hasn't written yet.
- Wired `WidgetBridgeWriter` into `GoalService` (Task 3): every method that already calls the private `_refreshCache` helper (`createGoal`, `logBoolean`, `logCounter`, `markDnf`'s success path, and `_writeVersionSegment`'s success path — the shared helper behind `editGoalVersion`/`pauseGoal`/`resumeGoal`) now also triggers `_syncWidgetBridge()` immediately after its own `_transactionRunner.run(...)` call returns — i.e. after the transaction has already committed, never inside it, satisfying Task 3.3's "not transactional with Drift" requirement. `_syncWidgetBridge()` wraps the call in try/catch so a shared-container write failure can never surface to or roll back the caller of an already-committed domain write.
  - The midnight-rollover job (`MidnightRolloverWatcher`, Story 1.11) needed no separate wiring: per `GoalService._refreshCache`'s own doc comment, the rollover's entire cache-write obligation is already just a regular `logCounter` call, which this story's hook already covers.
  - **Important correction made during implementation:** the bridge sync is invoked via `unawaited(_syncWidgetBridge())`, not `await`ed. An initial `await`ed version passed its own unit tests but broke ~10 existing presentation widget tests across `day_view_test.dart`, `week_view_test.dart`, `month_view_test.dart`, and others — every test that creates/logs a goal through `GoalService` and then immediately asserts on the rendered widget tree. Awaiting the bridge sync added extra async hops (repository reads + a `MethodChannel` round trip) before `createGoal()`/`logBoolean()`/etc. returned, and those tests' existing `pump()` counts weren't written to wait for that. Making the call fire-and-forget matches the story's own requirement more precisely anyway ("a failure to update the shared container must never roll back or **block** the already-committed domain write") and fixed all the regressions with no test changes needed elsewhere.
- Confirmed Task 5 (Android) needs no code change: inspected the `home_widget` 0.9.3 plugin's own `AndroidManifest.xml` (just declares its package, no components) — its `saveWidgetData`/`updateWidget` calls use a plain `SharedPreferences` file with no manifest registration required for the data-bridging side alone.
- Completed Task 6 (iOS) as Xcode project/entitlement configuration only: added `ios/Runner/Runner.entitlements` declaring the `com.apple.security.application-groups` capability for `group.com.panda.tracker.tracker` (the app's bundle id is `com.panda.tracker.tracker`), wired `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;` into all three Runner target build configurations (Debug/Release/Profile) in `project.pbxproj`, and added `HomeWidget.setAppGroupId(...)` via a new `widgetBridgeInitializerProvider` invoked once from `main.dart`. **Caveat:** this development environment is Windows with no Xcode/macOS available, so the entitlement/pbxproj edit could not be verified by actually opening the project in Xcode or building for iOS — it should be spot-checked by opening `ios/Runner.xcodeproj` on macOS before Story 5.2 adds the WidgetKit extension target.
- Guardrail tests (Task 4): `test/data/widget_bridge/widget_bridge_writer_impl_test.dart` — 7 tests covering the exact envelope shape, the AC4 empty-state envelope, the cache-miss-is-skipped rule, archived/expired exclusion, paused-date exclusion, the today-vs-week/month Empty-status asymmetry, and the mocked `home_widget` `MethodChannel` calls (`saveWidgetData` for all 3 keys, `updateWidget` once per scope). The "never reaches `evaluate()`" guardrail (Task 4.2) is proved by seeding the cache with a status a live `evaluate()` call could not have produced for the given (log-free) fixture, combined with the structural argument above (no `GoalLogRepository`/`evaluate()` import at all) — free top-level functions in this codebase aren't swappable via DI the way a repository interface is, so a literal "throwing fake evaluator" isn't constructible; this is the closest behaviorally-provable equivalent.
- Updated `test/domain/services/fakes.dart` with `InMemoryWidgetBridgeWriter` (records calls, no real platform channel) and updated the 5 existing test files that construct `GoalService` directly to pass the new required `widgetBridgeWriter` parameter — no behavioral changes to those suites.
- Full regression suite: 308 tests pass (`flutter test`); `flutter analyze` reports only the same pre-existing `prefer_initializing_formals` style infos already present on sibling files (`cache_writer_impl.dart`, `stats_service.dart`), nothing new.

### File List

- `pubspec.yaml` (modified — added `home_widget: ^0.9.3`)
- `pubspec.lock` (modified — dependency resolution)
- `lib/domain/services/widget_bridge_writer.dart` (new)
- `lib/data/widget_bridge/widget_bridge_writer_impl.dart` (new)
- `lib/domain/services/goal_service.dart` (modified — wired `WidgetBridgeWriter` into `createGoal`/`logBoolean`/`logCounter`/`markDnf`/`_writeVersionSegment`)
- `lib/presentation/providers/widget_bridge_provider.dart` (new)
- `lib/presentation/providers/widget_bridge_provider.g.dart` (new, generated)
- `lib/presentation/providers/goal_service_provider.dart` (modified — injects `widgetBridgeWriterProvider`)
- `lib/main.dart` (modified — watches `widgetBridgeInitializerProvider`)
- `ios/Runner/Runner.entitlements` (new)
- `ios/Runner.xcodeproj/project.pbxproj` (modified — App Group entitlement wiring)
- `test/data/widget_bridge/widget_bridge_writer_impl_test.dart` (new)
- `test/domain/services/fakes.dart` (modified — added `InMemoryWidgetBridgeWriter`)
- `test/domain/services/goal_service_test.dart` (modified — constructor param)
- `test/domain/services/cache_writer_test.dart` (modified — constructor param)
- `test/domain/evaluator/goal_service_cheat_day_test.dart` (modified — constructor param)
- `test/domain/evaluator/goal_service_multi_version_test.dart` (modified — constructor param)
- `test/domain/evaluator/pause_resume_evaluation_test.dart` (modified — constructor param)

## Change Log

- 2026-08-30: Implemented Story 5.1 (Widget Data Bridge) — domain `WidgetBridgeWriter` interface, `home_widget`-backed data-layer implementation, wired into every `GoalService` commit path (best-effort, non-blocking), Android storage confirmed to need no manifest changes, iOS App Group entitlement configured. Guardrail tests added; full suite green (308 passing).
