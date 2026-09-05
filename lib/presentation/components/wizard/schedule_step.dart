import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/goal_wizard_provider.dart';
import '../design_tokens.dart';
import '../recurrence_selector.dart';
import 'streak_clarification_banner.dart';

/// Step 3: Evaluation Period + Eligible-Days Rule (Subtasks 4.1-4.3).
///
/// Evaluation Period (Daily/Weekly/Biweekly/Monthly/Quarterly/Yearly/
/// Rolling-Window) and Eligible-Days (Story 1.4/1.5's `RecurrenceSelector`,
/// reused directly — never rebuilt) are two fully independent axes here,
/// exactly as the domain layer treats them (see
/// `GoalWizardState`'s doc comment for why "Custom" isn't a separate
/// Evaluation Period entry in this UI).
///
/// Blackout Dates are intentionally not configured here (Subtask 4.4) —
/// they're marked per-date from an existing goal's Day View, not during
/// creation.
class ScheduleStep extends ConsumerWidget {
  const ScheduleStep({super.key});

  static const _periodLabels = {
    WizardEvaluationPeriodKind.daily: 'Daily',
    WizardEvaluationPeriodKind.weekly: 'Weekly',
    WizardEvaluationPeriodKind.biweekly: 'Biweekly',
    WizardEvaluationPeriodKind.monthly: 'Monthly',
    WizardEvaluationPeriodKind.quarterly: 'Quarterly',
    WizardEvaluationPeriodKind.yearly: 'Yearly',
    WizardEvaluationPeriodKind.rollingWindow: 'Rolling window (N days)',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalWizardProvider);
    final notifier = ref.read(goalWizardProvider.notifier);
    final colors = AppColors.of(context);

    return ListView(
      children: [
        Text(
          'How often does this apply?',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        DropdownButton<String>(
          key: const Key('wizard-evaluation-period-dropdown'),
          value: state.evaluationPeriodKind,
          isExpanded: true,
          items: [
            for (final entry in _periodLabels.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: (value) {
            if (value == null) return;
            notifier.setEvaluationPeriodKind(value);
          },
        ),
        if (state.evaluationPeriodKind ==
            WizardEvaluationPeriodKind.rollingWindow) ...[
          const SizedBox(height: AppSpacing.s3),
          TextFormField(
            key: const Key('wizard-rolling-window-days-field'),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'N (days)'),
            initialValue: state.rollingWindowDays.toString(),
            onChanged: (value) {
              final n = int.tryParse(value);
              if (n != null) notifier.setRollingWindowDays(n);
            },
          ),
        ],
        if (state.evaluationPeriodKind == WizardEvaluationPeriodKind.daily) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Cheat days allowed (optional)',
            style: TextStyle(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s2),
          Row(
            children: [
              IconButton(
                key: const Key('wizard-cheat-day-quota-decrement'),
                onPressed: state.cheatDayQuota > 0
                    ? () => notifier.setCheatDayQuota(state.cheatDayQuota - 1)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '${state.cheatDayQuota}',
                  textAlign: TextAlign.center,
                  style: AppTypography.numeric(colors.textPrimary),
                ),
              ),
              IconButton(
                key: const Key('wizard-cheat-day-quota-increment'),
                onPressed: () =>
                    notifier.setCheatDayQuota(state.cheatDayQuota + 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
        if (state.scheduleStepShowsStreakBanner) ...[
          const SizedBox(height: AppSpacing.s4),
          const StreakClarificationBanner(),
        ],
        const SizedBox(height: AppSpacing.s5),
        Text(
          'Which days are eligible?',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        RecurrenceSelector(
          initialPattern: state.eligibleDaysPattern,
          onChanged: notifier.setEligibleDaysPattern,
        ),
      ],
    );
  }
}
