import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:share_plus/share_plus.dart';

import '../../domain/services/export_file_writer.dart';

/// `share_plus`-backed implementation of [ExportFileWriter]: writes the
/// export JSON to a temporary file, then hands it to the OS-native share
/// sheet (Settings → Export, Task 3.3) so Panda can save it to Files,
/// Drive, AirDrop, or wherever else the platform offers. `share_plus`
/// invokes the OS share sheet directly and makes no network call of its
/// own (NFR-1/NFR-2) — what the user does with the resulting share target
/// is their own choice, exactly like sharing a photo from the OS gallery.
///
/// [temporaryDirectoryProvider] and [sharePlus] default to the real
/// `path_provider`/`share_plus` plugins and are only ever overridden in
/// tests (Dev Notes: neither plugin is exercisable against a real device
/// from `flutter test`, so both are swapped for fakes there — the same
/// seam `GoalService`'s injectable `Uuid` uses).
class ShareExportFileWriter implements ExportFileWriter {
  ShareExportFileWriter({
    Future<Directory> Function()? temporaryDirectoryProvider,
    SharePlus? sharePlus,
  }) : _temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? path_provider.getTemporaryDirectory,
       _sharePlus = sharePlus ?? SharePlus.instance;

  final Future<Directory> Function() _temporaryDirectoryProvider;
  final SharePlus _sharePlus;

  @override
  Future<void> writeAndShare({
    required String fileName,
    required String contents,
  }) async {
    final dir = await _temporaryDirectoryProvider();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(contents);

    await _sharePlus.share(
      ShareParams(files: [XFile(file.path)], fileNameOverrides: [fileName]),
    );
  }
}
