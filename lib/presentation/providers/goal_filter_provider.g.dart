// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Story 3.5 Subtask 3.2: the Calendar's currently-applied [GoalFilter],
/// defaulting to "all Goals" (AC 3). `keepAlive: true` — same reasoning as
/// `GoalWizard` (Story 2.1) — so the selection survives navigating between
/// the Day/Week/Month calendar screens within a session rather than
/// resetting to All on every screen push, without persisting across app
/// restarts (not specified, Subtask 3.2).

@ProviderFor(SelectedGoalFilter)
final selectedGoalFilterProvider = SelectedGoalFilterProvider._();

/// Story 3.5 Subtask 3.2: the Calendar's currently-applied [GoalFilter],
/// defaulting to "all Goals" (AC 3). `keepAlive: true` — same reasoning as
/// `GoalWizard` (Story 2.1) — so the selection survives navigating between
/// the Day/Week/Month calendar screens within a session rather than
/// resetting to All on every screen push, without persisting across app
/// restarts (not specified, Subtask 3.2).
final class SelectedGoalFilterProvider
    extends $NotifierProvider<SelectedGoalFilter, GoalFilter> {
  /// Story 3.5 Subtask 3.2: the Calendar's currently-applied [GoalFilter],
  /// defaulting to "all Goals" (AC 3). `keepAlive: true` — same reasoning as
  /// `GoalWizard` (Story 2.1) — so the selection survives navigating between
  /// the Day/Week/Month calendar screens within a session rather than
  /// resetting to All on every screen push, without persisting across app
  /// restarts (not specified, Subtask 3.2).
  SelectedGoalFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedGoalFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedGoalFilterHash();

  @$internal
  @override
  SelectedGoalFilter create() => SelectedGoalFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalFilter>(value),
    );
  }
}

String _$selectedGoalFilterHash() =>
    r'd760d0b4060f29888bd45845ade626d59ceb2934';

/// Story 3.5 Subtask 3.2: the Calendar's currently-applied [GoalFilter],
/// defaulting to "all Goals" (AC 3). `keepAlive: true` — same reasoning as
/// `GoalWizard` (Story 2.1) — so the selection survives navigating between
/// the Day/Week/Month calendar screens within a session rather than
/// resetting to All on every screen push, without persisting across app
/// restarts (not specified, Subtask 3.2).

abstract class _$SelectedGoalFilter extends $Notifier<GoalFilter> {
  GoalFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GoalFilter, GoalFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GoalFilter, GoalFilter>,
              GoalFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
