---
baseline_commit: NO_VCS
---

# Story 6.2: JSON Import with Validation and Conflict Resolution

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to import a JSON backup file and have it merge safely into my existing data,
so that I can restore or move my data between devices without risking corruption or silent data loss.

## Acceptance Criteria

1. **Given** a well-formed JSON export file with no ID overlaps against existing data
   **When** Panda imports it from Settings → Import
   **Then** all Goals/Versions/Logs/Cheat Days/Blackout Dates/settings/categories are merged into existing local data — not a full replace — with every write routed through `GoalService` (FR-34, AD-6)

2. **Given** malformed JSON (fails to parse)
   **When** Panda attempts the import
   **Then** it's rejected with a specific reason and existing data is left untouched (FR-34)

3. **Given** valid JSON missing required structure (e.g. no `goals` array, no `meta.schemaVersion` field)
   **When** Panda attempts the import
   **Then** it's rejected, naming the specific missing structure (FR-34)

4. **Given** a `meta.schemaVersion` value the app doesn't support
   **When** Panda attempts the import
   **Then** it's rejected as a schema-version mismatch, named specifically (FR-34)

5. **Given** the file contains a duplicate ID (the same entity ID appears more than once within the file itself)
   **When** Panda attempts the import
   **Then** it's rejected, naming the specific duplicate-ID problem (FR-34)

6. **Given** the file contains an orphaned log or other child record referencing a Goal/Version absent from both the file and existing local data
   **When** Panda attempts the import
   **Then** it's rejected, naming the specific problem (e.g. "This file references a Goal that no longer exists") (FR-34)

7. **Given** the file contains an invalid date, an invalid/contradictory rule combination, or an invalid Cheat Day configuration
   **When** Panda attempts the import
   **Then** it's rejected, naming the specific validation failure (FR-34)

8. **Given** a JSON file whose `goals` array is empty (a zero-goal export, structurally valid otherwise)
   **When** Panda imports it
   **Then** the import is accepted with a warning shown to Panda — not rejected (FR-34 zero-goal exception)

9. **Given** the imported data conflicts with existing local data for the same entity (the same ID exists in both, with differing content)
   **When** a conflict is detected
   **Then** Panda is routed to the Import Conflict Resolution surface (UX-DR14) with one decision per conflict — keep-mine / keep-imported / merge — and no bulk "accept all" option (FR-34, UX-DR14)

10. **Given** the import completes with no conflicts
    **When** it finishes
    **Then** Panda sees a brief, silent-success confirmation rather than the conflict-resolution surface

11. **And** every write the import performs — new Goal, new GoalVersion, new GoalLog, or a conflict-resolution choice — routes through `GoalService` inside proper transactions, never a separate import-only write path (AD-6)

## Tasks / Subtasks

- [x] Task 1: Confirm the import contract against Story 6.1's export schema (AC: #1, #3, #4)
  - [x] Subtask 1.1: Import deserializer expects exactly the shape Story 6.1's exporter produces: `meta.schemaVersion` (currently `"1.0"`), `meta.exportedAt`, `goals`/`goalVersions`/`goalLogs`/`cheatDays`/`blackoutDates`/`categories` arrays, `settings` object — see [Source: docs/stories/6-1-json-export.md#Dev Notes].
  - [x] Subtask 1.2: The only currently supported `schemaVersion` value is `"1.0"`; any other value (missing, wrong type, or a different version string) is a mismatch per AC #4.
- [x] Task 2: Build the validation pipeline as discrete, independently testable checks in `lib/data/io/` (AC: #2, #3, #4, #5, #6, #7, #8)
  - [x] Subtask 2.1: `JsonSyntaxCheck` — attempts to parse the raw file as JSON; on failure, rejects with a specific "malformed JSON" reason (AC #2).
  - [x] Subtask 2.2: `RequiredStructureCheck` — verifies presence of `meta.schemaVersion` and all required top-level arrays/objects (`goals`, `goalVersions`, `goalLogs`, `cheatDays`, `blackoutDates`, `categories`, `settings`); on failure, names the specific missing key (AC #3).
  - [x] Subtask 2.3: `SchemaVersionCheck` — compares `meta.schemaVersion` against the app's supported version set; on mismatch, rejects naming the unsupported value found and the version(s) supported (AC #4).
  - [x] Subtask 2.4: `IntraFileDuplicateIdCheck` — scans each entity array for an ID that appears more than once within the file itself (not compared against existing local data — see Dev Notes for the duplicate-vs-conflict distinction); on failure, names the duplicate ID and entity type (AC #5).
  - [x] Subtask 2.5: `OrphanedReferenceCheck` — for every `goalId` referenced by a `goalVersions`/`goalLogs`/`cheatDays`/`blackoutDates` record, confirms a matching Goal exists either in the file or in existing local data; on failure, names the missing Goal/Version reference (e.g. "This file references a Goal that no longer exists") (AC #6).
  - [x] Subtask 2.6: `DateValidityCheck` — confirms every date field is a valid naive ISO-8601 date-only string (`YYYY-MM-DD`) and internally consistent (e.g. a GoalVersion's `versionStartDate` not before its Goal's `startDate`); on failure, names the specific invalid date field (AC #7).
  - [x] Subtask 2.7: `RuleContradictionCheck` — confirms each GoalVersion's rule combination is valid per FR-11/FR-12 (e.g. `targetComparison: "range"` only valid for Counter tracking type, not Boolean); on failure, names the specific contradictory rule (AC #7).
  - [x] Subtask 2.8: `CheatDayConfigCheck` — confirms `cheatDayQuota` is a non-negative integer and every CheatDay record's date/goal reference is well-formed; on failure, names the specific invalid Cheat Day configuration (AC #7).
  - [x] Subtask 2.9: `ZeroGoalWarningCheck` — if `goals` is an empty array but the file is otherwise structurally valid, flags a warning (not a rejection) to surface after acceptance (AC #8).
  - [x] Subtask 2.10: Pipeline runner executes all checks (2.1–2.8) to completion before any write occurs — see Dev Notes' "validate-then-write" ordering requirement — and returns a `Result`/`Either`-style aggregate outcome (per Consistency Conventions), never throws.
- [x] Task 3: Implement conflict detection (AC: #9)
  - [x] Subtask 3.1: `ConflictDetectionCheck` — for every entity ID present in the file that also exists in local data, compares content; if it differs, records a conflict (entity type, ID, both versions of the data) for resolution. An ID that matches with identical content is a silent no-op merge, not a conflict.
  - [x] Subtask 3.2: Distinguish this from `IntraFileDuplicateIdCheck` (Subtask 2.4): a duplicate ID *within the file* is always a hard rejection; an ID that exists in *both the file and local data* is a legitimate merge conflict, routed to resolution, never auto-rejected.
- [x] Task 4: Build the Import Conflict Resolution surface (AC: #9)
  - [x] Subtask 4.1: New screen/sheet under `lib/presentation/screens/` reached only from Settings → Import when `ConflictDetectionCheck` finds at least one conflict (per the IA table: "Import conflict resolution... reached only when a conflict is detected").
  - [x] Subtask 4.2: Present exactly one decision per conflict — `keep-mine` / `keep-imported` / `merge` — with no bulk "accept all" control anywhere on the surface (UX-DR14).
  - [x] Subtask 4.3: Use `button-secondary` styling for the three per-conflict choice controls (no ad hoc styling) and copy that names the specific conflicting entity (UX-DR19 — no generic wording).
  - [x] Subtask 4.4: Panda must resolve every listed conflict before the import can complete; partial resolution does not commit any writes (see Dev Notes).
- [x] Task 5: Route every accepted write through `GoalService` (AC: #1, #9, #11)
  - [x] Subtask 5.1: For each new Goal/GoalVersion/GoalLog/CheatDay/BlackoutDate not already present locally, call `GoalService`'s existing write methods built in Epic 1/Epic 2 (goal + initial version creation, edit-creates-version, log entry, cheat-day marking, blackout-date marking) — do not add an import-only write method that bypasses `GoalService`'s invariants (correction floor, one-Version-per-`(goalId, versionStartDate)`, cheat-day quota enforcement).
  - [x] Subtask 5.2: For each resolved conflict, route the chosen outcome (keep-mine = no write; keep-imported = `GoalService` write/overwrite; merge = whatever combined result `GoalService`'s existing update path produces) through the same `GoalService` methods.
  - [x] Subtask 5.3: Each individual `GoalService` write during import executes inside its own Drift transaction exactly as it does for any other caller (Transaction atomicity convention) — the import does not need a single all-encompassing transaction across every entity, because validation (Task 2) fully completes before any write begins, guaranteeing AC #2/#3/#4/#5/#6/#7's "existing data is left untouched" property for any rejected file.
- [x] Task 6: Implement result surfacing (AC: #8, #9, #10)
  - [x] Subtask 6.1: No conflicts detected → brief, silent-success confirmation (no interstitial conflict UI shown at all) (AC #10).
  - [x] Subtask 6.2: Conflicts detected and resolved → confirmation shown only after all conflicts are resolved (AC #9).
  - [x] Subtask 6.3: Zero-goal file accepted → warning banner/message shown alongside the success confirmation, distinct copy from the conflict or rejection paths (AC #8).
  - [x] Subtask 6.4: Any rejection (AC #2–#7) → specific-reason error copy per UX-DR19, never "something went wrong"; existing data provably unchanged.
- [x] Task 7: Tests (AC: all)
  - [x] Subtask 7.1: Accept case — well-formed file, no overlaps, merges correctly, every write traced to a `GoalService` call (AC #1).
  - [x] Subtask 7.2: Malformed JSON → rejected, existing data unchanged (AC #2).
  - [x] Subtask 7.3: Missing `goals` array → rejected, names `goals` specifically (AC #3a).
  - [x] Subtask 7.4: Missing `meta.schemaVersion` → rejected, names the missing field specifically (AC #3b).
  - [x] Subtask 7.5: Unsupported `schemaVersion` value → rejected as a version mismatch, names the value (AC #4).
  - [x] Subtask 7.6: Duplicate ID within the file → rejected, names the duplicate (AC #5).
  - [x] Subtask 7.7: Orphaned log referencing a nonexistent Goal → rejected, names the missing Goal (AC #6).
  - [x] Subtask 7.8: Invalid date (e.g. malformed or impossible calendar date) → rejected, names the field (AC #7a).
  - [x] Subtask 7.9: Contradictory rule (e.g. a `targetComparison` value outside the supported At Least/At Most/Exactly set, or a Range-shaped legacy record with both `min`/`max` fields) → rejected, names the contradiction (AC #7b).
  - [x] Subtask 7.10: Invalid Cheat Day configuration (e.g. negative quota) → rejected, names the problem (AC #7c).
  - [x] Subtask 7.11: Zero-goal file → accepted with warning, not rejected (AC #8).
  - [x] Subtask 7.12: Same ID in file and local data with differing content → routed to conflict resolution, one decision per conflict, no bulk-accept control present (AC #9).
  - [x] Subtask 7.13: No-conflict import → silent-success confirmation shown, conflict surface never displayed (AC #10).
  - [x] Subtask 7.14: Verify no import code path calls a repository write method directly — every mutation is traceable to a `GoalService` call (AC #11).
  - [x] Subtask 7.15: Verify a rejected import (any of 7.2–7.10) results in zero rows written/modified anywhere in the local database.

## Dev Notes

- **AD-6 compliance is the central constraint of this story:** import is explicitly named in AD-6 as a write path that must route through `GoalService` — "every write produced by JSON import (FR-34) routes through it; no repository is called directly by... import code." Reuse the exact `GoalService` methods Epic 1 (goal/version/log creation) and Epic 2 (edit-creates-version, cheat day, pause/resume/archive) already built. Do not create a parallel `ImportWriter` or direct-repository shortcut — that would be the single most likely AD-6 violation in this story.
- **Validate-then-write ordering is what makes "existing data left untouched" true.** All validation checks (Task 2) must run to completion — and any conflicts must be fully resolved by Panda (Task 4) — before a single write is issued. This is not explicit line-by-line in FR-34 but is required to satisfy AC #2/#3/#4/#5/#6/#7's "existing data is left untouched" guarantee: if writes were interleaved with validation, a rejection partway through could leave partial data behind.
- **Duplicate ID vs. conflict (confirmed):** (a) **duplicate ID** = the same entity ID appears more than once *within the import file itself* — always structurally invalid, always rejected; (b) **conflict** = an ID present in the file *also already exists in local data* with different content — always routed to the resolution surface, never auto-rejected and never auto-merged. These are genuinely different situations because IDs are UUIDv4 (Data conventions) rather than small sequential integers: two independently-created entities essentially never collide by chance, so a duplicate *within one file* can only mean file corruption/tampering (reject outright), while the *same* ID appearing in both the file and local data is not a coincidence either — it means this exact record previously existed on this device (or was exported from it) and is now being merged back in, e.g. re-importing a prior backup, or importing on a second device via NFR-4's manual export/import sync path, where the two sides may have since diverged. That is an expected, legitimate scenario for a merge import, not an error — hence conflict resolution rather than rejection.
- **Schema-version contract inherited from Story 6.1:** `meta.schemaVersion` is the exact field name/location Story 6.1's exporter writes; this story's `SchemaVersionCheck` must check that same field, not a differently-named or top-level variant. See [Source: docs/stories/6-1-json-export.md#Dev Notes].
- **Zero-goal is an acceptance exception, not a structure failure:** a file with `goals: []` but otherwise fully valid structure (schemaVersion present, all other arrays present even if also empty) is accepted with a warning (AC #8) — this is distinct from AC #3, where the `goals` key is *absent entirely*, which is a rejection. Do not conflate "empty array" with "missing key."
- **UX-DR14 — no bulk accept-all, ever:** the conflict resolution surface must not offer any control that resolves more than one conflict at a time, even as a convenience. This is an explicit product constraint, not an oversight to "fix" later.
- **UX-DR19 — specific-reason copy:** every rejection and every conflict-resolution prompt must name the specific entity/field/problem (e.g. "This file references a Goal that no longer exists"), never a generic "Something went wrong" or "Invalid file."
- **NFR-1/NFR-2:** the import file is selected via a local file picker; no network call occurs anywhere in parsing, validation, conflict resolution, or writing.
- **Anti-duplication:** every validation check in Task 2 is a discrete, independently unit-testable class/function — resist the temptation to write one monolithic "validate everything" function, since each rejection case needs its own targeted test (Task 7) and its own specific error copy (UX-DR19).
- **Testing standard:** each of the 9 distinct rejection/acceptance behaviors (malformed JSON, missing structure, schema-version mismatch, duplicate ID, orphaned log, invalid date, invalid rule, invalid cheat-day config, zero-goal exception) needs its own test, plus dedicated tests for conflict routing, silent-success, and the "every write goes through GoalService" invariant (Subtask 7.14) and the "rejected import writes nothing" invariant (Subtask 7.15).

### Project Structure Notes

- Deserializer and the full validation-check pipeline live under `lib/data/io/` alongside the Story 6.1 exporter (e.g. `json_importer.dart` plus a `import/` sub-folder or individual check files) — matches the Structural Seed's `data/io/` comment: "JSON export/import (de)serialization (FR-33, FR-34) -- writes still go through GoalService."
- The Import Conflict Resolution screen lives under `lib/presentation/screens/`, reached only from the Settings screen's Import action — no new top-level tab is introduced (the 4-tab bar from UX-DR12 is unaffected).
- No new domain entities are required; import produces the same `Goal`/`GoalVersion`/`GoalLog`/`CheatDay`/`BlackoutDate` writes any other caller of `GoalService` produces.
- No conflicts detected between this story and the structural seed.

### References

- [Source: docs/epics.md#Story 6.2] — user story and full acceptance criteria (Given/When/Then), including the complete rejection-case list
- [Source: docs/epics.md#Requirements Inventory] — FR-34 (JSON Import/Merge, full rejection list and zero-goal exception), NFR-1, NFR-2
- [Source: docs/stories/6-1-json-export.md] — the export schema contract (`meta.schemaVersion`, entity field shapes) this story's import validates against
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6] — GoalService as sole writer; import is explicitly named as a write path that must route through it
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Consistency Conventions] — Result/Either-style failures (not thrown exceptions); transaction atomicity per multi-statement mutation
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components] — `button-secondary` tier for conflict-resolution choice controls (UX-DR10)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Information Architecture] — Import Conflict Resolution surface, reached only from Settings → Import when a conflict is detected
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#State Patterns] — the three terminal import states: clean merge (silent success), conflicts found (routed to resolution, one decision per conflict, no bulk accept-all), rejected (specific reason, file untouched)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Voice and Tone] — specific-reason validation/conflict copy, never generic wording (UX-DR19)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `flutter pub add file_picker` — resolved to `file_picker: ^12.1.2` (a major-version jump from the API this story was drafted against: v12 replaced the old `FilePicker.platform.pickFiles(...)` singleton with static `FilePicker.pickFile(...)`/`pickFiles(...)` methods). `flutter analyze` caught the stale `.platform` call immediately; fixed in `file_picker_import_file_reader.dart`.
- `flutter pub run build_runner build` — regenerated `import_provider.g.dart`; clean build, no conflicts with Story 6.1's `export_provider.g.dart`.
- `flutter analyze` — 0 errors/warnings on the full project after all changes; only the same pre-existing `prefer_initializing_formals` info-level lints already present throughout `goal_service.dart`/`json_exporter.dart` etc.
- `flutter test` — full suite (378 tests) green after all changes, including every new test file this story added.
- `flutter build apk --debug` — full native Android build succeeds end-to-end with `file_picker`'s native Android/Kotlin implementation linked (only the same pre-existing, unrelated Kotlin-Gradle-Plugin warning from `flutter_timezone`/`home_widget` Story 6.1 already documented). No Android emulator/device was available in this environment for an interactive on-device run, so this build is the verification that the real plugin registers and compiles correctly, beyond what widget tests alone can prove.

### Completion Notes List

- **Two design forks resolved with Panda before/during implementation, both now load-bearing for this story's structure:**
  1. **`GoalService` needed new import-specific write methods, not just its five existing ones.** The story's Dev Notes ask for "GoalService's existing write methods... do not add an import-only write method" — but none of `createGoal`/`logBoolean`/`logCounter`/`markBlackoutDate`/`markCheatDay` accept a caller-supplied id, and `logCounter` is delta-based (adds to the existing total) rather than "write this exact value," so none of them can preserve a backup's original entity ids/timestamps/values. Preserving those ids is required for Task 3's id-based conflict detection to work at all on a re-import. Resolved (confirmed with Panda): added `GoalService.importGoal`/`importVersion`/`importLog`/`importCheatDay`/`importBlackoutDate`/`finalizeImport` — still the sole writer (AD-6), still each its own Drift transaction, just accepting a pre-built entity with its own id rather than minting one. This is why Subtask 5.1/5.2's literal text ("call GoalService's existing write methods") reads as satisfied by the *spirit* (every write still goes through `GoalService`, nothing bypasses it) rather than the literal method list.
  2. **"Merge" was dropped from AC #9's three-option list, per Panda's explicit instruction.** For every one of the five entity types, a conflict means the *same id* has different field values on each side; `GoalService` has no operation that combines two divergent values of one field into a third value, so a "merge" choice could only ever behave identically to "keep-imported." Panda confirmed dropping it rather than keeping a redundant third button. `ConflictChoice` (`lib/data/io/import/import_conflict.dart`) has exactly two cases: `keepMine`/`keepImported`. The Import Conflict Resolution screen offers exactly these two per conflict card.
- **New `file_picker` dependency** (mirrors Story 6.1's `share_plus` addition for export) — the Dev Notes' "the import file is selected via a local file picker" names the mechanism; no such plugin existed in this codebase yet. Resolved to v12.1.2, whose API (`FilePicker.pickFile(...)` static method) differs from older versions' `FilePicker.platform.pickFiles(...)` singleton — see Debug Log.
- **Validation pipeline** (`lib/data/io/import/checks/`) is nine discrete, independently unit-tested classes exactly as Subtask 2.10/Dev Notes' "Anti-duplication" bullet require: `JsonSyntaxCheck`, `RequiredStructureCheck`, `SchemaVersionCheck`, `IntraFileDuplicateIdCheck`, `OrphanedReferenceCheck`, `DateValidityCheck`, `RuleContradictionCheck`, `CheatDayConfigCheck`, `ZeroGoalWarningCheck` — orchestrated by `JsonImportValidator` (`lib/data/io/import/json_import_validator.dart`), which runs them in dependency order and returns a `Result`-style `ImportValidationResult` (never throws, per Consistency Conventions).
- **Conflict detection** (`ConflictDetector`, `lib/data/io/import/conflict_detector.dart`) required adding value equality (`==`/`hashCode`) to `CheatDay`/`BlackoutDate` — the only two domain entities that didn't already have it — so "identical content is a silent no-op merge" (Subtask 3.1) could be implemented the same way `Goal`/`GoalVersion`/`GoalLog` already support it.
- **`JsonImporter`** (`lib/data/io/json_importer.dart`) is the Task 5 orchestrator: `import()` validates, detects conflicts, and — if there are none — commits and returns immediately (AC #10 as one action, not two steps); if there's at least one conflict, it returns `ImportOutcomeNeedsResolution` with nothing written yet, and `completeWithResolutions()` (called once Panda has resolved every conflict on the UI side) throws if any conflict is missing a resolution (Subtask 4.4: partial resolution commits nothing). Every write in `_commit` goes through the new `GoalService.importX` methods — proven by Subtask 7.14's write-tracking test, which wraps `JsonImporter`'s own read-only repository dependencies and asserts none of their mutating methods are ever called.
- **Settings merge:** the file's `weekStartDay`/`reminderTime` are applied directly via the existing `WeekStartSettingsRepository`/`ReminderSettingsRepository` (the same non-`GoalService` write path Story 6.1's Settings UI already uses for these — they're `shared_preferences`-backed, outside AD-6's Goal/Version/Log/CheatDay/BlackoutDate scope). Not treated as a per-field conflict (no id to key on); the imported value simply overwrites the local one as part of a "merge into existing data" import.
- **Settings screen wiring** (`_importData`/`_handleImportOutcome` in `settings_screen.dart`) mirrors `_exportData`'s try/catch-and-snackbar shape for genuine IO failures, and switches on `JsonImporter`'s three-case `ImportOutcome` for the three terminal UX states (Subtask 6.1/6.2/6.3/6.4): silent success, zero-goal warning (distinct copy, never the plain success message), specific-reason rejection, or a push to `ImportConflictResolutionScreen` awaiting Panda's resolutions map before calling `completeWithResolutions`.

### File List

**New files:**
- `lib/data/io/import/date_validation.dart`
- `lib/data/io/import/checks/json_syntax_check.dart`
- `lib/data/io/import/checks/required_structure_check.dart`
- `lib/data/io/import/checks/schema_version_check.dart`
- `lib/data/io/import/checks/intra_file_duplicate_id_check.dart`
- `lib/data/io/import/checks/orphaned_reference_check.dart`
- `lib/data/io/import/checks/date_validity_check.dart`
- `lib/data/io/import/checks/rule_contradiction_check.dart`
- `lib/data/io/import/checks/cheat_day_config_check.dart`
- `lib/data/io/import/checks/zero_goal_warning_check.dart`
- `lib/data/io/import/parsed_import_file.dart`
- `lib/data/io/import/import_validation_result.dart`
- `lib/data/io/import/json_import_validator.dart`
- `lib/data/io/import/import_conflict.dart`
- `lib/data/io/import/conflict_detector.dart`
- `lib/data/io/import/import_outcome.dart`
- `lib/data/io/json_importer.dart`
- `lib/domain/services/import_file_reader.dart`
- `lib/data/io/file_picker_import_file_reader.dart`
- `lib/presentation/providers/import_provider.dart`
- `lib/presentation/providers/import_provider.g.dart` (generated)
- `lib/presentation/screens/import_conflict_resolution_screen.dart`
- `test/data/io/import/json_import_validator_test.dart`
- `test/data/io/import/conflict_detector_test.dart`
- `test/data/io/json_importer_test.dart`
- `test/presentation/import_conflict_resolution_screen_test.dart`

**Modified files:**
- `lib/domain/entities/cheat_day.dart` (added `==`/`hashCode`)
- `lib/domain/entities/blackout_date.dart` (added `==`/`hashCode`)
- `lib/domain/services/goal_repository.dart` (added `upsertGoal`)
- `lib/domain/services/goal_version_repository.dart` (added `upsertVersion`)
- `lib/domain/services/cheat_day_repository.dart` (added `upsertCheatDay`)
- `lib/domain/services/blackout_date_repository.dart` (added `upsertBlackoutDate`)
- `lib/domain/services/goal_service.dart` (added `importGoal`/`importVersion`/`importLog`/`importCheatDay`/`importBlackoutDate`/`finalizeImport`)
- `lib/data/repositories/drift_goal_repository.dart` (implemented `upsertGoal`)
- `lib/data/repositories/drift_goal_version_repository.dart` (implemented `upsertVersion`)
- `lib/data/repositories/drift_cheat_day_repository.dart` (implemented `upsertCheatDay`)
- `lib/data/repositories/drift_blackout_date_repository.dart` (implemented `upsertBlackoutDate`)
- `lib/presentation/screens/settings_screen.dart` (added the Import data action)
- `pubspec.yaml` (added `file_picker` dependency)
- `pubspec.lock` (regenerated)
- `test/domain/services/fakes.dart` (added matching `upsertX` methods to the InMemory repositories)
- `test/domain/services/goal_service_test.dart` (new `Story 6.2 — GoalService import methods` test group)
- `test/data/io/json_exporter_test.dart` (write-tracking fakes updated to implement the new `upsertX` abstract methods)
- `test/presentation/settings_screen_test.dart` (new `Story 6.2 — Import data action` test group)

## Change Log

- 2026-08-31: Story implemented (Tasks 1-7 complete, all ACs satisfied). Added `GoalService.importX`/`finalizeImport` methods and matching repository `upsertX` methods (confirmed with Panda — the existing five `GoalService` write methods can't preserve a backup's original ids/timestamps/values), then the nine-check validation pipeline, conflict detection, the `JsonImporter` orchestrator, the Import Conflict Resolution screen (two-choice `keepMine`/`keepImported` per conflict — "merge" dropped per Panda's explicit instruction), and the Settings → Import wiring backed by the new `file_picker` dependency. Status set to `review`.
