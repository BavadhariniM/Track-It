// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reset_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Story 6.3 (FR-36): the Settings screen's Reset/Erase-All write path. The
/// actual delete-everything/clear-settings logic lives entirely inside
/// `GoalService.resetAll()` (AD-6) — this controller's only job is
/// resolving the two settings repositories that method needs (unavoidably
/// async, since both sit behind `SharedPreferences.getInstance()`) and then
/// resetting the two live, synchronously-watched Settings values so every
/// screen reflects the fresh-install state immediately, with no app restart
/// required (AC #4). Every other screen (Dashboard, Goals, Calendar) needs
/// no equivalent nudge — they all read Goal/Version/Log data straight off
/// Drift's own `.watch()` streams, which already re-emit empty the instant
/// `resetAll()`'s transaction commits.
///
/// `keepAlive: true` for the same reason `ReminderTimeController`/
/// `WeekStartController` are: invoked via `ref.read` as a plain action call,
/// so nothing else keeps this provider's default auto-dispose lifetime
/// alive across its awaits.

@ProviderFor(ResetController)
final resetControllerProvider = ResetControllerProvider._();

/// Story 6.3 (FR-36): the Settings screen's Reset/Erase-All write path. The
/// actual delete-everything/clear-settings logic lives entirely inside
/// `GoalService.resetAll()` (AD-6) — this controller's only job is
/// resolving the two settings repositories that method needs (unavoidably
/// async, since both sit behind `SharedPreferences.getInstance()`) and then
/// resetting the two live, synchronously-watched Settings values so every
/// screen reflects the fresh-install state immediately, with no app restart
/// required (AC #4). Every other screen (Dashboard, Goals, Calendar) needs
/// no equivalent nudge — they all read Goal/Version/Log data straight off
/// Drift's own `.watch()` streams, which already re-emit empty the instant
/// `resetAll()`'s transaction commits.
///
/// `keepAlive: true` for the same reason `ReminderTimeController`/
/// `WeekStartController` are: invoked via `ref.read` as a plain action call,
/// so nothing else keeps this provider's default auto-dispose lifetime
/// alive across its awaits.
final class ResetControllerProvider
    extends $AsyncNotifierProvider<ResetController, void> {
  /// Story 6.3 (FR-36): the Settings screen's Reset/Erase-All write path. The
  /// actual delete-everything/clear-settings logic lives entirely inside
  /// `GoalService.resetAll()` (AD-6) — this controller's only job is
  /// resolving the two settings repositories that method needs (unavoidably
  /// async, since both sit behind `SharedPreferences.getInstance()`) and then
  /// resetting the two live, synchronously-watched Settings values so every
  /// screen reflects the fresh-install state immediately, with no app restart
  /// required (AC #4). Every other screen (Dashboard, Goals, Calendar) needs
  /// no equivalent nudge — they all read Goal/Version/Log data straight off
  /// Drift's own `.watch()` streams, which already re-emit empty the instant
  /// `resetAll()`'s transaction commits.
  ///
  /// `keepAlive: true` for the same reason `ReminderTimeController`/
  /// `WeekStartController` are: invoked via `ref.read` as a plain action call,
  /// so nothing else keeps this provider's default auto-dispose lifetime
  /// alive across its awaits.
  ResetControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resetControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resetControllerHash();

  @$internal
  @override
  ResetController create() => ResetController();
}

String _$resetControllerHash() => r'21d61d816d86c6a573f9d663c8530f8c89bd339c';

/// Story 6.3 (FR-36): the Settings screen's Reset/Erase-All write path. The
/// actual delete-everything/clear-settings logic lives entirely inside
/// `GoalService.resetAll()` (AD-6) — this controller's only job is
/// resolving the two settings repositories that method needs (unavoidably
/// async, since both sit behind `SharedPreferences.getInstance()`) and then
/// resetting the two live, synchronously-watched Settings values so every
/// screen reflects the fresh-install state immediately, with no app restart
/// required (AC #4). Every other screen (Dashboard, Goals, Calendar) needs
/// no equivalent nudge — they all read Goal/Version/Log data straight off
/// Drift's own `.watch()` streams, which already re-emit empty the instant
/// `resetAll()`'s transaction commits.
///
/// `keepAlive: true` for the same reason `ReminderTimeController`/
/// `WeekStartController` are: invoked via `ref.read` as a plain action call,
/// so nothing else keeps this provider's default auto-dispose lifetime
/// alive across its awaits.

abstract class _$ResetController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
