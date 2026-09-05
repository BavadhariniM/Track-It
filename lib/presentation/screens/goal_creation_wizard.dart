import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/design_tokens.dart';
import '../components/primary_button.dart';
import '../components/wizard/dates_step.dart';
import '../components/wizard/name_step.dart';
import '../components/wizard/reminders_step.dart';
import '../components/wizard/review_step.dart';
import '../components/wizard/schedule_step.dart';
import '../components/wizard/target_step.dart';
import '../components/wizard/tracking_type_step.dart';
import '../components/wizard_progress.dart';
import '../providers/goal_wizard_provider.dart';

/// The guided, one-decision-at-a-time goal-creation flow (Story 1.9),
/// replacing the placeholder `CreateGoalScreen` from Stories 1.1-1.6.
///
/// Linear, 7-step, fixed order (UX-DR15): name → tracking type → schedule
/// → target → dates → reminders → review — no step-skipping via
/// tap-ahead (EXPERIENCE.md Interaction Primitives). Back is always
/// enabled (exiting the wizard on step 1); Next is disabled until the
/// current step's own validation predicate passes. Nothing is written to
/// `GoalService` until Review's Save button (Subtask 1.4).
///
/// Steps are held in an `IndexedStack` rather than a `PageView`/lazily
/// built route so that a step's own local widget state (e.g. the
/// `RecurrenceSelector`'s internal recurrence-kind selection) survives
/// Back-then-forward navigation within one wizard session.
class GoalCreationWizard extends ConsumerWidget {
  const GoalCreationWizard({super.key});

  static const _totalSteps = GoalWizardState.totalSteps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalWizardProvider);
    final notifier = ref.read(goalWizardProvider.notifier);
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: WizardProgress(
          currentStep: state.step + 1,
          totalSteps: GoalCreationWizard._totalSteps,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: IndexedStack(
            index: state.step,
            children: const [
              NameStep(),
              TrackingTypeStep(),
              ScheduleStep(),
              TargetStep(),
              DatesStep(),
              RemindersStep(),
              ReviewStep(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.s4),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('wizard-back-button'),
                onPressed: () {
                  if (state.step == 0) {
                    Navigator.of(context).pop();
                  } else {
                    notifier.goBack();
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
            // The Review step's own Save button is the forward action on
            // the last step — no Next slot there.
            if (state.step < GoalCreationWizard._totalSteps - 1) ...[
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: PrimaryButton(
                  key: const Key('wizard-next-button'),
                  label: 'Next',
                  onPressed: state.isStepValid(state.step)
                      ? notifier.goNext
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
