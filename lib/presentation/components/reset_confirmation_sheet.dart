import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/reset_provider.dart';
import 'design_tokens.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// Story 6.3 (AC #1, #2, #5, UX-DR24): the sole two-step confirmation
/// surface in the product. Reached only from Settings' "Reset / Erase All"
/// row (Subtask 2.1's first tap); this sheet is the second, explicit step —
/// nothing about opening it mutates any data, and only its own "Erase
/// Everything" tap does (Subtask 2.5). A modal sheet, per DESIGN.md's one
/// permitted elevation exception, matching `cheat_blackout_sheet.dart`'s
/// existing `showModalBottomSheet` convention.
Future<void> showResetConfirmationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => const _ResetConfirmationSheet(),
  );
}

class _ResetConfirmationSheet extends ConsumerStatefulWidget {
  const _ResetConfirmationSheet();

  @override
  ConsumerState<_ResetConfirmationSheet> createState() =>
      _ResetConfirmationSheetState();
}

class _ResetConfirmationSheetState
    extends ConsumerState<_ResetConfirmationSheet> {
  bool _resetting = false;

  Future<void> _confirm() async {
    setState(() => _resetting = true);
    await ref.read(resetControllerProvider.notifier).resetAll();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reset / Erase All',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            // AC #2/FR-36: the exact, consequence-specific copy — not a
            // generic "Are you sure?" (UX-DR19).
            Text(
              key: const Key('reset-confirm-sheet-copy'),
              'This erases all Goals, logs, and settings. This cannot be '
              'undone.',
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s4),
            PrimaryButton(
              key: const Key('reset-confirm-sheet-confirm'),
              label: _resetting ? 'Erasing…' : 'Erase Everything',
              onPressed: _resetting ? null : _confirm,
            ),
            const SizedBox(height: AppSpacing.s3),
            SecondaryButton(
              key: const Key('reset-confirm-sheet-cancel'),
              label: 'Cancel',
              // AC #5: backing out here writes nothing — no transaction has
              // ever been started by merely showing this sheet.
              onPressed: _resetting
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
