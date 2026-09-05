import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/goal_version.dart';
import '../../../domain/entities/goal_version_draft.dart';
import '../../../domain/evaluator/date_format.dart';
import '../../../domain/services/goal_service_result.dart';
import '../../../domain/services/result.dart';
import '../../providers/goal_service_provider.dart';
import '../../providers/goal_wizard_provider.dart';
import '../design_tokens.dart';
import '../primary_button.dart';
import 'review_sentence.dart';

/// Step 7 (Subtasks 8.1-8.3): restates the full rule as one plain-language
/// sentence, then Save calls `GoalService.createGoal` — the only write in
/// the entire wizard flow (AC #4). On success, pops back to whatever
/// pushed the wizard (Day View, per this story's scope) so Panda sees the
/// new goal appear immediately.
class ReviewStep extends ConsumerStatefulWidget {
  const ReviewStep({super.key});

  @override
  ConsumerState<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends ConsumerState<ReviewStep> {
  bool _saving = false;
  String? _errorText;

  Future<void> _save() async {
    final state = ref.read(goalWizardProvider);
    setState(() {
      _saving = true;
      _errorText = null;
    });

    if (state.isEditMode) {
      await _saveEdit(state);
      return;
    }

    final result = await ref
        .read(goalServiceProvider)
        .createGoal(
          name: state.name,
          description: state.description,
          category: state.category,
          startDate: formatDateOnly(state.startDate),
          endDate: state.endDate == null
              ? null
              : formatDateOnly(state.endDate!),
          evaluationPeriod: state.encodedEvaluationPeriod,
          eligibleDaysRule: state.eligibleDaysPattern.encode(),
          targetComparison: state.effectiveTargetComparison,
          targetValue: state.effectiveTargetValueText,
          trackingType: state.trackingType!,
          cheatDayQuota: state.cheatDayQuota,
        );

    if (!mounted) return;

    switch (result) {
      case Success<dynamic>():
        ref.read(goalWizardProvider.notifier).reset();
        Navigator.of(context).pop();
      case Failure<dynamic>(:final message):
        setState(() {
          _saving = false;
          _errorText = message;
        });
    }
  }

  /// Task 4.4/4.5: edit-mode Save routes to `editGoalVersion` instead of
  /// `createGoal`. On `versionLocked`, the wizard jumps back to the Dates
  /// step with the specific UX-DR19 message rather than showing a Review-
  /// step error — `GoalWizard.reportVersionLocked` does the step change.
  ///
  /// Story 3.5 Subtask 1.2: the category assignment is saved first via
  /// `updateGoalCategory` — a direct, non-versioned `GOAL` metadata write,
  /// independent of whether the rule edit below succeeds or is rejected as
  /// `versionLocked`.
  Future<void> _saveEdit(GoalWizardState state) async {
    await ref
        .read(goalServiceProvider)
        .updateGoalCategory(
          goalId: state.editingGoalId!,
          category: state.category,
        );

    if (!mounted) return;

    final result = await ref
        .read(goalServiceProvider)
        .editGoalVersion(
          goalId: state.editingGoalId!,
          effectiveDate: formatDateOnly(state.startDate),
          newRules: GoalVersionDraft(
            evaluationPeriod: state.encodedEvaluationPeriod,
            eligibleDaysRule: state.eligibleDaysPattern.encode(),
            targetComparison: state.effectiveTargetComparison,
            targetValue: state.effectiveTargetValueText,
            trackingType: state.trackingType!,
            cheatDayQuota: state.cheatDayQuota,
          ),
        );

    if (!mounted) return;

    switch (result) {
      case GoalServiceSuccess<GoalVersion>():
        ref.read(goalWizardProvider.notifier).reset();
        Navigator.of(context).pop();
      case GoalServiceFailureResult<GoalVersion>(:final reason):
        ref
            .read(goalWizardProvider.notifier)
            .reportVersionLocked(reason.message, state.startDate);
        setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalWizardProvider);
    final colors = AppColors.of(context);
    final sentence = buildReviewSentence(state);

    return ListView(
      children: [
        Text(
          'Review',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          state.name,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Container(
          key: const Key('wizard-review-sentence'),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.s4),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            border: Border.all(color: colors.borderHairline),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            sentence,
            style: TextStyle(color: colors.textPrimary, fontSize: 16),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: AppSpacing.s3),
          Text(_errorText!, style: TextStyle(color: colors.statusFail)),
        ],
        const SizedBox(height: AppSpacing.s5),
        PrimaryButton(
          key: const Key('wizard-save-button'),
          label: _saving ? 'Saving…' : 'Save',
          onPressed: (_saving || !state.reviewStepValid) ? null : _save,
        ),
      ],
    );
  }
}
