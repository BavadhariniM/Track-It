// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'in_flight_edit_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The single Counter direct-entry dialog that may be mid-edit at once —
/// the dialog is modal, so only one can be open at a time. `null` means no
/// uncommitted entry exists right now.
///
/// Presentation-layer-only state (AD-1): `domain` never learns this exists.
/// The midnight-rollover watcher is the only reader that turns this into a
/// `GoalService.logCounter` call, and only ever with the explicit `date`
/// already captured here — it never resolves a fresh "today".

@ProviderFor(InFlightEdit)
final inFlightEditProvider = InFlightEditProvider._();

/// The single Counter direct-entry dialog that may be mid-edit at once —
/// the dialog is modal, so only one can be open at a time. `null` means no
/// uncommitted entry exists right now.
///
/// Presentation-layer-only state (AD-1): `domain` never learns this exists.
/// The midnight-rollover watcher is the only reader that turns this into a
/// `GoalService.logCounter` call, and only ever with the explicit `date`
/// already captured here — it never resolves a fresh "today".
final class InFlightEditProvider
    extends $NotifierProvider<InFlightEdit, InFlightCounterEdit?> {
  /// The single Counter direct-entry dialog that may be mid-edit at once —
  /// the dialog is modal, so only one can be open at a time. `null` means no
  /// uncommitted entry exists right now.
  ///
  /// Presentation-layer-only state (AD-1): `domain` never learns this exists.
  /// The midnight-rollover watcher is the only reader that turns this into a
  /// `GoalService.logCounter` call, and only ever with the explicit `date`
  /// already captured here — it never resolves a fresh "today".
  InFlightEditProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inFlightEditProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inFlightEditHash();

  @$internal
  @override
  InFlightEdit create() => InFlightEdit();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InFlightCounterEdit? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InFlightCounterEdit?>(value),
    );
  }
}

String _$inFlightEditHash() => r'd274ab0aaec8075494caa57587edd19bd69f05c3';

/// The single Counter direct-entry dialog that may be mid-edit at once —
/// the dialog is modal, so only one can be open at a time. `null` means no
/// uncommitted entry exists right now.
///
/// Presentation-layer-only state (AD-1): `domain` never learns this exists.
/// The midnight-rollover watcher is the only reader that turns this into a
/// `GoalService.logCounter` call, and only ever with the explicit `date`
/// already captured here — it never resolves a fresh "today".

abstract class _$InFlightEdit extends $Notifier<InFlightCounterEdit?> {
  InFlightCounterEdit? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<InFlightCounterEdit?, InFlightCounterEdit?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InFlightCounterEdit?, InFlightCounterEdit?>,
              InFlightCounterEdit?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
