// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_wizard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives every step's UI (Subtask 1.3): validity of the current step is
/// exposed reactively so Next can enable/disable itself, and editing an
/// earlier answer (e.g. Tracking Type) resets dependent later state
/// (Subtask 1.5, AC #5) rather than leaving stale cached values in place.
/// `keepAlive: true` (Story 2.1 Task 4.3): edit-mode pre-fill is applied by
/// `loadForEdit` synchronously *before* the wizard route is pushed (from
/// `GoalDetailScreen`'s Edit button) — an autoDispose provider can be torn
/// down in the gap between that call and the new screen's first `watch`,
/// since nothing holds a listener across the navigation. Both entry points
/// (`DayViewScreen`'s "Create Goal" and `GoalDetailScreen`'s "Edit") fully
/// initialize the state they need before pushing, so nothing relies on the
/// *previous* session having cleaned up after itself on exit.

@ProviderFor(GoalWizard)
final goalWizardProvider = GoalWizardProvider._();

/// Drives every step's UI (Subtask 1.3): validity of the current step is
/// exposed reactively so Next can enable/disable itself, and editing an
/// earlier answer (e.g. Tracking Type) resets dependent later state
/// (Subtask 1.5, AC #5) rather than leaving stale cached values in place.
/// `keepAlive: true` (Story 2.1 Task 4.3): edit-mode pre-fill is applied by
/// `loadForEdit` synchronously *before* the wizard route is pushed (from
/// `GoalDetailScreen`'s Edit button) — an autoDispose provider can be torn
/// down in the gap between that call and the new screen's first `watch`,
/// since nothing holds a listener across the navigation. Both entry points
/// (`DayViewScreen`'s "Create Goal" and `GoalDetailScreen`'s "Edit") fully
/// initialize the state they need before pushing, so nothing relies on the
/// *previous* session having cleaned up after itself on exit.
final class GoalWizardProvider
    extends $NotifierProvider<GoalWizard, GoalWizardState> {
  /// Drives every step's UI (Subtask 1.3): validity of the current step is
  /// exposed reactively so Next can enable/disable itself, and editing an
  /// earlier answer (e.g. Tracking Type) resets dependent later state
  /// (Subtask 1.5, AC #5) rather than leaving stale cached values in place.
  /// `keepAlive: true` (Story 2.1 Task 4.3): edit-mode pre-fill is applied by
  /// `loadForEdit` synchronously *before* the wizard route is pushed (from
  /// `GoalDetailScreen`'s Edit button) — an autoDispose provider can be torn
  /// down in the gap between that call and the new screen's first `watch`,
  /// since nothing holds a listener across the navigation. Both entry points
  /// (`DayViewScreen`'s "Create Goal" and `GoalDetailScreen`'s "Edit") fully
  /// initialize the state they need before pushing, so nothing relies on the
  /// *previous* session having cleaned up after itself on exit.
  GoalWizardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalWizardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalWizardHash();

  @$internal
  @override
  GoalWizard create() => GoalWizard();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalWizardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalWizardState>(value),
    );
  }
}

String _$goalWizardHash() => r'ad4a2da4fb2b89293b22878a636850e3826a5b91';

/// Drives every step's UI (Subtask 1.3): validity of the current step is
/// exposed reactively so Next can enable/disable itself, and editing an
/// earlier answer (e.g. Tracking Type) resets dependent later state
/// (Subtask 1.5, AC #5) rather than leaving stale cached values in place.
/// `keepAlive: true` (Story 2.1 Task 4.3): edit-mode pre-fill is applied by
/// `loadForEdit` synchronously *before* the wizard route is pushed (from
/// `GoalDetailScreen`'s Edit button) — an autoDispose provider can be torn
/// down in the gap between that call and the new screen's first `watch`,
/// since nothing holds a listener across the navigation. Both entry points
/// (`DayViewScreen`'s "Create Goal" and `GoalDetailScreen`'s "Edit") fully
/// initialize the state they need before pushing, so nothing relies on the
/// *previous* session having cleaned up after itself on exit.

abstract class _$GoalWizard extends $Notifier<GoalWizardState> {
  GoalWizardState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GoalWizardState, GoalWizardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GoalWizardState, GoalWizardState>,
              GoalWizardState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
