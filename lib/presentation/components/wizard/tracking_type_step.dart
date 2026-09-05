import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/rule_values.dart';
import '../../providers/goal_wizard_provider.dart';
import '../design_tokens.dart';

/// Step 2: Boolean vs. Counter selection (Subtask 3.1) —
/// `GoalVersion.trackingType`, Stories 1.1/1.2.
class TrackingTypeStep extends ConsumerWidget {
  const TrackingTypeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalWizardProvider);
    final notifier = ref.read(goalWizardProvider.notifier);
    final colors = AppColors.of(context);

    return ListView(
      children: [
        Text(
          'How do you want to track it?',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          'Done / not done goals are marked complete or not each day. '
          'Counter goals track a running number.',
          style: TextStyle(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s4),
        SegmentedButton<String>(
          key: const Key('wizard-tracking-type-selector'),
          segments: const [
            ButtonSegment(
              value: TrackingType.boolean,
              label: Text('Done / not done'),
            ),
            ButtonSegment(value: TrackingType.counter, label: Text('Counter')),
          ],
          selected: {if (state.trackingType != null) state.trackingType!},
          emptySelectionAllowed: true,
          onSelectionChanged: (selection) {
            if (selection.isEmpty) return;
            notifier.setTrackingType(selection.first);
          },
        ),
      ],
    );
  }
}
