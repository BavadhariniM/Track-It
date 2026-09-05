// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'week_start_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Week-Start setting (FR-24): which weekday Week View's and Month
/// View's first grid column is, and the exact same value handed to
/// `evaluate()`'s `weekStart` parameter so the visual calendar grid and the
/// evaluator's own Weekly-period boundary calculation never disagree about
/// where a week starts (Story 1.10 Dev Notes).
///
/// Stays a plain, synchronously-watched [WeekStart] (never an `AsyncValue`)
/// for every existing reader (`week_view.dart`, `month_view.dart`,
/// `stats_providers.dart`, `widget_bridge_provider.dart`) — [weekStartInitializerProvider]
/// hydrates it from persisted storage once at startup instead of making this
/// provider itself async. It is overridable in tests via `ProviderScope`
/// overrides, exactly like `goalRepositoryProvider` etc. (see
/// `test/presentation/day_view_test.dart` for the pattern).

@ProviderFor(WeekStartSetting)
final weekStartSettingProvider = WeekStartSettingProvider._();

/// The Week-Start setting (FR-24): which weekday Week View's and Month
/// View's first grid column is, and the exact same value handed to
/// `evaluate()`'s `weekStart` parameter so the visual calendar grid and the
/// evaluator's own Weekly-period boundary calculation never disagree about
/// where a week starts (Story 1.10 Dev Notes).
///
/// Stays a plain, synchronously-watched [WeekStart] (never an `AsyncValue`)
/// for every existing reader (`week_view.dart`, `month_view.dart`,
/// `stats_providers.dart`, `widget_bridge_provider.dart`) — [weekStartInitializerProvider]
/// hydrates it from persisted storage once at startup instead of making this
/// provider itself async. It is overridable in tests via `ProviderScope`
/// overrides, exactly like `goalRepositoryProvider` etc. (see
/// `test/presentation/day_view_test.dart` for the pattern).
final class WeekStartSettingProvider
    extends $NotifierProvider<WeekStartSetting, WeekStart> {
  /// The Week-Start setting (FR-24): which weekday Week View's and Month
  /// View's first grid column is, and the exact same value handed to
  /// `evaluate()`'s `weekStart` parameter so the visual calendar grid and the
  /// evaluator's own Weekly-period boundary calculation never disagree about
  /// where a week starts (Story 1.10 Dev Notes).
  ///
  /// Stays a plain, synchronously-watched [WeekStart] (never an `AsyncValue`)
  /// for every existing reader (`week_view.dart`, `month_view.dart`,
  /// `stats_providers.dart`, `widget_bridge_provider.dart`) — [weekStartInitializerProvider]
  /// hydrates it from persisted storage once at startup instead of making this
  /// provider itself async. It is overridable in tests via `ProviderScope`
  /// overrides, exactly like `goalRepositoryProvider` etc. (see
  /// `test/presentation/day_view_test.dart` for the pattern).
  WeekStartSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekStartSettingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekStartSettingHash();

  @$internal
  @override
  WeekStartSetting create() => WeekStartSetting();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeekStart value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeekStart>(value),
    );
  }
}

String _$weekStartSettingHash() => r'1b983616803d138741cbf98fcd15ce7cc8985408';

/// The Week-Start setting (FR-24): which weekday Week View's and Month
/// View's first grid column is, and the exact same value handed to
/// `evaluate()`'s `weekStart` parameter so the visual calendar grid and the
/// evaluator's own Weekly-period boundary calculation never disagree about
/// where a week starts (Story 1.10 Dev Notes).
///
/// Stays a plain, synchronously-watched [WeekStart] (never an `AsyncValue`)
/// for every existing reader (`week_view.dart`, `month_view.dart`,
/// `stats_providers.dart`, `widget_bridge_provider.dart`) — [weekStartInitializerProvider]
/// hydrates it from persisted storage once at startup instead of making this
/// provider itself async. It is overridable in tests via `ProviderScope`
/// overrides, exactly like `goalRepositoryProvider` etc. (see
/// `test/presentation/day_view_test.dart` for the pattern).

abstract class _$WeekStartSetting extends $Notifier<WeekStart> {
  WeekStart build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WeekStart, WeekStart>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WeekStart, WeekStart>,
              WeekStart,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// This is the composition root (AD-1/AD-2): the only place that binds
/// [WeekStartSettingsRepository] to its `shared_preferences`-backed
/// implementation (AD-3's settings exception).

@ProviderFor(weekStartSettingsRepository)
final weekStartSettingsRepositoryProvider =
    WeekStartSettingsRepositoryProvider._();

/// This is the composition root (AD-1/AD-2): the only place that binds
/// [WeekStartSettingsRepository] to its `shared_preferences`-backed
/// implementation (AD-3's settings exception).

final class WeekStartSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<WeekStartSettingsRepository>,
          WeekStartSettingsRepository,
          FutureOr<WeekStartSettingsRepository>
        >
    with
        $FutureModifier<WeekStartSettingsRepository>,
        $FutureProvider<WeekStartSettingsRepository> {
  /// This is the composition root (AD-1/AD-2): the only place that binds
  /// [WeekStartSettingsRepository] to its `shared_preferences`-backed
  /// implementation (AD-3's settings exception).
  WeekStartSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekStartSettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekStartSettingsRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<WeekStartSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WeekStartSettingsRepository> create(Ref ref) {
    return weekStartSettingsRepository(ref);
  }
}

String _$weekStartSettingsRepositoryHash() =>
    r'd4054d5b20aabb29a5cb4c0d668f7dc85911a976';

/// Startup hook (mirrors `reminderInitializer`'s "async load, then apply to
/// the synchronous, widely-watched setting" pattern): hydrates
/// [weekStartSettingProvider] from whatever Panda previously chose in
/// Settings, if anything. Watched once from `main.dart`'s composition root.

@ProviderFor(weekStartInitializer)
final weekStartInitializerProvider = WeekStartInitializerProvider._();

/// Startup hook (mirrors `reminderInitializer`'s "async load, then apply to
/// the synchronous, widely-watched setting" pattern): hydrates
/// [weekStartSettingProvider] from whatever Panda previously chose in
/// Settings, if anything. Watched once from `main.dart`'s composition root.

final class WeekStartInitializerProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Startup hook (mirrors `reminderInitializer`'s "async load, then apply to
  /// the synchronous, widely-watched setting" pattern): hydrates
  /// [weekStartSettingProvider] from whatever Panda previously chose in
  /// Settings, if anything. Watched once from `main.dart`'s composition root.
  WeekStartInitializerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekStartInitializerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekStartInitializerHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return weekStartInitializer(ref);
  }
}

String _$weekStartInitializerHash() =>
    r'9c0e47df044c36984d744c0bb3618e1894adfb22';

/// The Settings screen's write path: persists Panda's Week-Start choice and
/// updates the live [weekStartSettingProvider] in the same step, so Week/
/// Month View and every other reader picks up the change immediately.
/// `keepAlive: true` for the same reason as `ReminderTimeController`: this is
/// invoked via `ref.read` as a plain action call, so nothing else keeps this
/// provider's default auto-dispose lifetime alive across its awaits.

@ProviderFor(WeekStartController)
final weekStartControllerProvider = WeekStartControllerProvider._();

/// The Settings screen's write path: persists Panda's Week-Start choice and
/// updates the live [weekStartSettingProvider] in the same step, so Week/
/// Month View and every other reader picks up the change immediately.
/// `keepAlive: true` for the same reason as `ReminderTimeController`: this is
/// invoked via `ref.read` as a plain action call, so nothing else keeps this
/// provider's default auto-dispose lifetime alive across its awaits.
final class WeekStartControllerProvider
    extends $AsyncNotifierProvider<WeekStartController, void> {
  /// The Settings screen's write path: persists Panda's Week-Start choice and
  /// updates the live [weekStartSettingProvider] in the same step, so Week/
  /// Month View and every other reader picks up the change immediately.
  /// `keepAlive: true` for the same reason as `ReminderTimeController`: this is
  /// invoked via `ref.read` as a plain action call, so nothing else keeps this
  /// provider's default auto-dispose lifetime alive across its awaits.
  WeekStartControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekStartControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekStartControllerHash();

  @$internal
  @override
  WeekStartController create() => WeekStartController();
}

String _$weekStartControllerHash() =>
    r'6c39dddf152d691d45fb7924ebe4adadecf7dc97';

/// The Settings screen's write path: persists Panda's Week-Start choice and
/// updates the live [weekStartSettingProvider] in the same step, so Week/
/// Month View and every other reader picks up the change immediately.
/// `keepAlive: true` for the same reason as `ReminderTimeController`: this is
/// invoked via `ref.read` as a plain action call, so nothing else keeps this
/// provider's default auto-dispose lifetime alive across its awaits.

abstract class _$WeekStartController extends $AsyncNotifier<void> {
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
