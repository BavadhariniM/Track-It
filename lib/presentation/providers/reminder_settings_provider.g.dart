// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<SharedPreferences>,
          SharedPreferences,
          FutureOr<SharedPreferences>
        >
    with
        $FutureModifier<SharedPreferences>,
        $FutureProvider<SharedPreferences> {
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $FutureProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SharedPreferences> create(Ref ref) {
    return sharedPreferences(ref);
  }
}

String _$sharedPreferencesHash() => r'48e60558ea6530114ea20ea03e69b9fb339ab129';

/// This is the composition root (AD-1/AD-2): the only place that binds
/// [ReminderSettingsRepository] to its `shared_preferences`-backed
/// implementation (AD-3's settings exception).

@ProviderFor(reminderSettingsRepository)
final reminderSettingsRepositoryProvider =
    ReminderSettingsRepositoryProvider._();

/// This is the composition root (AD-1/AD-2): the only place that binds
/// [ReminderSettingsRepository] to its `shared_preferences`-backed
/// implementation (AD-3's settings exception).

final class ReminderSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReminderSettingsRepository>,
          ReminderSettingsRepository,
          FutureOr<ReminderSettingsRepository>
        >
    with
        $FutureModifier<ReminderSettingsRepository>,
        $FutureProvider<ReminderSettingsRepository> {
  /// This is the composition root (AD-1/AD-2): the only place that binds
  /// [ReminderSettingsRepository] to its `shared_preferences`-backed
  /// implementation (AD-3's settings exception).
  ReminderSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderSettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderSettingsRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<ReminderSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ReminderSettingsRepository> create(Ref ref) {
    return reminderSettingsRepository(ref);
  }
}

String _$reminderSettingsRepositoryHash() =>
    r'32f35a9ba3d3732aa35a5721a306541504bf7ba9';

/// This is the composition root (AD-1/AD-2): the only place that binds
/// [ReminderScheduler] to its `flutter_local_notifications`-backed
/// implementation. `keepAlive` so the plugin instance is never recreated.

@ProviderFor(reminderScheduler)
final reminderSchedulerProvider = ReminderSchedulerProvider._();

/// This is the composition root (AD-1/AD-2): the only place that binds
/// [ReminderScheduler] to its `flutter_local_notifications`-backed
/// implementation. `keepAlive` so the plugin instance is never recreated.

final class ReminderSchedulerProvider
    extends
        $FunctionalProvider<
          ReminderScheduler,
          ReminderScheduler,
          ReminderScheduler
        >
    with $Provider<ReminderScheduler> {
  /// This is the composition root (AD-1/AD-2): the only place that binds
  /// [ReminderScheduler] to its `flutter_local_notifications`-backed
  /// implementation. `keepAlive` so the plugin instance is never recreated.
  ReminderSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderSchedulerHash();

  @$internal
  @override
  $ProviderElement<ReminderScheduler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReminderScheduler create(Ref ref) {
    return reminderScheduler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReminderScheduler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReminderScheduler>(value),
    );
  }
}

String _$reminderSchedulerHash() => r'd85bc7f169e3065d955489ee6cdc200087f4000e';

/// The configured global reminder time (FR-30), or `null` if Panda has never
/// set one yet. Read by both the Settings screen (pre-filling the time
/// picker) and the Dashboard (Story 3.1's "next reminder" display).

@ProviderFor(reminderTime)
final reminderTimeProvider = ReminderTimeProvider._();

/// The configured global reminder time (FR-30), or `null` if Panda has never
/// set one yet. Read by both the Settings screen (pre-filling the time
/// picker) and the Dashboard (Story 3.1's "next reminder" display).

final class ReminderTimeProvider
    extends
        $FunctionalProvider<
          AsyncValue<TimeOfDayValue?>,
          TimeOfDayValue?,
          FutureOr<TimeOfDayValue?>
        >
    with $FutureModifier<TimeOfDayValue?>, $FutureProvider<TimeOfDayValue?> {
  /// The configured global reminder time (FR-30), or `null` if Panda has never
  /// set one yet. Read by both the Settings screen (pre-filling the time
  /// picker) and the Dashboard (Story 3.1's "next reminder" display).
  ReminderTimeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderTimeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderTimeHash();

  @$internal
  @override
  $FutureProviderElement<TimeOfDayValue?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TimeOfDayValue?> create(Ref ref) {
    return reminderTime(ref);
  }
}

String _$reminderTimeHash() => r'5e645e475622c51b0075363c264f52a7352dc898';

/// The Settings screen's write path (Task 1.4): persists a new reminder
/// time and re-registers the daily notification for it in one step, then
/// invalidates [reminderTimeProvider] so every reader (Settings, Dashboard)
/// picks up the change reactively.
/// `keepAlive: true`: `setReminderTime` is invoked via `ref.read` (a plain
/// action call, not a `watch`), so nothing keeps this provider's default
/// auto-dispose lifetime alive across the awaits inside it — without this,
/// Riverpod tears the notifier down mid-method as soon as the synchronous
/// call returns, which surfaces as an `UnmountedRefException` once
/// `setReminderTime` reaches its first `await`.

@ProviderFor(ReminderTimeController)
final reminderTimeControllerProvider = ReminderTimeControllerProvider._();

/// The Settings screen's write path (Task 1.4): persists a new reminder
/// time and re-registers the daily notification for it in one step, then
/// invalidates [reminderTimeProvider] so every reader (Settings, Dashboard)
/// picks up the change reactively.
/// `keepAlive: true`: `setReminderTime` is invoked via `ref.read` (a plain
/// action call, not a `watch`), so nothing keeps this provider's default
/// auto-dispose lifetime alive across the awaits inside it — without this,
/// Riverpod tears the notifier down mid-method as soon as the synchronous
/// call returns, which surfaces as an `UnmountedRefException` once
/// `setReminderTime` reaches its first `await`.
final class ReminderTimeControllerProvider
    extends $AsyncNotifierProvider<ReminderTimeController, void> {
  /// The Settings screen's write path (Task 1.4): persists a new reminder
  /// time and re-registers the daily notification for it in one step, then
  /// invalidates [reminderTimeProvider] so every reader (Settings, Dashboard)
  /// picks up the change reactively.
  /// `keepAlive: true`: `setReminderTime` is invoked via `ref.read` (a plain
  /// action call, not a `watch`), so nothing keeps this provider's default
  /// auto-dispose lifetime alive across the awaits inside it — without this,
  /// Riverpod tears the notifier down mid-method as soon as the synchronous
  /// call returns, which surfaces as an `UnmountedRefException` once
  /// `setReminderTime` reaches its first `await`.
  ReminderTimeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderTimeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderTimeControllerHash();

  @$internal
  @override
  ReminderTimeController create() => ReminderTimeController();
}

String _$reminderTimeControllerHash() =>
    r'a9a4a7d145402caddbfe98d8ab12f62162f57e08';

/// The Settings screen's write path (Task 1.4): persists a new reminder
/// time and re-registers the daily notification for it in one step, then
/// invalidates [reminderTimeProvider] so every reader (Settings, Dashboard)
/// picks up the change reactively.
/// `keepAlive: true`: `setReminderTime` is invoked via `ref.read` (a plain
/// action call, not a `watch`), so nothing keeps this provider's default
/// auto-dispose lifetime alive across the awaits inside it — without this,
/// Riverpod tears the notifier down mid-method as soon as the synchronous
/// call returns, which surfaces as an `UnmountedRefException` once
/// `setReminderTime` reaches its first `await`.

abstract class _$ReminderTimeController extends $AsyncNotifier<void> {
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

/// Composition-root startup hook (Story 4.1 AC #4): initializes the
/// notification plugin once per app launch, then re-registers whatever
/// reminder time was already configured (if any). Android reboots are
/// re-armed by the plugin's own boot receiver (see
/// `FlutterLocalNotificationsReminderScheduler`'s doc comment); this covers
/// the force-quit-then-relaunch case, where no reboot occurs but the
/// process (and any of its in-memory scheduling state) starts fresh.

@ProviderFor(reminderInitializer)
final reminderInitializerProvider = ReminderInitializerProvider._();

/// Composition-root startup hook (Story 4.1 AC #4): initializes the
/// notification plugin once per app launch, then re-registers whatever
/// reminder time was already configured (if any). Android reboots are
/// re-armed by the plugin's own boot receiver (see
/// `FlutterLocalNotificationsReminderScheduler`'s doc comment); this covers
/// the force-quit-then-relaunch case, where no reboot occurs but the
/// process (and any of its in-memory scheduling state) starts fresh.

final class ReminderInitializerProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Composition-root startup hook (Story 4.1 AC #4): initializes the
  /// notification plugin once per app launch, then re-registers whatever
  /// reminder time was already configured (if any). Android reboots are
  /// re-armed by the plugin's own boot receiver (see
  /// `FlutterLocalNotificationsReminderScheduler`'s doc comment); this covers
  /// the force-quit-then-relaunch case, where no reboot occurs but the
  /// process (and any of its in-memory scheduling state) starts fresh.
  ReminderInitializerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderInitializerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderInitializerHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return reminderInitializer(ref);
  }
}

String _$reminderInitializerHash() =>
    r'0468b9ab2f34a219154d168a72bf3c1ee879f52e';
