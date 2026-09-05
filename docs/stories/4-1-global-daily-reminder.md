---
baseline_commit: NO_VCS
---

# Story 4.1: Global Daily Reminder

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to set a single reminder time that applies across all goals,
so that I get nudged once a day without configuring each goal individually.

## Acceptance Criteria

1. **Given** Settings **When** Panda sets a reminder time **Then** it's stored via `shared_preferences` (AD-3 settings exception) and applies globally across all goals — no per-goal custom time exists (FR-30)
2. **Given** the reminder time is set **When** the scheduled time arrives **Then** `flutter_local_notifications` fires one local notification, entirely offline, with no third-party network call (NFR-1, NFR-2)
3. **Given** the Dashboard (Story 3.1) **When** it renders **Then** it shows this same next scheduled reminder time (FR-26 cross-reference)
4. **And** if the device reboots after a reminder time was previously set, the scheduled notification re-registers correctly rather than silently disappearing

## Tasks / Subtasks

- [x] Task 1: Add reminder-time settings persistence (AC: #1)
  - [x] 1.1 Add a `ReminderSettingsRepository` (or extend an existing settings repository) in `lib/domain/services/` as an interface with `Future<TimeOfDayValue?> getReminderTime()` and `Future<void> setReminderTime(TimeOfDayValue time)` — domain-defined interface, zero Flutter/Drift/`shared_preferences` imports in `domain` (AD-1).
  - [x] 1.2 Implement the interface in `lib/data/` (e.g. `lib/data/settings/shared_prefs_reminder_settings_repository.dart`) backed by `shared_preferences`, storing the reminder time as a simple serializable value (e.g. minutes-since-midnight int, or `"HH:mm"` string) — this is the one explicit exception to Drift-only persistence (AD-3).
  - [x] 1.3 Expose the repository via a Riverpod `@riverpod` provider (AD-2) in `lib/presentation/providers/` — no service-locator/singleton access.
  - [x] 1.4 Add a Settings screen control (`lib/presentation/screens/`) for picking the reminder time (platform time picker), writing through the provider from 1.3. No per-goal time field exists anywhere in the UI or data model.
- [x] Task 2: Build the notification scheduling service (AC: #2, #4)
  - [x] 2.1 Add `flutter_local_notifications` (pinned seed version 21.0.0 — re-verify at `flutter pub add` time per architecture's own caveat) and initialize it in the composition root, wiring Android/iOS platform-specific initialization settings.
  - [x] 2.2 Create a `ReminderScheduler` in `lib/domain/services/` defining the scheduling contract (interface only, no I/O) — the concrete `flutter_local_notifications` implementation lives in `lib/data/` (or a thin platform-facing wrapper under `lib/platform/`), keeping `domain` free of Flutter plugin imports (AD-1).
  - [x] 2.3 Implement daily-repeating local notification scheduling for the single global time using `flutter_local_notifications`' exact-alarm/daily-repeat API, entirely on-device — verify no network permission or call is introduced (NFR-1, NFR-2).
  - [x] 2.4 Reschedule the notification whenever the reminder time changes (call scheduler from the Settings write path in Task 1.4).
  - [x] 2.5 Register a boot-completed receiver (Android `RECEIVE_BOOT_COMPLETED` + rebroadcast re-scheduling logic; iOS local notifications persist across reboot by OS design, but confirm re-registration still occurs if the app was force-quit) so a previously-set reminder re-registers after device reboot without user action (AC #4).
- [x] Task 3: Surface the next reminder time on the Dashboard (AC: #3)
  - [x] 3.1 Read the stored reminder time via the provider from Task 1.3 in the Dashboard screen/widget (Story 3.1's surface) and render it as the "next scheduled reminder time," reusing existing typography tokens — no new component needed for a single time string.
- [x] Task 4: Testing (AC: #1-#4)
  - [x] 4.1 Unit test the `shared_preferences`-backed repository: set/get round-trip, absence-of-value default behavior (no reminder configured yet).
  - [x] 4.2 Unit/widget test that the Settings time picker writes through the provider and triggers a reschedule call (mock `ReminderScheduler`).
  - [x] 4.3 Widget test that Dashboard renders the stored reminder time (or an appropriate empty/unset state) reactively when the Riverpod provider value changes.
  - [x] 4.4 Manual/platform verification checklist (cannot be fully unit-tested): notification actually fires at the configured time on both Android and iOS; notification survives a device reboot; no network permission is requested or used anywhere in this flow. **Checklist authored below in Completion Notes — execution against a real device/simulator is outside what an automated dev pass can perform and remains an open manual follow-up before this story is considered field-verified.**

## Dev Notes

- **Offline/telemetry constraint (NFR-1, NFR-2):** This entire story must be implementable and testable with the device in airplane mode. `flutter_local_notifications` is a local-only plugin — do not add any remote-push counterpart (no FCM/APNs remote registration). No analytics/crash-reporting SDK may be introduced to instrument notification delivery.
- **`shared_preferences` is the deliberate, sole exception to Drift** (AD-3): "all local persistence of domain data goes through Drift... `shared_preferences` (or equivalent) is permitted only for simple user settings (week-start day, reminder time) that are not part of the Goal/Version/Log model." The reminder time is explicitly named in the architecture spine as belonging here — do not add a Drift table for it. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-3]
- **Single global time, no per-goal times, ever:** FR-30 is explicit that there is no per-goal custom time. Do not design the settings schema or UI in a way that implies per-goal times are a future toggle on this same screen — that is out of scope for the entire product, not just this story.
- **Layering (AD-1):** `domain` must define the scheduling and settings-repository interfaces with zero Flutter or plugin imports; `data`/`platform` implement them. `flutter_local_notifications` is a Flutter plugin, so its calls belong in `data`/`platform`, never directly inside `domain` use-cases or entities.
- **DI (AD-2):** every cross-layer wire-up (the settings repository, the scheduler) must be exposed as a Riverpod `@riverpod` (code-gen, 3.x line) provider from the composition root. No singleton/service-locator pattern for the notifications plugin instance.
- **Reboot re-registration (AC #4):** `flutter_local_notifications`'s scheduled notifications are generally OS-persisted, but Android requires the app to explicitly listen for `BOOT_COMPLETED` and re-schedule if the plugin's own daily-repeat mechanism doesn't survive a reboot on the target OS version — verify against the pinned plugin version's current documented behavior at implementation time (re-verify per the architecture's own "re-verify at build time" caveat on `flutter_local_notifications 21.0.0`). Do not assume silently that "it just works" — this AC exists because that's exactly the class of bug that would otherwise go unnoticed until a real device reboot.
- **This story only schedules; it does not suppress.** Story 4.1 fires one notification per day at the configured time, unconditionally with respect to goal content — the "does this goal deserve to be in today's reminder" logic (eligibility, paused/archived, target-already-met, the At-Least exception) is entirely Story 4.2's responsibility, layered on top of this scheduling mechanism. Do not build any goal-filtering logic into the scheduler itself in this story; the scheduler's job here is purely "fire at time X, daily, offline, survive reboot." Story 4.2 will need a hook point (e.g. a callback or a notification-content-builder invoked at fire time, or at minimum a build step just before scheduling/firing) where it can compute which goals to mention, or suppress the notification body/entirely, using Epic 1's `evaluate()` output. Design the scheduler's API in Task 2.2 with this in mind — e.g. accept a content-provider/builder rather than a hardcoded notification body — so Story 4.2 does not need to rewrite the scheduling plumbing.
- **Testing standards:** Domain-level settings repository and scheduler interfaces should be fully unit-testable with fakes/mocks (no real `shared_preferences` or `flutter_local_notifications` I/O needed for logic tests). Actual notification firing and reboot survival cannot be verified by automated unit tests alone — call this out explicitly as a manual/platform verification item, per NFR-6's "correctness as a first-class acceptance bar" applying even to things automated tests can't fully cover.

### Project Structure Notes

- New/changed files align with the structural seed: `lib/domain/services/` (new interfaces: reminder settings repository, `ReminderScheduler`), `lib/data/` (new: `shared_preferences`-backed settings repository implementation, `flutter_local_notifications`-backed scheduler implementation), `lib/presentation/providers/` (new Riverpod providers), `lib/presentation/screens/` (Settings screen reminder-time control; Dashboard screen gains the "next reminder" read), `lib/platform/android/` and `lib/platform/ios/` (boot-receiver / platform notification permission wiring, if required beyond what the plugin auto-generates). [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed]
- No new Drift tables are introduced by this story — reminder time is `shared_preferences`-only, per AD-3's explicit settings exception. This is a deliberate, documented variance from "Drift is the sole local persistence for domain data," because reminder time is not domain data (a Goal/Version/Log), it's a simple setting.
- Settings screen itself is a pre-existing structural element (`lib/presentation/screens/`) per the Structural Seed and the IA table in `EXPERIENCE.md` ("Settings | Tab bar | Week-start day, global reminder time, categories, export, import, reset") — this story adds the reminder-time control to that screen, it does not create the screen's overall shell (other Settings items — week-start day, categories, export/import/reset — are delivered by other stories/epics).

### References

- [Source: docs/epics.md#Story 4.1] — user story statement and acceptance criteria (Given/When/Then blocks) verbatim basis for this file.
- [Source: docs/epics.md#Requirements Inventory] — FR-30 (Local Reminders, single global time, At-Least exception noted for Story 4.2), NFR-1 (Offline-First), NFR-2 (Zero Telemetry).
- [Source: docs/epics.md#Additional Requirements] — AD-1 (layering), AD-2 (Riverpod DI), AD-3 (`shared_preferences` settings exception), Stack table (`flutter_local_notifications 21.0.0`, "re-verify at build time" caveat).
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-1] — Layered/Hexagonal Paradigm.
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-2] — Riverpod for State & Dependency Injection.
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-3] — Drift as Sole Local Persistence (settings exception).
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Stack] — `flutter_local_notifications 21.0.0` pinned seed version.
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed] — file/folder layout (`lib/domain/services/`, `lib/data/`, `lib/presentation/providers/`, `lib/presentation/screens/`, `lib/platform/`).
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Consistency Conventions] — "Simple user settings (week-start day, global reminder time) via `shared_preferences`, outside the Drift schema."
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Information Architecture] — Settings surface IA row listing "global reminder time" among Settings contents.
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Key Flows] — "Panda sets up an exotic goal" flow references the wizard's reminders step opting into the single global reminder time.
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Voice and Tone] — UX-DR19 copy-tone constraints (no exclamation points, plain declarative copy) apply to any Settings copy or notification body text this story introduces.
- [Source: docs/epics.md#Story 3.1] — Dashboard's "next scheduled reminder time" display this story must satisfy (FR-26 cross-reference).

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `flutter pub add flutter_local_notifications` resolved to `22.3.0` (pinned architecture seed was `21.0.0`; re-verified per the architecture's own "re-verify at build time" caveat — `22.3.0` is what pub.dev actually resolves to today, and its `zonedSchedule`/`AndroidNotificationDetails`/`initialize` API surfaces were confirmed by reading the installed package source directly).
- Also added `flutter_timezone` (^5.1.0) and promoted `timezone` (transitive → direct) — undocumented in the architecture's Stack table, but required for `zonedSchedule` to fire at the device's actual local time rather than UTC; without a real IANA zone the daily-repeat time would silently drift by the local UTC offset.
- `flutter pub add` and `dart run build_runner build` both emitted a trailing "Flutter failed to delete a directory ... .plugin_symlinks" / OneDrive-lock error after otherwise completing successfully (pubspec.yaml/lock and generated `.g.dart` files were all written correctly) — a known transient OneDrive file-lock on this machine, not a real failure.
- `flutter analyze` and `flutter test` (full suite, 283 tests) both pass clean after all changes.

### Completion Notes List

- Implemented the domain-defined `ReminderSettingsRepository`/`TimeOfDayValue` pair and its `shared_preferences`-backed implementation (AD-1/AD-3), reusing the exact `global_reminder_time` / `"HH:mm"` storage contract that Story 3.1's placeholder `reminder_time_provider.dart` had already committed to reading — that placeholder file (and its `.g.dart`) has been deleted and replaced by `reminder_settings_provider.dart`, which now owns both the read side (`reminderTimeProvider`) and the new write side (`ReminderTimeController`).
- `ReminderScheduler`'s `scheduleDaily` takes a `contentBuilder` callback (invoked at scheduling time, not at fire time) specifically so Story 4.2 can later swap in per-goal eligibility content without touching the scheduling plumbing itself — Story 4.1's own builder (`_defaultReminderContent`) is fixed and unconditional, per this story's explicit "does not suppress" boundary.
- `ReminderTimeController` is `keepAlive: true`: it's driven via `ref.read(...).setReminderTime(...)` (an action call, not a `watch`), and Riverpod's default auto-dispose lifetime tears an unwatched provider down as soon as the synchronous call returns — which surfaced as an `UnmountedRefException` mid-`await` in the first test run until this was added. Worth remembering for any future action-style controller in this codebase.
- Android's reboot re-registration (AC #4) relies on `flutter_local_notifications`' own bundled boot receiver, activated purely by declaring `RECEIVE_BOOT_COMPLETED` (and `SCHEDULE_EXACT_ALARM`, required for `AndroidScheduleMode.exactAllowWhileIdle`) in `AndroidManifest.xml` — no custom receiver code was written. `main.dart`'s new `reminderInitializerProvider` additionally re-registers the reminder on every app launch, covering the force-quit case a boot receiver alone wouldn't reach.
- Settings screen only implements the reminder-time row (this story's scope); the other Settings IA rows (week-start day, categories, export/import, reset) are explicitly out of scope and left for their own stories.
- **Manual/platform verification checklist (Subtask 4.4 — not executable from this automated session, no physical device/simulator available):**
  1. Set a reminder time in Settings on a real Android device; confirm the notification fires at that exact wall-clock time.
  2. Repeat on a real iOS device/simulator.
  3. Reboot the Android device after setting a reminder; confirm it still fires the next day without reopening the app.
  4. Force-quit (not reboot) the app on both platforms after setting a reminder; confirm it still fires.
  5. With the device in airplane mode throughout, confirm the notification still fires and no network permission prompt or traffic ever appears (NFR-1/NFR-2).

### File List

**New:**
- `lib/domain/entities/time_of_day_value.dart`
- `lib/domain/services/reminder_settings_repository.dart`
- `lib/domain/services/reminder_scheduler.dart`
- `lib/data/settings/shared_prefs_reminder_settings_repository.dart`
- `lib/data/notifications/flutter_local_notifications_reminder_scheduler.dart`
- `lib/presentation/providers/reminder_settings_provider.dart`
- `lib/presentation/providers/reminder_settings_provider.g.dart`
- `lib/presentation/screens/settings_screen.dart`
- `test/domain/entities/time_of_day_value_test.dart`
- `test/data/settings/shared_prefs_reminder_settings_repository_test.dart`
- `test/presentation/reminder_settings_provider_test.dart`
- `test/presentation/settings_screen_test.dart`

**Modified:**
- `pubspec.yaml` / `pubspec.lock` — added `flutter_local_notifications`, `flutter_timezone`, `timezone`
- `android/app/src/main/AndroidManifest.xml` — `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM` permissions
- `lib/main.dart` — startup reminder re-registration hook
- `lib/presentation/screens/app_shell.dart` — wired real `SettingsScreen` in place of the Story 3.1 placeholder
- `lib/presentation/screens/dashboard_screen.dart` — reads the new `reminderTimeProvider` (now `TimeOfDayValue?`-typed)
- `test/presentation/dashboard_screen_test.dart` — updated for the `TimeOfDayValue`-typed provider
- `test/presentation/app_shell_test.dart` — updated import for the renamed provider file
- `test/presentation/month_view_test.dart` — updated import for the renamed provider file
- `test/presentation/streak_consistency_test.dart` — updated import for the renamed provider file

**Deleted:**
- `lib/presentation/providers/reminder_time_provider.dart` (Story 3.1 placeholder, superseded)
- `lib/presentation/providers/reminder_time_provider.g.dart`
