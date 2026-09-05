import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/io/json_exporter.dart';
import '../../data/io/share_export_file_writer.dart';
import '../../domain/services/export_file_writer.dart';
import 'reminder_settings_provider.dart';
import 'repository_providers.dart';
import 'week_start_provider.dart';

part 'export_provider.g.dart';

/// This is the composition root (AD-1/AD-2): the only place that binds
/// [ExportFileWriter] to its `share_plus`-backed implementation.
@Riverpod(keepAlive: true)
ExportFileWriter exportFileWriter(Ref ref) {
  return ShareExportFileWriter();
}

/// Assembles a [JsonExporter] from the same read-only repository providers
/// every other screen already uses, plus the two `shared_preferences`-backed
/// settings repositories — never `GoalService` or any write-capable
/// provider (AC #3: export is read-only).
@riverpod
Future<JsonExporter> jsonExporter(Ref ref) async {
  return JsonExporter(
    goalRepository: ref.watch(goalRepositoryProvider),
    goalVersionRepository: ref.watch(goalVersionRepositoryProvider),
    goalLogRepository: ref.watch(goalLogRepositoryProvider),
    cheatDayRepository: ref.watch(cheatDayRepositoryProvider),
    blackoutDateRepository: ref.watch(blackoutDateRepositoryProvider),
    reminderSettingsRepository: await ref.watch(
      reminderSettingsRepositoryProvider.future,
    ),
    weekStartSettingsRepository: await ref.watch(
      weekStartSettingsRepositoryProvider.future,
    ),
  );
}
