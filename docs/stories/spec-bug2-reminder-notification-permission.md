---
title: 'Bug 2: Daily reminder never fires because notification permission is never requested'
type: 'bugfix'
created: '2026-08-31'
status: 'done'
route: 'one-shot'
---

## Intent

**Problem:** Panda can set a daily reminder time in Settings, and `FlutterLocalNotificationsReminderScheduler` does successfully call `zonedSchedule` — but the app never requests the Android runtime notification permission (`POST_NOTIFICATIONS`, required on API 33+) or the exact-alarm permission, so the OS silently drops every scheduled reminder. The reminder is effectively always disabled, with no error surfaced anywhere.

**Approach:** Declare `POST_NOTIFICATIONS` in `AndroidManifest.xml` and request both it and the exact-alarm permission from `FlutterLocalNotificationsReminderScheduler.initialize()` — the composition-root call already run once at every app startup, before any `scheduleDaily` call, so every reminder registration (Settings, app-open re-registration, midnight rollover) benefits without changing any of those call sites.

## Suggested Review Order

**Permission declaration**

- New `POST_NOTIFICATIONS` entry alongside the existing boot/exact-alarm permissions.
  [`AndroidManifest.xml:8`](../../android/app/src/main/AndroidManifest.xml#L8)

**Runtime permission request**

- `initialize()` now requests both the notification and exact-alarm permissions via the Android-specific plugin implementation, resolving to `null` (a no-op) on iOS — where `DarwinInitializationSettings()`'s own default permission flags already cover the equivalent prompt.
  [`flutter_local_notifications_reminder_scheduler.dart:33`](../../lib/data/notifications/flutter_local_notifications_reminder_scheduler.dart#L33)

**Deferred (see `deferred-work.md`)**

- No UI feedback if Panda denies either permission — Settings still shows the reminder as configured with no indication it won't fire.
- `reminderInitializer`'s `AsyncValue` is watched but never inspected in `main.dart`, so a thrown permission-request error would silently stop reminders again.
- `FlutterLocalNotificationsReminderScheduler` has no test coverage at all, before or after this fix.
- The unconditional cold-start permission prompt (no rationale) and exact-alarm Settings redirect are a UX/Play-Store-policy question, not addressed here.
