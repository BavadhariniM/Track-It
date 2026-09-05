// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// This is the composition root (AD-1/AD-2): the only place that binds
/// [ExportFileWriter] to its `share_plus`-backed implementation.

@ProviderFor(exportFileWriter)
final exportFileWriterProvider = ExportFileWriterProvider._();

/// This is the composition root (AD-1/AD-2): the only place that binds
/// [ExportFileWriter] to its `share_plus`-backed implementation.

final class ExportFileWriterProvider
    extends
        $FunctionalProvider<
          ExportFileWriter,
          ExportFileWriter,
          ExportFileWriter
        >
    with $Provider<ExportFileWriter> {
  /// This is the composition root (AD-1/AD-2): the only place that binds
  /// [ExportFileWriter] to its `share_plus`-backed implementation.
  ExportFileWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportFileWriterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportFileWriterHash();

  @$internal
  @override
  $ProviderElement<ExportFileWriter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExportFileWriter create(Ref ref) {
    return exportFileWriter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportFileWriter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportFileWriter>(value),
    );
  }
}

String _$exportFileWriterHash() => r'b72c341545445c04519b54d4761393ddce2ee325';

/// Assembles a [JsonExporter] from the same read-only repository providers
/// every other screen already uses, plus the two `shared_preferences`-backed
/// settings repositories — never `GoalService` or any write-capable
/// provider (AC #3: export is read-only).

@ProviderFor(jsonExporter)
final jsonExporterProvider = JsonExporterProvider._();

/// Assembles a [JsonExporter] from the same read-only repository providers
/// every other screen already uses, plus the two `shared_preferences`-backed
/// settings repositories — never `GoalService` or any write-capable
/// provider (AC #3: export is read-only).

final class JsonExporterProvider
    extends
        $FunctionalProvider<
          AsyncValue<JsonExporter>,
          JsonExporter,
          FutureOr<JsonExporter>
        >
    with $FutureModifier<JsonExporter>, $FutureProvider<JsonExporter> {
  /// Assembles a [JsonExporter] from the same read-only repository providers
  /// every other screen already uses, plus the two `shared_preferences`-backed
  /// settings repositories — never `GoalService` or any write-capable
  /// provider (AC #3: export is read-only).
  JsonExporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jsonExporterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jsonExporterHash();

  @$internal
  @override
  $FutureProviderElement<JsonExporter> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<JsonExporter> create(Ref ref) {
    return jsonExporter(ref);
  }
}

String _$jsonExporterHash() => r'e33c1d23c2a5f1fb4d50ff4f501006e7fcf2fb50';
