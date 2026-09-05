import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/goal_wizard_provider.dart';
import '../design_tokens.dart';

/// Step 5: start date (required, defaults to today but user-editable to a
/// past/future date — FR-1's "not necessarily 'today'") and optional end
/// date (Subtasks 6.1/6.2). `Goal.endDate` (Story 1.9's ER-diagram gap fix)
/// is collected here — the first and only Epic-1 point that collects it.
class DatesStep extends ConsumerWidget {
  const DatesStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalWizardProvider);
    final notifier = ref.read(goalWizardProvider.notifier);
    final colors = AppColors.of(context);

    if (state.isEditMode) {
      return ListView(
        children: [
          Text(
            'When should this change take effect?',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          ListTile(
            key: const Key('wizard-effective-date-tile'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Effective date'),
            subtitle: Text(_formatDate(state.startDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickStartDate(context, ref, state),
          ),
          if (state.versionLockedMessage != null) ...[
            const SizedBox(height: AppSpacing.s3),
            Text(
              state.versionLockedMessage!,
              key: const Key('wizard-version-locked-message'),
              style: TextStyle(color: colors.statusFail),
            ),
          ],
        ],
      );
    }

    return ListView(
      children: [
        Text(
          'When does this start?',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        ListTile(
          key: const Key('wizard-start-date-tile'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Start date'),
          subtitle: Text(_formatDate(state.startDate)),
          trailing: const Icon(Icons.calendar_today),
          onTap: () => _pickStartDate(context, ref, state),
        ),
        const SizedBox(height: AppSpacing.s3),
        ListTile(
          key: const Key('wizard-end-date-tile'),
          contentPadding: EdgeInsets.zero,
          title: const Text('End date (optional)'),
          subtitle: Text(
            state.endDate == null ? 'No end date' : _formatDate(state.endDate!),
          ),
          trailing: state.endDate == null
              ? const Icon(Icons.calendar_today)
              : IconButton(
                  key: const Key('wizard-clear-end-date-button'),
                  icon: const Icon(Icons.clear),
                  onPressed: () => notifier.setEndDate(null),
                ),
          onTap: () => _pickEndDate(context, ref, state),
        ),
        if (!state.datesStepValid) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            'End date must be on or after the start date.',
            style: TextStyle(color: colors.statusFail),
          ),
        ],
      ],
    );
  }

  Future<void> _pickStartDate(
    BuildContext context,
    WidgetRef ref,
    GoalWizardState state,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: state.startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && context.mounted) {
      ref.read(goalWizardProvider.notifier).setStartDate(picked);
    }
  }

  Future<void> _pickEndDate(
    BuildContext context,
    WidgetRef ref,
    GoalWizardState state,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: state.endDate ?? state.startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && context.mounted) {
      ref.read(goalWizardProvider.notifier).setEndDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
