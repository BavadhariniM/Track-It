// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_bridge_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Composition root (AD-1): binds [WidgetBridgeWriter] to its `data`-layer
/// implementation, the same pattern `cacheWriterProvider` uses.

@ProviderFor(widgetBridgeWriter)
final widgetBridgeWriterProvider = WidgetBridgeWriterProvider._();

/// Composition root (AD-1): binds [WidgetBridgeWriter] to its `data`-layer
/// implementation, the same pattern `cacheWriterProvider` uses.

final class WidgetBridgeWriterProvider
    extends
        $FunctionalProvider<
          WidgetBridgeWriter,
          WidgetBridgeWriter,
          WidgetBridgeWriter
        >
    with $Provider<WidgetBridgeWriter> {
  /// Composition root (AD-1): binds [WidgetBridgeWriter] to its `data`-layer
  /// implementation, the same pattern `cacheWriterProvider` uses.
  WidgetBridgeWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetBridgeWriterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetBridgeWriterHash();

  @$internal
  @override
  $ProviderElement<WidgetBridgeWriter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WidgetBridgeWriter create(Ref ref) {
    return widgetBridgeWriter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WidgetBridgeWriter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WidgetBridgeWriter>(value),
    );
  }
}

String _$widgetBridgeWriterHash() =>
    r'c0e2672de39a244807cdbe090623d4a7b24fd608';

/// Composition-root startup hook (Task 6.2): sets the iOS App Group id once
/// per app launch so every `HomeWidget.saveWidgetData`/`updateWidget` call
/// targets the shared container a future WidgetKit extension (Story 5.2)
/// reads from. A no-op on Android, which has no App Group concept.

@ProviderFor(widgetBridgeInitializer)
final widgetBridgeInitializerProvider = WidgetBridgeInitializerProvider._();

/// Composition-root startup hook (Task 6.2): sets the iOS App Group id once
/// per app launch so every `HomeWidget.saveWidgetData`/`updateWidget` call
/// targets the shared container a future WidgetKit extension (Story 5.2)
/// reads from. A no-op on Android, which has no App Group concept.

final class WidgetBridgeInitializerProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Composition-root startup hook (Task 6.2): sets the iOS App Group id once
  /// per app launch so every `HomeWidget.saveWidgetData`/`updateWidget` call
  /// targets the shared container a future WidgetKit extension (Story 5.2)
  /// reads from. A no-op on Android, which has no App Group concept.
  WidgetBridgeInitializerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetBridgeInitializerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetBridgeInitializerHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return widgetBridgeInitializer(ref);
  }
}

String _$widgetBridgeInitializerHash() =>
    r'5412bec49193fed48805ec33d78105fdc503dd19';
