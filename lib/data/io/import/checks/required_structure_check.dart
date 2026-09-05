/// Subtask 2.2 (AC #3): verifies presence of `meta.schemaVersion` and every
/// required top-level entity array/object — naming the specific missing key
/// on failure (UX-DR19), never a generic "invalid file" message. Must run
/// before [SchemaVersionCheck][import checks/schema_version_check.dart],
/// which assumes `meta.schemaVersion` already exists.
class RequiredStructureCheck {
  const RequiredStructureCheck();

  static const requiredArrayKeys = [
    'goals',
    'goalVersions',
    'goalLogs',
    'cheatDays',
    'blackoutDates',
    'categories',
  ];

  String? check(Map<String, dynamic> json) {
    final meta = json['meta'];
    if (meta is! Map || !meta.containsKey('schemaVersion')) {
      return 'This file is missing required structure: meta.schemaVersion.';
    }
    for (final key in requiredArrayKeys) {
      if (!json.containsKey(key)) {
        return 'This file is missing required structure: $key.';
      }
    }
    if (json['settings'] is! Map) {
      return 'This file is missing required structure: settings.';
    }
    return null;
  }
}
