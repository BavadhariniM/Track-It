import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// The `wizard-progress` component (UX-DR9): a thin top-of-screen bar,
/// `height: 4px`, `radius: rounded.full`, `track: border-hairline`,
/// `fill: accent` — filled proportionally across the 7 steps. This is one
/// of only two places `rounded.full` is used in the entire app (the other
/// being status badges, per UX-DR3) — never buttons (UX-DR10 reserves
/// `rounded.md` for those).
///
/// No step numerals ("Step 3 of 7") are shown anywhere else in the UI —
/// this bar is the only progress indicator (UX-DR9).
class WizardProgress extends StatelessWidget {
  const WizardProgress({
    required this.currentStep,
    required this.totalSteps,
    super.key,
  });

  /// 1-based current step number (e.g. `3` while on the 3rd of 7 steps),
  /// so the bar shows real progress on step 1 and a full bar on the last
  /// step — not `0/7` through `6/7`.
  final int currentStep;

  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final fraction = totalSteps <= 0
        ? 0.0
        : (currentStep / totalSteps).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: SizedBox(
        height: 4,
        child: LinearProgressIndicator(
          value: fraction,
          minHeight: 4,
          backgroundColor: colors.borderHairline,
          valueColor: AlwaysStoppedAnimation(colors.accent),
        ),
      ),
    );
  }
}
