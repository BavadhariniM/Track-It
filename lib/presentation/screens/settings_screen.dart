import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/io/import/import_conflict.dart';
import '../../data/io/import/import_outcome.dart';
import '../../domain/entities/time_of_day_value.dart';
import '../../domain/evaluator/period_boundary.dart';
import '../components/design_tokens.dart';
import '../components/reset_confirmation_sheet.dart';
import '../components/secondary_button.dart';
import '../providers/export_provider.dart';
import '../providers/import_provider.dart';
import '../providers/reminder_settings_provider.dart';
import '../providers/week_start_provider.dart';
import 'import_conflict_resolution_screen.dart';

/// The Settings tab (EXPERIENCE.md IA row: "Week-start day, global reminder
/// time, categories, export, import, reset"). This story adds the
/// global-reminder-time row (FR-30), the Week-Start row (FR-24), and the
/// Export action (FR-33) — Story 6.2 added Import; Story 6.3 adds the
/// Reset / Erase All row (FR-36) — the remaining row (categories) belongs
/// to another story/epic and is not this screen's shell.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final reminderAsync = ref.watch(reminderTimeProvider);
    final weekStart = ref.watch(weekStartSettingProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            key: const Key('settings-reminder-time-tile'),
            title: const Text('Daily reminder'),
            subtitle: Text(
              reminderAsync.value?.toString() ?? 'Not set',
              style: TextStyle(color: colors.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickReminderTime(context, ref, reminderAsync.value),
          ),
          Padding(
            key: const Key('settings-week-start-tile'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s3,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Week starts on'),
                Row(
                  children: [
                    _WeekStartChip(
                      chipKey: const Key('settings-week-start-monday'),
                      label: 'Mon',
                      selected: weekStart == WeekStart.monday,
                      onTap: () => ref
                          .read(weekStartControllerProvider.notifier)
                          .setWeekStart(WeekStart.monday),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    _WeekStartChip(
                      chipKey: const Key('settings-week-start-sunday'),
                      label: 'Sun',
                      selected: weekStart == WeekStart.sunday,
                      onTap: () => ref
                          .read(weekStartControllerProvider.notifier)
                          .setWeekStart(WeekStart.sunday),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s3,
            ),
            child: SecondaryButton(
              key: const Key('settings-export-button'),
              label: 'Export data',
              onPressed: () => _exportData(context, ref),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s3,
            ),
            child: SecondaryButton(
              key: const Key('settings-import-button'),
              label: 'Import data',
              onPressed: () => _importData(context, ref),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s3,
            ),
            child: SecondaryButton(
              // Subtask 2.1/UX-DR10: `button-secondary`, not the screen's
              // single forward action — it must not visually invite an
              // accidental tap the way a primary action would.
              key: const Key('settings-reset-button'),
              label: 'Reset / Erase All',
              onPressed: () => showResetConfirmationSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Task 3.2/3.3: builds the export JSON via the read-only
  /// [jsonExporterProvider] (never `GoalService`), then hands it to the
  /// platform's native save/share flow — no `BuildContext`-coupled domain
  /// access (AD-2), only this widget-layer glue between the two providers.
  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final exporter = await ref.read(jsonExporterProvider.future);
      final json = await exporter.exportToJson();

      final now = DateTime.now();
      final fileName =
          'tracker-export-'
          '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}-'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}.json';

      await ref
          .read(exportFileWriterProvider)
          .writeAndShare(fileName: fileName, contents: json);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export failed. Please try again.')),
      );
    }
  }

  /// Task 6: picks a JSON file, hands it to [JsonImporter], and surfaces
  /// whichever of the three terminal states (AC #10) results — a silent-
  /// success confirmation (Subtask 6.1), a route to
  /// [ImportConflictResolutionScreen] once conflicts are found (Subtask
  /// 6.2), or a specific-reason rejection (Subtask 6.4, UX-DR19). A
  /// zero-goal file (AC #8) gets distinct warning copy alongside acceptance
  /// (Subtask 6.3), never the plain success message.
  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      final raw = await ref.read(importFileReaderProvider).pickAndReadFile();
      if (raw == null) return; // Panda cancelled the picker.
      if (!context.mounted) return;

      final importer = await ref.read(jsonImporterProvider.future);
      final outcome = await importer.import(raw);
      if (!context.mounted) return;

      await _handleImportOutcome(context, ref, outcome);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import failed. Please try again.')),
      );
    }
  }

  Future<void> _handleImportOutcome(
    BuildContext context,
    WidgetRef ref,
    ImportOutcome outcome,
  ) async {
    switch (outcome) {
      case ImportOutcomeRejected(:final reason):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(reason)));
      case ImportOutcomeCompleted(:final zeroGoalWarning):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              zeroGoalWarning
                  ? 'Import complete — the file had no Goals to restore.'
                  : 'Import complete.',
            ),
          ),
        );
      case ImportOutcomeNeedsResolution(:final file, :final detection, :final zeroGoalWarning):
        final resolutions = await Navigator.of(context).push<Map<String, ConflictChoice>>(
          MaterialPageRoute(
            builder: (_) =>
                ImportConflictResolutionScreen(conflicts: detection.conflicts),
          ),
        );
        if (resolutions == null) return; // Panda backed out — nothing written.
        if (!context.mounted) return;

        final importer = await ref.read(jsonImporterProvider.future);
        final completed = await importer.completeWithResolutions(
          file: file,
          detection: detection,
          resolutions: resolutions,
          zeroGoalWarning: zeroGoalWarning,
        );
        if (!context.mounted) return;
        await _handleImportOutcome(context, ref, completed);
    }
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    WidgetRef ref,
    TimeOfDayValue? current,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current == null
          ? TimeOfDay.now()
          : TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked == null) return;

    await ref
        .read(reminderTimeControllerProvider.notifier)
        .setReminderTime(
          TimeOfDayValue(hour: picked.hour, minute: picked.minute),
        );
  }
}

/// A `button-secondary`-styled toggle chip (UX-DR10: no new interactive
/// primitive beyond the two established button tiers) — the same outlined/
/// filled-when-selected treatment `GoalFilterBar`'s `_FilterChip` uses,
/// reused here for the Week-Start Monday/Sunday choice.
class _WeekStartChip extends StatelessWidget {
  const _WeekStartChip({
    required this.chipKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key chipKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return OutlinedButton(
      key: chipKey,
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? colors.accent : Colors.transparent,
        foregroundColor: selected ? colors.accentOn : colors.textPrimary,
        side: BorderSide(
          color: selected ? colors.accent : colors.borderHairline,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
      child: Text(label),
    );
  }
}
