import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'current_date_provider.dart';
import 'goal_service_provider.dart';
import 'in_flight_edit_provider.dart';
import 'reminder_settings_provider.dart';

part 'midnight_rollover_provider.g.dart';

/// Watches [currentDateProvider] for the local calendar date advancing
/// while the app is open and, when it does, auto-commits any in-flight
/// Counter direct-entry edit (Task 1) against the date it was entered on —
/// the *pre*-rollover date, from [InFlightCounterEdit.date] — rather than
/// letting it sit unsaved and vulnerable to being lost if the app is later
/// killed (FR-19/FR-20).
///
/// This is purely a *caller* of `GoalService.logCounter` — the exact same
/// entry point any user-triggered log write calls (AD-6), never a bypass
/// write path — with the `date` argument pinned to whatever value the
/// in-flight edit already captured explicitly when its dialog opened
/// (Subtask 1.3). `domain` never learns "midnight" exists as a concept
/// (AD-1); this provider is the entire extent of that awareness, and
/// `GoalService`'s signature is unchanged.
///
/// Instantiated once at the composition root (`main.dart`'s `TrackerApp`)
/// so it observes for the app's whole lifetime; `keepAlive: true` so it is
/// never accidentally disposed while no screen happens to be watching it.
@Riverpod(keepAlive: true)
class MidnightRolloverWatcher extends _$MidnightRolloverWatcher {
  DateTime? _lastSeenDate;

  @override
  void build() {
    ref.listen<AsyncValue<DateTime>>(currentDateProvider, (previous, next) {
      next.whenData(_onDateObserved);
    }, fireImmediately: true);
  }

  Future<void> _onDateObserved(DateTime date) async {
    final previouslySeen = _lastSeenDate;
    _lastSeenDate = date;

    // The first observed date only establishes the baseline; it is not
    // itself a rollover.
    if (previouslySeen == null || date == previouslySeen) return;

    await _commitInFlightEdit();
    await _rescheduleReminderIfSet();
  }

  Future<void> _commitInFlightEdit() async {
    final inFlight = ref.read(inFlightEditProvider);
    if (inFlight == null) return;

    final delta = double.tryParse(inFlight.text);
    if (delta != null) {
      await ref
          .read(goalServiceProvider)
          .logCounter(
            goalId: inFlight.goalId,
            date: inFlight.date,
            delta: delta,
          );
    }

    // Either committed above, or there was nothing parseable to commit —
    // either way this in-flight edit no longer belongs to "now". Clearing
    // it signals the still-open dialog (if any) to close itself silently
    // (UX-DR21 — no interstitial/toast), since it was targeting a day that
    // is no longer the one being viewed.
    ref.read(inFlightEditProvider.notifier).clear();
  }

  /// Story 4.2: re-registers the daily reminder with freshly-computed
  /// suppression-aware content on every rollover, since
  /// `flutter_local_notifications` bakes notification content in at
  /// scheduling time rather than recomputing it when the notification
  /// actually fires (see `ReminderContentBuilder`'s doc comment) — without
  /// this, a reminder registered yesterday would keep showing yesterday's
  /// goal list until the next time Settings or app-open happened to
  /// re-register it. No-ops if Panda has never configured a reminder time.
  Future<void> _rescheduleReminderIfSet() async {
    final time = await ref.read(reminderTimeProvider.future);
    if (time == null) return;

    await ref
        .read(reminderSchedulerProvider)
        .scheduleDaily(
          time: time,
          contentBuilder: buildSuppressionAwareReminderContent(ref),
        );
  }
}
