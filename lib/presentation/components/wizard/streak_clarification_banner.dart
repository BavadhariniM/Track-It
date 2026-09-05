import 'package:flutter/material.dart';

import '../design_tokens.dart';

/// UX-DR16's Streak clarification — the hardest UX requirement in Story
/// 1.9 (Dev Notes): "Daily goals with cheat days track a real day-by-day
/// Streak. Weekly-count goals track a single pass/fail per week, with no
/// daily Streak." Shown at both the Schedule step and the Target step
/// (Subtask 4.3/5.2) whenever the current wizard selection could be
/// confused between the two contrasted patterns — deliberately a visible
/// bordered card, not a footnote, so it can't be missed (AC #3).
class StreakClarificationBanner extends StatelessWidget {
  const StreakClarificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      key: const Key('streak-clarification-banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.accent, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.accent),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              'Daily goals with cheat days track a real day-by-day Streak. '
              'Weekly-count goals track a single pass/fail per week, with '
              'no daily Streak.',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
