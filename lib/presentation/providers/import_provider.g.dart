// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// This is the composition root (AD-1/AD-2): the only place that binds
/// [ImportFileReader] to its `file_picker`-backed implementation.

@ProviderFor(importFileReader)
final importFileReaderProvider = ImportFileReaderProvider._();

/// This is the composition root (AD-1/AD-2): the only place that binds
/// [ImportFileReader] to its `file_picker`-backed implementation.

final class ImportFileReaderProvider
    extends
        $FunctionalProvider<
          ImportFileReader,
          ImportFileReader,
          ImportFileReader
        >
    with $Provider<ImportFileReader> {
  /// This is the composition root (AD-1/AD-2): the only place that binds
  /// [ImportFileReader] to its `file_picker`-backed implementation.
  ImportFileReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importFileReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importFileReaderHash();

  @$internal
  @override
  $ProviderElement<ImportFileReader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImportFileReader create(Ref ref) {
    return importFileReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportFileReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportFileReader>(value),
    );
  }
}

String _$importFileReaderHash() => r'5f3e517ddf6b4b139a76561ad6fe5398a3006f13';

/// Assembles a [JsonImporter] from the same repository providers every other
/// screen already uses, plus [goalServiceProvider] — every write this story
/// performs routes through that one `GoalService` instance (AD-6, AC #11).

@ProviderFor(jsonImporter)
final jsonImporterProvider = JsonImporterProvider._();

/// Assembles a [JsonImporter] from the same repository providers every other
/// screen already uses, plus [goalServiceProvider] — every write this story
/// performs routes through that one `GoalService` instance (AD-6, AC #11).

final class JsonImporterProvider
    extends
        $FunctionalProvider<
          AsyncValue<JsonImporter>,
          JsonImporter,
          FutureOr<JsonImporter>
        >
    with $FutureModifier<JsonImporter>, $FutureProvider<JsonImporter> {
  /// Assembles a [JsonImporter] from the same repository providers every other
  /// screen already uses, plus [goalServiceProvider] — every write this story
  /// performs routes through that one `GoalService` instance (AD-6, AC #11).
  JsonImporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jsonImporterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jsonImporterHash();

  @$internal
  @override
  $FutureProviderElement<JsonImporter> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<JsonImporter> create(Ref ref) {
    return jsonImporter(ref);
  }
}

String _$jsonImporterHash() => r'b2df0afc036f4a5d9065f437ec28a77fd04414a3';
