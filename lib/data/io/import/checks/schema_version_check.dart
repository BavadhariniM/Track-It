/// Subtask 2.3 (AC #4): compares `meta.schemaVersion` against the app's
/// supported version set — the same `1.0` value Story 6.1's exporter writes
/// (`json_exporter.dart`'s `exportSchemaVersion`). On mismatch, rejects
/// naming both the unsupported value found and the version(s) supported
/// (UX-DR19). Assumes [RequiredStructureCheck] has already confirmed
/// `meta.schemaVersion` is present.
class SchemaVersionCheck {
  const SchemaVersionCheck();

  static const supportedVersions = {'1.0'};

  String? check(Map<String, dynamic> json) {
    final meta = json['meta'] as Map;
    final version = meta['schemaVersion'];
    if (version is String && supportedVersions.contains(version)) return null;
    return 'This file uses schema version "$version", which this app does '
        'not support. Supported version(s): ${supportedVersions.join(', ')}.';
  }
}
