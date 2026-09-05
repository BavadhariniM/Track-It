import 'package:flutter/material.dart';

import '../../domain/entities/day_status.dart';
import 'design_tokens.dart';

/// The `status-cell` component (UX-DR6): fixed-size square, `rounded.sm`,
/// filled with exactly one status color, plus a compact glyph so status
/// never depends on color alone, and a screen-reader label. Built
/// generically over the whole [DayStatusValue] enum from day one — this
/// story only exercises `success`, but `fail`/`cheat`/`empty`/`pending`
/// (Stories 1.4, 1.8) render correctly without touching this widget again.
class StatusCell extends StatelessWidget {
  const StatusCell({required this.status, this.size = 32, super.key});

  final DayStatusValue status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (fill, onFill, glyph, semanticLabel) = switch (status) {
      DayStatusValue.success => (
        colors.statusSuccess,
        colors.statusSuccessOn,
        '✓',
        'Success',
      ),
      DayStatusValue.fail => (
        colors.statusFail,
        colors.statusFailOn,
        '✕',
        'Failed, certain',
      ),
      DayStatusValue.cheat => (
        colors.statusCheat,
        colors.statusCheatOn,
        'C',
        'Cheat day used',
      ),
      DayStatusValue.empty => (
        colors.statusEmpty,
        colors.statusEmptyOn,
        '–',
        'Not eligible',
      ),
      DayStatusValue.pending => (
        colors.statusPending,
        colors.statusPendingOn,
        '…',
        'Pending',
      ),
    };

    return Semantics(
      label: semanticLabel,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: ExcludeSemantics(
          child: Text(
            glyph,
            style: TextStyle(
              color: onFill,
              fontWeight: FontWeight.w600,
              fontSize: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
