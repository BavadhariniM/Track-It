import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:tracker/data/io/share_export_file_writer.dart';

/// Records every [share] call instead of invoking a real OS share sheet —
/// `SharePlus.custom` (`@visibleForTesting`) is `share_plus`'s own seam for
/// exactly this.
class _FakeSharePlatform extends SharePlatform {
  ShareParams? lastParams;

  @override
  Future<ShareResult> share(ShareParams params) async {
    lastParams = params;
    return ShareResult('fake', ShareResultStatus.success);
  }
}

void main() {
  late Directory tempDir;
  late _FakeSharePlatform fakePlatform;
  late ShareExportFileWriter writer;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('export_writer_test');
    fakePlatform = _FakeSharePlatform();
    writer = ShareExportFileWriter(
      temporaryDirectoryProvider: () async => tempDir,
      sharePlus: SharePlus.custom(fakePlatform),
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'writes the contents to a file named exactly as requested and hands it '
    'to the platform share flow (Task 3.3)',
    () async {
      await writer.writeAndShare(
        fileName: 'tracker-export-test.json',
        contents: '{"meta":{"schemaVersion":"1.0"}}',
      );

      final writtenFile = File(
        p.join(tempDir.path, 'tracker-export-test.json'),
      );
      expect(writtenFile.existsSync(), isTrue);
      expect(
        await writtenFile.readAsString(),
        '{"meta":{"schemaVersion":"1.0"}}',
      );

      final params = fakePlatform.lastParams;
      expect(params, isNotNull);
      expect(params!.files, hasLength(1));
      expect(params.files!.single.path, writtenFile.path);
      expect(params.fileNameOverrides, ['tracker-export-test.json']);
    },
  );
}
