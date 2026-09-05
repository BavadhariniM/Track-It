import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/io/file_picker_import_file_reader.dart';
import '../../data/io/json_importer.dart';
import '../../domain/services/import_file_reader.dart';
import 'goal_service_provider.dart';
import 'reminder_settings_provider.dart';
import 'repository_providers.dart';
import 'week_start_provider.dart';

part 'import_provider.g.dart';

/// This is the composition root (AD-1/AD-2): the only place that binds
/// [ImportFileReader] to its `file_picker`-backed implementation.
@Riverpod(keepAlive: true)
ImportFileReader importFileReader(Ref ref) {
  return const FilePickerImportFileReader();
}

/// Assembles a [JsonImporter] from the same repository providers every other
/// screen already uses, plus [goalServiceProvider] — every write this story
/// performs routes through that one `GoalService` instance (AD-6, AC #11).
@riverpod
Future<JsonImporter> jsonImporter(Ref ref) async {
  return JsonImporter(
    goalRepository: ref.watch(goalRepositoryProvider),
    goalVersionRepository: ref.watch(goalVersionRepositoryProvider),
    goalLogRepository: ref.watch(goalLogRepositoryProvider),
    cheatDayRepository: ref.watch(cheatDayRepositoryProvider),
    blackoutDateRepository: ref.watch(blackoutDateRepositoryProvider),
    goalService: ref.watch(goalServiceProvider),
    weekStartSettingsRepository: await ref.watch(
      weekStartSettingsRepositoryProvider.future,
    ),
    reminderSettingsRepository: await ref.watch(
      reminderSettingsRepositoryProvider.future,
    ),
  );
}
