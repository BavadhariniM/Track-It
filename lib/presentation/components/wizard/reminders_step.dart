import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/goal_wizard_provider.dart';
import '../design_tokens.dart';

/// Step 6: a trivial opt-in toggle only (Subtask 7.1). The actual global
/// reminder-time setting and `flutter_local_notifications` scheduling
/// belong to Epic 4 Story 4.1 — this story does not implement notification
/// scheduling, and the toggle's value isn't persisted anywhere (no
/// per-goal reminder-flag field exists on the domain yet, and this story's
/// Epic 4 boundary note says that's fine): it's discarded on Save so the
/// wizard's 7-step structure is complete now without blocking on Epic 4.
/// Always valid — no required input.
class RemindersStep extends ConsumerWidget {
  const RemindersStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalWizardProvider);
    final notifier = ref.read(goalWizardProvider.notifier);
    final colors = AppColors.of(context);

    return ListView(
      children: [
        Text(
          'Want a reminder?',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          'A daily reminder can be set up later in Settings.',
          style: TextStyle(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s4),
        SwitchListTile(
          key: const Key('wizard-reminder-toggle'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me about this goal'),
          value: state.reminderOptIn,
          onChanged: notifier.setReminderOptIn,
        ),
      ],
    );
  }
}
