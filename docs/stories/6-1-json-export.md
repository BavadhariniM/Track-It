---
baseline_commit: NO_VCS
---

# Story 6.1: JSON Export

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to export my full app state to a single JSON file,
so that I have a portable backup of everything I've tracked.

## Acceptance Criteria

1. **Given** any amount of app data exists (Goals, Versions, Logs, Cheat Days, Blackout Dates, settings, categories, notification config)
   **When** Panda triggers Export from Settings
   **Then** a single JSON file is produced containing all of it plus metadata including a schema-version field (FR-33)

2. **Given** zero Goals exist yet
   **When** Panda triggers Export
   **Then** a valid, structurally complete JSON file is still produced with an empty `goals` array — this enables the zero-goal-import acceptance case in Story 6.2 (FR-33)

3. **Given** the export process only reads data
   **When** it runs
   **Then** it performs a read-only operation — no `GoalService` write path is ever invoked by export

4. **And** the export happens entirely offline, with no network call of any kind (NFR-1, NFR-2)

## Tasks / Subtasks

- [x] Task 1: Define the export JSON schema contract (AC: #1, #2)
  - [x] Subtask 1.1: Define top-level `meta` object: `schemaVersion` (string, current value `"1.0"`), `exportedAt` (naive ISO-8601 timestamp string, local device time per NFR-3 — no timezone offset).
  - [x] Subtask 1.2: Define top-level entity arrays mirroring the Drift schema fields exactly as specified in ARCHITECTURE-SPINE.md's `erDiagram`: `goals` (`id`, `name`, `category`, `archived`, `startDate`), `goalVersions` (`id`, `goalId`, `versionStartDate`, `evaluationPeriod`, `eligibleDaysRule`, `targetComparison`, `targetValue`, `trackingType`, `cheatDayQuota`), `goalLogs` (`id`, `goalId`, `date`, `timestamp`, `value`, `completed`, `dnfMarked`, `note`), `cheatDays` (`id`, `goalId`, `date`, `note`), `blackoutDates` (`id`, `goalId`, `date`, `reason`).
  - [x] Subtask 1.3: Define top-level `categories` array (id, name) and `settings` object (`weekStartDay`: `"monday"`|`"sunday"`, `reminderTime`: `"HH:mm"` string or null if unset) — the `shared_preferences`-backed settings outside the Drift schema (AD-3).
  - [x] Subtask 1.4: Record this exact shape as the canonical contract Story 6.2's import validator must check against field-for-field — do not let the two stories' schemas drift apart.
- [x] Task 2: Implement the exporter in `lib/data/io/` (AC: #1, #2, #3)
  - [x] Subtask 2.1: Create `json_exporter.dart` (or equivalent) that depends only on domain-defined repository interfaces (read methods only — `getAll`-style queries), never on `GoalService` or any write-capable API.
  - [x] Subtask 2.2: Assemble the in-memory export model from repository reads, serialize to a JSON string with the `meta.schemaVersion`/`meta.exportedAt` fields populated.
  - [x] Subtask 2.3: Handle the zero-Goal case explicitly: emit `"goals": []` (and correspondingly empty `goalVersions`/`goalLogs`/`cheatDays`/`blackoutDates`) rather than omitting the arrays or erroring.
  - [x] Subtask 2.4: Verify no code path in the exporter calls into `GoalService` or any repository write/insert/update/delete method — export is provably read-only.
- [x] Task 3: Wire the Settings → Export action (AC: #1, #4)
  - [x] Subtask 3.1: Add an "Export" action to the existing Settings screen (`lib/presentation/screens/`, already scaffolded by Epic 4 Story 4.1 for reminder settings) using `button-secondary` per UX-DR10 (this is not the screen's single forward action).
  - [x] Subtask 3.2: Expose the exporter through a Riverpod provider (AD-2) — no `BuildContext`-coupled domain/data access.
  - [x] Subtask 3.3: Write the resulting JSON to a single portable file via the platform file-save/share flow; confirm no network permission or call is exercised anywhere in this path (NFR-1, NFR-2).
- [x] Task 4: Tests (AC: #1, #2, #3, #4)
  - [x] Subtask 4.1: Unit test — full data set (multiple goals, versions, logs, cheat days, blackout dates, categories, settings) exports with every field present and correctly typed.
  - [x] Subtask 4.2: Unit test — zero-Goal state exports a structurally valid file with `goals: []` and empty related arrays, not an error and not omitted keys.
  - [x] Subtask 4.3: Unit test — export path never invokes any repository write method or `GoalService` method (verify via fake/mock repository that fails the test if any mutating method is called).
  - [x] Subtask 4.4: Static/architectural check — the exporter module has no import of any networking package, consistent with NFR-1/NFR-2.

## Dev Notes

- **Read-only, not a GoalService use-case:** unlike every other write path in this product, export never calls `GoalService` — AD-6 governs writes, and export performs none. This is a deliberate asymmetry with Story 6.2 (import) and 6.3 (reset), both of which do route through `GoalService`. Do not add a "write export metadata" side effect anywhere in this story.
- **Schema-version contract is load-bearing for Story 6.2:** the `meta.schemaVersion` field (literal string `"1.0"` for this release) is the exact field Story 6.2's import validator checks for presence and for exact-match support. Keep the field name (`schemaVersion`), its location (nested under `meta`, not top-level), and its value format (`"1.0"`) stable — Story 6.2 was written against this contract.
- **Field-for-field parity with the Drift ER diagram:** every exported entity array's field names match ARCHITECTURE-SPINE.md's `erDiagram` exactly (e.g. `GOAL_LOG.dnfMarked`, `GOAL_VERSION.cheatDayQuota`) so the deserializer in 6.2 can map fields without a translation layer.
- **Location:** `lib/data/io/` per the Structural Seed — this is the `data` layer; it may depend on `domain` (entities, repository interfaces) but never the reverse (AD-1).
- **Offline guarantee:** NFR-1 (offline-first, absolute) and NFR-2 (zero telemetry, no third-party network calls) apply directly — the exporter must not perform or trigger any network I/O, and nothing about the export flow may transmit data off-device.
- **Settings screen reuse:** the Settings surface already exists by this point (Epic 4 Story 4.1 built it for the global reminder time), so this story adds an action to it rather than building a new screen from scratch.
- **Testing standard:** because export's only real risk is silently missing data or accidentally writing, tests must positively assert (a) completeness of the exported shape against real data and (b) the absence of any write-path invocation — not just "export doesn't throw."

### Project Structure Notes

- New file(s) belong under `lib/data/io/` (e.g. `json_exporter.dart`), consistent with the Structural Seed's `data/io/ # JSON export/import (de)serialization (FR-33, FR-34) -- writes still go through GoalService` comment — export itself has no writes, but the folder is shared with import (Story 6.2).
- No new domain entities are needed; export serializes existing domain entities (`Goal`, `GoalVersion`, `GoalLog`, `CheatDay`, `BlackoutDate`) plus the `shared_preferences`-backed settings, so no `lib/domain/entities/` changes are expected in this story.
- Settings screen changes live under `lib/presentation/screens/` (existing file from Epic 4); no new screen route is introduced for export itself — it's an action within Settings, not a separate destination (per the IA table in EXPERIENCE.md, which lists "export" as reached from Settings, not as its own row).
- No conflicts detected between this story and the structural seed.

### References

- [Source: docs/epics.md#Story 6.1] — user story and full acceptance criteria (Given/When/Then)
- [Source: docs/epics.md#Requirements Inventory] — FR-33 (JSON Export), NFR-1 (Offline-First), NFR-2 (Zero Telemetry)
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6] — GoalService as sole writer; export is explicitly read-only and outside AD-6's write path
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-1] — layered/hexagonal boundary; `data/io/` depends on `domain` only
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed] — `lib/data/io/` location; `erDiagram` entity field shapes (`GOAL`, `GOAL_VERSION`, `GOAL_LOG`, `CHEAT_DAY`, `BLACKOUT_DATE`)
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Consistency Conventions] — data conventions (UUIDv4 ids, naive ISO-8601 date-only strings, `shared_preferences` for settings)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Information Architecture] — Settings surface lists export/import/reset as reachable actions
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components] — `button-secondary` usage for non-primary Settings actions (UX-DR10)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `flutter pub run build_runner build` — regenerated Riverpod `.g.dart` files for `week_start_provider.dart` and the new `export_provider.dart`; clean build, no conflicts.
- `flutter analyze` — 0 errors/warnings on the full project after all changes; only pre-existing `prefer_initializing_formals` info-level lints (same style already used throughout `goal_service.dart` etc.).
- `flutter test` — full suite (335 tests) green after all changes, including the 4 new `JsonExporter` tests, the `ShareExportFileWriter` test, the Week-Start persistence tests, and the updated `settings_screen_test.dart`.
- `flutter build apk --debug` — full native Android build succeeds end-to-end with the new `share_plus` plugin linked (only a pre-existing, unrelated Kotlin-Gradle-Plugin warning from `flutter_timezone`/`home_widget`). No Android emulator/device was available in this environment for an interactive on-device run, so this build is the verification that the real plugin registers and compiles correctly, beyond what widget tests alone can prove.
- `flutter build windows --debug` — failed on a pre-existing, unrelated environment gap: `flutter_local_notifications_windows` (an Epic 4 dependency, untouched by this story) can't find `atlbase.h` (missing Visual Studio ATL component). Confirmed this is not caused by this story's changes since the failing plugin has no connection to `share_plus`/`path_provider`/Week-Start persistence.

### Completion Notes List

- **Two schema gaps found and resolved before implementation (confirmed with Panda):** the story assumed a persisted `weekStartDay` setting and an `{id, name}` `categories` shape, but neither existed in the codebase yet — Week-Start was only an in-memory Riverpod default (never written to `shared_preferences`, no Settings UI), and categories are free-text strings on `Goal.category` with no separate id concept. Panda asked for Week-Start to become a real, user-changeable, persisted setting (defaulting to Monday) rather than exporting a hardcoded default, so this story adds that persistence + a small Settings UI toggle as prerequisite infrastructure (Subtask 1.3/3.1 scope). For categories, the category name is used as its own `id` (`{id: name, name: name}`) since nothing else exists to key on — Story 6.2 can treat `id` as an opaque string.
- **Week-Start persistence added:** `WeekStartSettingsRepository` (domain) + `SharedPrefsWeekStartSettingsRepository` (data), mirroring `ReminderSettingsRepository`'s shape exactly. `week_start_provider.dart` keeps `weekStartSettingProvider` a plain synchronous `WeekStart` (never `AsyncValue`) for every existing reader (`week_view.dart`, `month_view.dart`, `stats_providers.dart`, `widget_bridge_provider.dart`) — a new `weekStartInitializerProvider` hydrates it from `shared_preferences` once at startup (same "async load, then apply to the synchronous setting" pattern as `reminderInitializer`), and a new `WeekStartController` persists+applies a new choice in one step. `main.dart` now watches `weekStartInitializerProvider` alongside `reminderInitializerProvider`. `settings_screen.dart` gained a "Week starts on" row with Mon/Sun toggle chips (reusing `GoalFilterBar._FilterChip`'s outlined/filled-when-selected treatment per UX-DR10 — no new interactive primitive).
- **Export includes real fields beyond the story's literal (pre-Story-1.9/2.2) field lists:** `Goal.description`/`Goal.endDate` (added by Story 1.9) and `GoalVersion.isPaused` (added by Story 2.2) are real persisted domain state that postdates ARCHITECTURE-SPINE.md's original `erDiagram`, which the story's Subtask 1.2 field lists were transcribed from verbatim. Omitting them would silently drop real user data from a "full app state" backup, contradicting AC #1's "containing all of it." All three are included in the export; documented here rather than editing the story's task text.
- **`JsonExporter` (`lib/data/io/json_exporter.dart`)** depends only on the five read-only domain repository interfaces already used elsewhere (`GoalRepository.watchAllGoals()` + a per-goal loop calling each repository's existing `findAllForGoal`) plus the two settings repositories — never `GoalService`, satisfying AC #3 by construction. `exportToJson()` pretty-prints via `JsonEncoder.withIndent`; `buildExportModel()` exposes the plain `Map` for tests without re-parsing JSON.
- **File-save/share flow uses `share_plus` (new dependency)**, added because no such platform plugin existed in this codebase yet — writes the JSON to a temp file (`path_provider`) then hands it to the OS-native share sheet via `SharePlus.instance.share(ShareParams(...))` (the package's current, non-deprecated API as of `share_plus 13.3.0`). `ShareExportFileWriter` takes its `path_provider`/`share_plus` dependencies as injectable constructor params (defaulting to the real plugins) purely so tests can substitute a real temp directory and `SharePlus.custom(fakePlatform)` — the same seam `GoalService`'s injectable `Uuid` already uses. `share_plus_platform_interface` was added as an explicit dev dependency since the test imports its `SharePlatform` directly (previously only a transitive dependency).
- **Settings screen** (`lib/presentation/screens/settings_screen.dart`) gained an "Export data" `SecondaryButton` (UX-DR10, not the screen's single forward action) that reads `jsonExporterProvider`, builds the JSON, and hands it to `exportFileWriterProvider` — a timestamped filename (`tracker-export-YYYYMMDD-HHmmss.json`) is generated inline; failures show a `SnackBar` rather than propagating (this is a user-triggered, best-effort share action, not a domain write with an atomicity guarantee to protect).
- Task 4.3's "fails the test if any mutating method is called" fake was implemented as write-tracking wrapper repositories (`_WriteTrackingGoalRepository` etc. in the test file) that flag a boolean on any write call rather than throwing immediately — this lets the export run to completion and be asserted on normally, then separately assert every write flag stayed `false`, rather than aborting mid-export on the first (hypothetical) violation.
- Task 4.4's static check reads `json_exporter.dart`'s own source text and asserts none of its `import` lines reference `dart:io`, `dart:html`, or common networking packages (`http`, `dio`, `web_socket_channel`, `cronet`) — trivially true today (the file only imports `dart:convert` + domain interfaces) and guards against a future regression.

### File List

**New files:**
- `lib/domain/services/week_start_settings_repository.dart`
- `lib/data/settings/shared_prefs_week_start_settings_repository.dart`
- `lib/domain/services/export_file_writer.dart`
- `lib/data/io/share_export_file_writer.dart`
- `lib/data/io/json_exporter.dart`
- `lib/presentation/providers/export_provider.dart`
- `lib/presentation/providers/export_provider.g.dart` (generated)
- `test/data/settings/shared_prefs_week_start_settings_repository_test.dart`
- `test/presentation/week_start_controller_test.dart`
- `test/data/io/json_exporter_test.dart`
- `test/data/io/share_export_file_writer_test.dart`

**Modified files:**
- `lib/presentation/providers/week_start_provider.dart`
- `lib/presentation/providers/week_start_provider.g.dart` (generated)
- `lib/main.dart`
- `lib/presentation/screens/settings_screen.dart`
- `test/presentation/settings_screen_test.dart`
- `pubspec.yaml` (added `share_plus` dependency, `share_plus_platform_interface` dev dependency)
- `pubspec.lock` (regenerated)

## Change Log

- 2026-08-31: Story implemented (Tasks 1-4 complete, all ACs satisfied). Added Week-Start setting persistence + Settings UI as prerequisite infrastructure (confirmed with Panda), then implemented the read-only `JsonExporter`, the `share_plus`-backed file-save/share flow, and the Settings → Export action. Status set to `review`.
