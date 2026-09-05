import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// The `stat-card` component (UX-DR8): a `card-surface`-styled tile for one
/// numeric stat — big `numeric` tabular-figure value, small label beneath,
/// no icons. Introduced by Story 3.2 for Goal Detail's Streak/longest
/// Streak/completion % row; Story 3.4 adds more cards to the same grid
/// through this exact widget, never a second stat-display pattern.
class StatCard extends StatelessWidget {
  const StatCard({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderHairline),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTypography.numeric(colors.textPrimary, fontSize: 24)),
          const SizedBox(height: AppSpacing.s1),
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
