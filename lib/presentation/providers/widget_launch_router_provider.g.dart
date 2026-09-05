// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_launch_router_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Warm-start case (Task 1.3): `home_widget`'s `widgetClicked` stream fires
/// while the app is already running (foreground or background), so a
/// widget tap while the app is alive also routes correctly.

@ProviderFor(widgetClicked)
final widgetClickedProvider = WidgetClickedProvider._();

/// Warm-start case (Task 1.3): `home_widget`'s `widgetClicked` stream fires
/// while the app is already running (foreground or background), so a
/// widget tap while the app is alive also routes correctly.

final class WidgetClickedProvider
    extends $FunctionalProvider<AsyncValue<Uri?>, Uri?, Stream<Uri?>>
    with $FutureModifier<Uri?>, $StreamProvider<Uri?> {
  /// Warm-start case (Task 1.3): `home_widget`'s `widgetClicked` stream fires
  /// while the app is already running (foreground or background), so a
  /// widget tap while the app is alive also routes correctly.
  WidgetClickedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetClickedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetClickedHash();

  @$internal
  @override
  $StreamProviderElement<Uri?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Uri?> create(Ref ref) {
    return widgetClicked(ref);
  }
}

String _$widgetClickedHash() => r'aaa14d5878795485f42294841ee76e3195528225';

/// Composition-root startup hook: detects a cold-start widget-tap launch
/// (Task 1.2, via `HomeWidget.initiallyLaunchedFromHomeWidget()`) and
/// subscribes to the warm-start stream (Task 1.3) for the app's whole
/// lifetime, routing both cases through the same
/// [navigateToWidgetLaunchTarget]/[widgetLaunchNavigatorKey].

@ProviderFor(widgetLaunchWatcher)
final widgetLaunchWatcherProvider = WidgetLaunchWatcherProvider._();

/// Composition-root startup hook: detects a cold-start widget-tap launch
/// (Task 1.2, via `HomeWidget.initiallyLaunchedFromHomeWidget()`) and
/// subscribes to the warm-start stream (Task 1.3) for the app's whole
/// lifetime, routing both cases through the same
/// [navigateToWidgetLaunchTarget]/[widgetLaunchNavigatorKey].

final class WidgetLaunchWatcherProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Composition-root startup hook: detects a cold-start widget-tap launch
  /// (Task 1.2, via `HomeWidget.initiallyLaunchedFromHomeWidget()`) and
  /// subscribes to the warm-start stream (Task 1.3) for the app's whole
  /// lifetime, routing both cases through the same
  /// [navigateToWidgetLaunchTarget]/[widgetLaunchNavigatorKey].
  WidgetLaunchWatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetLaunchWatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetLaunchWatcherHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return widgetLaunchWatcher(ref);
  }
}

String _$widgetLaunchWatcherHash() =>
    r'6b6f0c0fe8a38033c420978044e65c89a25f3a44';
