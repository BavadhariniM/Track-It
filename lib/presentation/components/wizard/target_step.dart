import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/rule_values.dart';
import '../../providers/goal_wizard_provider.dart';
import '../design_tokens.dart';
import 'streak_clarification_banner.dart';

/// Step 4: Target Comparison + value (Subtasks 5.1-5.3).
///
/// At Least/At Most/Exactly are all valid for both Tracking Types (Story
/// 1.7) — no comparison is Boolean- or Counter-only, and there is no
/// Range/bounded option. A Boolean goal on a Daily period is the one
/// exception (see `GoalWizardState.isFixedBooleanDaily`): `evaluate()`'s
/// Daily/Boolean branch never reads the comparison or value at all, so
/// asking Panda to pick a meaningless number would be its own kind of
/// under-implementation — this step shows a fixed statement instead.
class TargetStep extends ConsumerStatefulWidget {
  const TargetStep({super.key});

  @override
  ConsumerState<TargetStep> createState() => _TargetStepState();
}

class _TargetStepState extends ConsumerState<TargetStep> {
  late final TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: ref.read(goalWizardProvider).targetValueText,
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalWizardProvider);
    final notifier = ref.read(goalWizardProvider.notifier);
    final colors = AppColors.of(context);

    return ListView(
      children: [
        Text(
          'What counts as success?',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        if (state.isFixedBooleanDaily)
          Text(
            'This goal is simply marked done or not done each eligible day '
            '— no target number needed.',
            key: const Key('wizard-fixed-boolean-daily-note'),
            style: TextStyle(color: colors.textSecondary),
          )
        else ...[
          SegmentedButton<String>(
            key: const Key('wizard-target-comparison-selector'),
            segments: const [
              ButtonSegment(
                value: TargetComparison.atLeast,
                label: Text('At least'),
              ),
              ButtonSegment(
                value: TargetComparison.atMost,
                label: Text('At most'),
              ),
              ButtonSegment(
                value: TargetComparison.exactly,
                label: Text('Exactly'),
              ),
            ],
            selected: {
              if (state.targetComparison != null) state.targetComparison!,
            },
            emptySelectionAllowed: true,
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              notifier.setTargetComparison(selection.first);
            },
          ),
          const SizedBox(height: AppSpacing.s4),
          TextField(
            key: const Key('wizard-target-value-field'),
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTypography.numeric(colors.textPrimary, fontSize: 20),
            decoration: const InputDecoration(labelText: 'Target value'),
            onChanged: notifier.setTargetValueText,
          ),
        ],
        if (state.targetStepShowsStreakBanner) ...[
          const SizedBox(height: AppSpacing.s4),
          const StreakClarificationBanner(),
        ],
      ],
    );
  }
}
