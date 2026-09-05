import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_date_provider.g.dart';

/// The device clock's current calendar date, with no time-of-day component
/// (NFR-3) — a plain synchronous read, shared by [currentDate] (the live,
/// rollover-detecting stream below) and by one-shot callers like Story 4.2's
/// reminder content builder that just need "what date is it right now"
/// without subscribing to change notifications.
DateTime todayDateOnly() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// The local device's current calendar date (date-only — no time-of-day
/// component, and no timezone/DST awareness beyond whatever the device's
/// own clock reports, per NFR-3), re-emitted whenever it changes while the
/// app stays open.
///
/// This is the single source of "today" every rollover-aware consumer
/// watches, instead of each capturing `DateTime.now()` independently (e.g.
/// once in an `initState`) and silently going stale across a midnight
/// boundary. Detecting a wall-clock date change is fundamentally an I/O /
/// platform-clock concern, so it lives here in `presentation`, never in
/// `domain` (AD-1) — `domain`'s `evaluate()`/`GoalService` never learn
/// "midnight" exists as a concept; they only ever receive an
/// already-resolved date.
///
/// Overridden in tests with a controllable stream (backed by a
/// `StreamController<DateTime>`) so a midnight rollover can be simulated
/// deterministically without waiting on real wall-clock time — the same
/// `ProviderScope`-override pattern every other I/O-backed provider in this
/// app uses (see `goalRepositoryProvider` etc., and
/// `test/presentation/midnight_rollover_test.dart`).
@riverpod
Stream<DateTime> currentDate(Ref ref) {
  final controller = StreamController<DateTime>();
  Timer? timer;
  var last = todayDateOnly();

  controller.onListen = () {
    controller.add(last);
    // Polling at a 1-second granularity is cheap (a single DateTime
    // comparison) and only ever produces a new event on an actual calendar
    // date change, which happens at most once a day.
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = todayDateOnly();
      if (now != last) {
        last = now;
        controller.add(now);
      }
    });
  };
  controller.onCancel = () => timer?.cancel();

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
}
