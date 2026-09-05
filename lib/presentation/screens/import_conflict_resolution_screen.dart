import 'package:flutter/material.dart';

import '../../data/io/import/import_conflict.dart';
import '../components/design_tokens.dart';
import '../components/primary_button.dart';
import '../components/secondary_button.dart';

/// Story 6.2 Task 4 (AC #9, UX-DR14): reached only from Settings → Import
/// when `ConflictDetectionCheck` finds at least one conflict. Presents
/// exactly one decision per conflict — `keep-mine` / `keep-imported` — with
/// no bulk "accept all" control anywhere on this screen (UX-DR14); "merge"
/// was considered and dropped (confirmed with Panda — see
/// `ConflictChoice`'s doc comment for why a third option had no coherent
/// meaning here). Every listed conflict must be resolved before "Finish
/// Import" is enabled (Subtask 4.4) — [Navigator.pop] returns the completed
/// resolutions map to the caller, which never commits a partial batch.
class ImportConflictResolutionScreen extends StatefulWidget {
  const ImportConflictResolutionScreen({super.key, required this.conflicts});

  final List<ImportConflict> conflicts;

  @override
  State<ImportConflictResolutionScreen> createState() =>
      _ImportConflictResolutionScreenState();
}

class _ImportConflictResolutionScreenState
    extends State<ImportConflictResolutionScreen> {
  final Map<String, ConflictChoice> _resolutions = {};

  bool get _allResolved => widget.conflicts.every(
    (c) => _resolutions.containsKey(c.resolutionKey),
  );

  void _choose(ImportConflict conflict, ConflictChoice choice) {
    setState(() => _resolutions[conflict.resolutionKey] = choice);
  }

  void _finish() {
    Navigator.of(context).pop(Map<String, ConflictChoice>.of(_resolutions));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Resolve Import Conflicts')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.s4),
        itemCount: widget.conflicts.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s4),
        itemBuilder: (context, index) {
          final conflict = widget.conflicts[index];
          return _ConflictCard(
            key: Key('import-conflict-$index'),
            conflict: conflict,
            choice: _resolutions[conflict.resolutionKey],
            onChoose: (choice) => _choose(conflict, choice),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: PrimaryButton(
            key: const Key('import-conflict-finish-button'),
            label: 'Finish Import',
            onPressed: _allResolved ? _finish : null,
          ),
        ),
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    super.key,
    required this.conflict,
    required this.choice,
    required this.onChoose,
  });

  final ImportConflict conflict;
  final ConflictChoice? choice;
  final ValueChanged<ConflictChoice> onChoose;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        border: Border.all(color: colors.borderHairline),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // UX-DR19: names the specific conflicting entity, never generic
          // wording (built in `ConflictDetector` from the entity's own
          // fields).
          Text(
            conflict.label,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'This exists both on this device and in the imported file, with '
            'different content.',
            style: TextStyle(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  key: Key('${conflict.resolutionKey}-keep-mine'),
                  label: 'Keep Mine',
                  onPressed: () => onChoose(ConflictChoice.keepMine),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: SecondaryButton(
                  key: Key('${conflict.resolutionKey}-keep-imported'),
                  label: 'Keep Imported',
                  onPressed: () => onChoose(ConflictChoice.keepImported),
                ),
              ),
            ],
          ),
          if (choice != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              choice == ConflictChoice.keepMine
                  ? 'Selected: Keep Mine'
                  : 'Selected: Keep Imported',
              style: TextStyle(color: colors.accent),
            ),
          ],
        ],
      ),
    );
  }
}
