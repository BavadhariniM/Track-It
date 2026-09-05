import 'package:flutter/material.dart';

import '../../domain/entities/day_status.dart';
import '../../domain/entities/rule_values.dart';
import 'design_tokens.dart';
import 'status_cell.dart';

/// The `goal-row` component (UX-DR7): status dot + goal name, then either a
/// "Done" label (Boolean) or a compact progress bar + fraction (Counter).
/// No inline Cheat Day/Blackout iconography at row level. The single shared
/// row component every tracking type renders through — not a second row
/// component per type.
class GoalRow extends StatelessWidget {
  const GoalRow({
    required this.name,
    required this.status,
    required this.trackingType,
    this.currentValue,
    this.targetValue,
    this.targetComparison,
    this.showDnfBadge = false,
    this.streak,
    this.onTap,
    this.onNameTap,
    this.onLongPress,
    super.key,
  });

  final String name;
  final DayStatusValue status;
  final String trackingType;

  /// The Counter variant's Target Comparison (`TargetComparison.atLeast`/
  /// `atMost`/`exactly`) — purely a display concern here (which symbol, if
  /// any, prefixes [targetValue]), never re-deriving the pass/fail verdict
  /// [status] already carries. `null` for Boolean goals, which have no
  /// fraction to annotate. Without this, "0/2" reads identically whether
  /// the goal needs *at least* 2 (0/2 should look unmet) or *at most* 2 (0/2
  /// is a legitimate, complete Success) — the fraction alone can't
  /// distinguish a floor from a ceiling.
  final String? targetComparison;

  /// Story 2.5 AC 1/UX-DR20: renders a supplementary "DNF · pending period
  /// close" `meta`-typography label beneath [name] — a goal-row-level
  /// annotation layered on top of the existing Pending `status-cell`, not a
  /// sixth `status-cell` glyph (DESIGN.md's `status-cell` is fixed at five).
  /// Callers gate this strictly on `DayStatus == pending` (Task 4.3): once
  /// the period resolves, this flips to `false` and the badge disappears
  /// with no separate write.
  final bool showDnfBadge;

  /// Story 3.1 Subtask 4.4 (UX-DR2/UX-DR19): the goal's current streak,
  /// rendered in `numeric` tabular-figure type as a plain "Streak: N" label
  /// — no cheerleading copy or emoji. `null` renders nothing (a caller that
  /// hasn't computed a streak for this row, or a row that intentionally
  /// omits one).
  final int? streak;

  /// Progress context for the Counter variant; unused by Boolean goals.
  final double? currentValue;
  final double? targetValue;

  final VoidCallback? onTap;

  /// Splits the row into two independent tap zones when non-null: the
  /// leading name/streak area (this callback) and the trailing
  /// status/progress area ([onTap]). When `null` (the default — Day View,
  /// Goals List, Week View), the row keeps its legacy single-zone behavior:
  /// one `InkWell` over the whole row driven by [onTap] alone.
  final VoidCallback? onNameTap;

  /// Opens the Cheat Day / Blackout Date sheet (UX-DR13). Long-press is a
  /// secondary/contextual action, distinct from tap's primary log action
  /// (EXPERIENCE.md Interaction Primitives).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.borderHairline),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: colors.bgSurface,
        child: onNameTap == null
            ? InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s3),
                  child: Row(
                    children: [
                      Expanded(child: _leading(colors)),
                      _trailing(colors),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(AppSpacing.s3),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: onNameTap,
                          onLongPress: onLongPress,
                          child: _leading(colors),
                        ),
                      ),
                      InkWell(
                        onTap: onTap,
                        onLongPress: onLongPress,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s2,
                          ),
                          child: Center(child: _trailing(colors)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _leading(AppColors colors) {
    return Row(
      children: [
        StatusCell(status: status),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(color: colors.textPrimary, fontSize: 16),
              ),
              if (showDnfBadge)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s1),
                  child: Text(
                    'DNF · pending period close',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (streak != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s1),
                  child: Text(
                    'Streak: $streak',
                    style: AppTypography.numeric(
                      colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// The symbol prefixed onto [targetValue] so the fraction itself says
  /// which kind of target this is: a floor (`at_least`, no symbol — "1/2"
  /// already reads as "1 of 2 needed"), a ceiling (`at_most` — "≤" makes
  /// "0/≤2" read as "0 of a max 2 allowed," not "0 of 2 needed"), or an
  /// exact count (`exactly` — "=").
  String _targetSymbol() {
    return switch (targetComparison) {
      TargetComparison.atMost => '≤',
      TargetComparison.exactly => '=',
      _ => '',
    };
  }

  Widget _trailing(AppColors colors) {
    if (trackingType == TrackingType.counter) {
      final current = currentValue ?? 0;
      final target = targetValue ?? 0;
      final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
      return SizedBox(
        width: 76,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${formatNumeric(current)}/${_targetSymbol()}${formatNumeric(target)}',
              style: AppTypography.numeric(colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.s1),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: colors.borderHairline,
                valueColor: AlwaysStoppedAnimation(colors.accent),
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      'Done',
      style: TextStyle(
        color: colors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
