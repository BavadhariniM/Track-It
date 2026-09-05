import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../../domain/services/import_file_reader.dart';

/// `file_picker`-backed [ImportFileReader] (new dependency, Story 6.2 —
/// mirrors Story 6.1's `share_plus` addition for export). Reads the picked
/// file directly off local disk via `dart:io`; no network permission or
/// call is exercised anywhere in this path (NFR-1/NFR-2).
class FilePickerImportFileReader implements ImportFileReader {
  const FilePickerImportFileReader();

  @override
  Future<String?> pickAndReadFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = file?.path;
    if (path == null) return null;
    return File(path).readAsString();
  }
}
