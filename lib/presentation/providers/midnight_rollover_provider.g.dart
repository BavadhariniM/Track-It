// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'midnight_rollover_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(MidnightRolloverWatcher)
final midnightRolloverWatcherProvider = MidnightRolloverWatcherProvider._();

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
final class MidnightRolloverWatcherProvider
    extends $NotifierProvider<MidnightRolloverWatcher, void> {
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
  MidnightRolloverWatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'midnightRolloverWatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$midnightRolloverWatcherHash();

  @$internal
  @override
  MidnightRolloverWatcher create() => MidnightRolloverWatcher();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$midnightRolloverWatcherHash() =>
    r'51489a8d63391470153763b69ce20759f434e866';

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

abstract class _$MidnightRolloverWatcher extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
