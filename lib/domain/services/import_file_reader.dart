/// Domain-defined, platform-agnostic abstraction for Story 6.2's "selected
/// via a local file picker" import source (Dev Notes, NFR-1/NFR-2: no
/// network call anywhere in this path). Implemented by
/// `FilePickerImportFileReader` in `data/io/` (AD-1).
abstract interface class ImportFileReader {
  /// Opens the platform file picker restricted to JSON files and returns its
  /// raw text contents, or `null` if Panda cancels the picker without
  /// choosing a file.
  Future<String?> pickAndReadFile();
}
