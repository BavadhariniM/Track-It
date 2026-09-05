/// Domain-defined interface for handing an already-serialized export
/// document to the platform's native file-save/share flow (FR-33 Task 3).
/// Implemented by `ShareExportFileWriter` in `data/io/` — deliberately
/// narrow (accepts a finished JSON string, never touches a repository
/// itself) since assembling the export content is `JsonExporter`'s concern
/// alone (AC #3: export is read-only).
abstract interface class ExportFileWriter {
  /// Writes [contents] to a file named [fileName] and hands it to the
  /// platform's native save/share flow. Never performs or triggers any
  /// network I/O (NFR-1/NFR-2) — sharing to a local app or a device's own
  /// file system is a purely on-device OS mechanism.
  Future<void> writeAndShare({
    required String fileName,
    required String contents,
  });
}
