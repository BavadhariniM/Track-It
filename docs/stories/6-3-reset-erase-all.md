---
baseline_commit: NO_VCS
---

# Story 6.3: Reset / Erase All

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want a separate action that wipes all my local data and returns the app to a clean first-run state,
so that I can start over completely if I ever want to, with no chance of it happening by accident.

## Acceptance Criteria

1. **Given** Settings
   **When** Panda selects Reset / Erase All
   **Then** an explicit secondary confirmation step is required before anything is deleted — the only action in the app with this two-step confirmation (FR-36, UX-DR24)

2. **Given** the confirmation step
   **When** it's shown
   **Then** its copy states the specific consequence and irreversibility ("This erases all Goals, logs, and settings. This cannot be undone.") rather than generic wording (FR-36)

3. **Given** Panda confirms
   **When** the reset executes
   **Then** all Goals, GoalVersions, GoalLogs, Cheat Days, Blackout Dates, settings, and categories are wiped inside a single Drift transaction, executed as a `GoalService` use-case (AD-6, Transaction atomicity)

4. **Given** the reset completes
   **When** Panda returns to the app
   **Then** it shows the same first-run empty state as a fresh install (FR-36, UX-DR26)

5. **Given** Panda cancels at the secondary confirmation step
   **When** they back out
   **Then** no data is deleted and the app returns to Settings unchanged

6. **And** Reset / Erase All is the only truly irreversible action in the product — every other lifecycle action (archive, pause) remains reversible/history-preserving and therefore stays single-tap (UX-DR24, FR-2, FR-35)

## Tasks / Subtasks

- [x] Task 1: Implement the `GoalService.resetAll()` use-case (AC: #3)
  - [x] Subtask 1.1: Add a `resetAll()` (or equivalently named) method to `GoalService` (domain layer, `lib/domain/services/`) — Reset is explicitly named in AD-6 as "a `GoalService` use-case that clears all Drift tables plus the settings store inside one transaction," so it must live on `GoalService`, not on a repository or a presentation-layer controller.
  - [x] Subtask 1.2: Inside a single Drift transaction, delete all rows from every domain table: `GOAL`, `GOAL_VERSION`, `GOAL_LOG`, `CHEAT_DAY`, `BLACKOUT_DATE`, plus any categories table.
  - [x] Subtask 1.3: Within the same transaction (or immediately following it, still inside the same logical use-case call), clear the `shared_preferences`-backed settings (week-start day, global reminder time) so no stale setting survives the reset — Reset must return the app to a state indistinguishable from fresh install, not just an empty Drift database.
  - [x] Subtask 1.4: Invalidate/clear the status cache (AD-7) as part of the same operation — a stale cache after a full data wipe would violate AD-7's "fully recomputable, never a source of truth" guarantee, even though there's nothing left to recompute from.
  - [x] Subtask 1.5: Clear the `widget_bridge` shared container (if populated) so home-screen widgets reflect the reset rather than showing stale pre-reset status until their next natural update.
- [x] Task 2: Build the Settings → Reset entry point and two-step confirmation (AC: #1, #2, #5)
  - [x] Subtask 2.1: Add a "Reset / Erase All" action to the Settings screen (`lib/presentation/screens/`), styled with `button-secondary` (UX-DR10) — it is not the screen's single forward action, and it must not be visually styled to invite an accidental tap.
  - [x] Subtask 2.2: First tap opens an explicit secondary confirmation step (modal sheet, per DESIGN.md's one permitted elevation exception for modal sheets) — this is the only surface in the app requiring two-step confirmation (AC #1, UX-DR24).
  - [x] Subtask 2.3: Confirmation copy states the specific consequence verbatim per FR-36: "This erases all Goals, logs, and settings. This cannot be undone." — no generic "Are you sure?" wording (AC #2, UX-DR19).
  - [x] Subtask 2.4: A cancel/back control on the confirmation step returns to Settings with zero data changes (AC #5) — verify no partial write or transaction has begun before final confirmation.
  - [x] Subtask 2.5: Only the final, explicit confirm action inside the second step invokes `GoalService.resetAll()` — nothing about opening the confirmation step itself triggers any mutation.
- [x] Task 3: Post-reset navigation and state (AC: #4)
  - [x] Subtask 3.1: After `resetAll()` completes, navigate/refresh so the app displays the identical first-run empty state used on fresh install (empty Dashboard prompting Goal creation, no login/account step, per UX-DR26) — reuse the existing first-run empty-state component rather than building a second "post-reset" variant.
  - [x] Subtask 3.2: Confirm all four tabs (Today/Calendar/Goals/Settings, UX-DR12) reflect the clean state correctly (e.g. Goals list empty, Calendar shows no goal data, Settings shows default week-start/no reminder time set).
- [x] Task 4: Tests (AC: all)
  - [x] Subtask 4.1: Unit test — `GoalService.resetAll()` wipes every domain table (Goal, GoalVersion, GoalLog, CheatDay, BlackoutDate, categories) starting from a populated fixture data set, verified by querying each table post-reset.
  - [x] Subtask 4.2: Unit test — `resetAll()` also clears `shared_preferences` settings (week-start day, reminder time) back to their fresh-install defaults.
  - [x] Subtask 4.3: Unit test — `resetAll()` executes as a single Drift transaction; simulate a mid-transaction failure and confirm no partial deletion occurs (all-or-nothing).
  - [x] Subtask 4.4: Integration/widget test — the full-wipe post-reset app state is behaviorally equivalent to a genuine fresh-install state (first-run empty state renders identically; no stray data surfaces anywhere, including cache-backed surfaces like Dashboard rollups and widgets).
  - [x] Subtask 4.5: Widget/UI test — Reset requires two distinct confirmation taps; canceling at the second step leaves all existing data intact (query tables before/after cancel and assert no change).
  - [x] Subtask 4.6: Widget/UI test — confirmation step copy matches the specific, consequence-stated wording (not a generic string) (AC #2).
  - [x] Subtask 4.7: Verify no other lifecycle action in the app (archive, pause) has been altered to require a second confirmation step as a side effect of this story — Reset remains the sole two-step action (AC #6).

## Dev Notes

- **AD-6 — Reset is a `GoalService` use-case, not a data-layer or presentation-layer operation.** The architecture spine states this explicitly: "Reset/Erase-All (FR-36) is a `GoalService` use-case that clears all Drift tables plus the settings store inside one transaction." Do not implement the wipe as a repository method called directly from a Settings screen controller — that would bypass `GoalService` exactly as a direct-repository import write would violate AD-6 in Story 6.2. This story and Story 6.2 share the same "no write path bypasses `GoalService`" constraint; keep the same discipline here.
- **Single-transaction, all-domain-tables wipe:** per the Transaction atomicity convention, this is one multi-statement domain mutation and must execute inside a single Drift transaction — a kill mid-reset must not leave a partially-wiped database (some tables cleared, others not). This is the same atomicity guarantee already required for GoalLog writes and GoalVersion creation, just applied to a delete-everything operation instead of an insert.
- **Reset must also clear the settings-store and cache/widget-bridge state, not just Drift tables.** AD-3 keeps week-start day and reminder time in `shared_preferences`, outside Drift; AD-7's status cache and the `widget_bridge` shared container are both derived state. All three must be cleared/invalidated so the observable result is indistinguishable from fresh install (AC #4) — a reset that wipes Drift but leaves a stale reminder time or a stale cached "Success" status on a widget would fail this story's actual intent even though the literal Drift tables are empty.
- **UX-DR24 — Reset is uniquely two-step; nothing else in the product should be.** Every other lifecycle action (archive, pause) is reversible/history-preserving and therefore stays single-tap. Do not add a second confirmation step anywhere else as an incidental "safety" measure while building this story — that would violate the "sole two-step action" invariant this story is supposed to establish (AC #6).
- **FR-36 consequence-specific copy is prescriptive, not illustrative:** EXPERIENCE.md quotes the exact confirmation copy ("This erases all Goals, logs, and settings. This cannot be undone.") as the model for consequence-specific wording (UX-DR19) — use this or copy matching its level of specificity, not a generic confirmation dialog string.
- **Anti-duplication:** reuse the existing first-run empty-state UI (already built for fresh install) for the post-reset state rather than building a parallel "post-reset empty state" — FR-36 explicitly requires these to be the same state, not merely similar ones.
- **Testing standard:** Reset needs both a narrow unit test (does `resetAll()` actually delete every row in every table plus settings) and a broader equivalence test (is the resulting app state behaviorally identical to genuine first-run) — the two are not the same test and both are required, since a resetAll() that empties tables but leaves cached/derived state behind would pass the narrow test while still failing the story's real intent.

### Project Structure Notes

- `resetAll()` (or equivalently named) belongs on `GoalService` in `lib/domain/services/`, per the Structural Seed (`domain/services/ # GoalService (AD-6), StatsService (AD-8), repository + CacheWriter interfaces`) — it is domain logic, with zero Flutter/Drift imports (AD-1); the actual table-clearing SQL lives in the Drift repository implementation(s) under `lib/data/drift/` and `lib/data/repositories/`, invoked through the domain-defined repository interfaces exactly as every other `GoalService` write already is.
- Settings-store clearing touches whatever `shared_preferences` wrapper Epic 4 Story 4.1 introduced for the reminder-time setting — reuse that same abstraction rather than adding a second settings-access path.
- The confirmation UI lives under `lib/presentation/screens/` (Settings screen) plus a modal sheet component, consistent with DESIGN.md's one permitted shadow exception for modal sheets.
- No new domain entities are introduced by this story; it is the inverse operation of everything Epic 1/2 built (deletion instead of creation), still funneled through the same `GoalService` surface.
- No conflicts detected between this story and the structural seed.

### References

- [Source: docs/epics.md#Story 6.3] — user story and full acceptance criteria (Given/When/Then)
- [Source: docs/epics.md#Requirements Inventory] — FR-36 (Reset/Erase All, the only true irreversible deletion, requires explicit secondary confirmation)
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6] — "Reset/Erase-All (FR-36) is a `GoalService` use-case that clears all Drift tables plus the settings store inside one transaction"
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-7] — status cache must remain fully recomputable / never stale; reset must not leave stale cached state
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Consistency Conventions] — Transaction atomicity: every multi-statement domain mutation executes inside one Drift transaction
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed] — `lib/domain/services/` location for `GoalService`
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Interaction Primitives] — Reset is the only action requiring a secondary confirmation step; every other lifecycle action stays single-tap (UX-DR24)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Voice and Tone] — exact consequence-specific confirmation copy for Reset
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#State Patterns] — first-run empty state definition, reused post-reset (UX-DR26)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Elevation & Depth] — modal-sheet shadow exception used for the confirmation step

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5

### Debug Log References

- `flutter analyze`: 0 errors/warnings (43 pre-existing `prefer_initializing_formals` infos, none touching this story's code).
- `flutter test`: 381/381 passing (full suite, no regressions).

### Completion Notes List

- `GoalService.resetAll()` wipes `GoalLog`/`GoalVersion`/`CheatDay`/`BlackoutDate`/the status cache/`Goal` (children before `Goals`, per its FK references) inside one `TransactionRunner.run` call, then clears the two `shared_preferences`-backed settings repos, then syncs the widget bridge — matching AD-6's "GoalService use-case… inside one transaction" plus Subtask 1.3's "immediately following it, still inside the same logical use-case call" allowance for the non-Drift settings clear.
- There is no separate `categories` table in this codebase (confirmed via `tables.dart`/`goal_filter.dart`'s `distinctCategories`) — `category` is a plain column on `GOAL`, so wiping `Goals` already satisfies Subtask 1.2's categories clause; no extra table or clear step was needed.
- `resetAll()` takes `ReminderSettingsRepository`/`WeekStartSettingsRepository` as call-time parameters rather than constructor dependencies, since both providers are `Future`-returning (behind `SharedPreferences.getInstance()`) unlike every other `GoalService` dependency; `goalServiceProvider` stays synchronous and unchanged, avoiding a ripple through its ~12 existing call sites. The new `ResetController` (`lib/presentation/providers/reset_provider.dart`) resolves both repos and calls `resetAll()`, then resets the live `weekStartSettingProvider` state and invalidates `reminderTimeProvider` so every screen reflects the change without an app restart.
- `CacheWriter.clearAll()`/`StatusCacheRepository.deleteAll()` were added as new methods distinct from the existing `rebuildAll()` — `rebuildAll()` only recomputes from existing Goals, so after a full wipe it would loop over zero Goals and leave every previously-cached row stale/orphaned; `clearAll()` deletes them outright.
- The post-reset "first-run empty state" (AC #4, Subtask 3.1/3.2) required no new component: every screen (Dashboard, Goals list, Week/Month View) already reads Goal/Version/Log data straight off Drift's reactive `.watch()` streams, which emit empty the instant `resetAll()`'s transaction commits — proven directly by `test/presentation/reset_flow_test.dart`, which drives the real `AppShell` end-to-end.
- Subtask 4.7 (no other action gained a second confirmation step): verified by inspection — this story does not touch `archiveGoal`/`pauseGoal`/`resumeGoal` or their UI call sites at all, and the pre-existing `goal_detail_screen_test.dart` archive test (still passing, single tap, no dialog) is unchanged evidence of this.

### File List

- `lib/domain/services/goal_service.dart` — added `resetAll()`.
- `lib/domain/services/goal_repository.dart`, `goal_version_repository.dart`, `goal_log_repository.dart`, `blackout_date_repository.dart`, `cheat_day_repository.dart`, `status_cache_repository.dart` — added `deleteAll()` to each interface.
- `lib/domain/services/cache_writer.dart` — added `clearAll()`.
- `lib/domain/services/reminder_settings_repository.dart`, `week_start_settings_repository.dart` — added `clear()` to each interface.
- `lib/data/repositories/drift_goal_repository.dart`, `drift_goal_version_repository.dart`, `drift_goal_log_repository.dart`, `drift_blackout_date_repository.dart`, `drift_cheat_day_repository.dart`, `drift_status_cache_repository.dart` — implemented `deleteAll()`.
- `lib/data/cache/cache_writer_impl.dart` — implemented `clearAll()`.
- `lib/data/settings/shared_prefs_reminder_settings_repository.dart`, `shared_prefs_week_start_settings_repository.dart` — implemented `clear()`.
- `lib/presentation/providers/reset_provider.dart` (new) — `ResetController`.
- `lib/presentation/providers/reset_provider.g.dart` (generated, new).
- `lib/presentation/components/reset_confirmation_sheet.dart` (new) — the two-step confirmation modal sheet.
- `lib/presentation/screens/settings_screen.dart` — added the "Reset / Erase All" row.
- `test/domain/services/fakes.dart` — added `deleteAll()`/`clearAll()` to every affected in-memory fake; added `shouldFailOnDeleteAll` to `InMemoryGoalRepository`.
- `test/domain/services/goal_service_test.dart` — added the `resetAll` test group plus local settings-repo fakes.
- `test/data/io/json_exporter_test.dart`, `test/data/io/json_importer_test.dart` — added `deleteAll()`/`clear()` to their local write-tracking/settings fakes.
- `test/presentation/midnight_rollover_test.dart`, `reminder_settings_provider_test.dart`, `week_start_controller_test.dart`, `settings_screen_test.dart` — added `clear()` to their local settings fakes.
- `test/presentation/reset_flow_test.dart` (new) — full-`AppShell` two-step Reset flow, cancel-leaves-data-intact, and fresh-install equivalence across all four tabs.

## Change Log

- 2026-08-31: Story 6.3 implemented — `GoalService.resetAll()`, the Settings Reset/Erase-All two-step confirmation UI, and full test coverage (unit, transaction-atomicity, and full-app equivalence). Status set to `review`.
