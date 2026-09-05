// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_date_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(currentDate)
final currentDateProvider = CurrentDateProvider._();

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

final class CurrentDateProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, Stream<DateTime>>
    with $FutureModifier<DateTime>, $StreamProvider<DateTime> {
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
  CurrentDateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentDateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentDateHash();

  @$internal
  @override
  $StreamProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime> create(Ref ref) {
    return currentDate(ref);
  }
}

String _$currentDateHash() => r'49e5b909a7c16cb09d8f6281c7c2aedc7ebd493b';
