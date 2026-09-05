import '../entities/time_of_day_value.dart';

/// The notification title/body for one day's reminder, as produced by a
/// [ReminderContentBuilder]. Returning `null` from the builder means "don't
/// show a reminder today" — Story 4.1 never returns `null` (it always uses
/// a fixed, unconditional body); Story 4.2 is the one that computes this
/// per-goal and may suppress the notification entirely.
class ReminderContent {
  const ReminderContent({required this.title, required this.body});

  final String title;
  final String body;
}

/// Builds the content for the next reminder firing. Invoked whenever the
/// scheduler (re)registers the daily notification, not at fire time itself
/// — `flutter_local_notifications`' daily-repeat mechanism fires a
/// previously-scheduled notification with content fixed at scheduling time,
/// so anything wanting fresher content (Story 4.2's per-goal eligibility)
/// must call `ReminderScheduler.scheduleDaily` again (e.g. from a
/// midnight-rollover hook) rather than relying on the OS to recompute it.
typedef ReminderContentBuilder = Future<ReminderContent?> Function();

/// Domain-defined, plugin-agnostic contract for the single global daily
/// reminder (FR-30). Implemented by a `flutter_local_notifications`-backed
/// class in `data`/`platform` — `flutter_local_notifications` is a Flutter
/// plugin, so it never appears inside `domain` (AD-1).
///
/// This story only schedules unconditionally; it does not decide whether a
/// reminder is worth showing today (that's Story 4.2, via [contentBuilder]).
abstract interface class ReminderScheduler {
  /// Initializes the underlying notification platform. Call once from the
  /// composition root before any [scheduleDaily] call.
  Future<void> initialize();

  /// (Re)registers one daily-repeating local notification at [time],
  /// entirely on-device (NFR-1, NFR-2). Calling this again with a new [time]
  /// or [contentBuilder] replaces whatever was previously scheduled — there
  /// is only ever one global reminder, never more than one pending.
  Future<void> scheduleDaily({
    required TimeOfDayValue time,
    required ReminderContentBuilder contentBuilder,
  });

  /// Cancels the currently-scheduled daily reminder, if any.
  Future<void> cancel();
}
