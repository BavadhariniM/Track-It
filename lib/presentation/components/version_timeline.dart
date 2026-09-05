import 'package:flutter/material.dart';

import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_version.dart';
import 'design_tokens.dart';
import 'wizard/review_sentence.dart';

/// Story 3.2's Version Timeline (UX-DR17): a horizontal, dated-segment strip
/// — one segment per [GoalVersion], positioned separately from (never merged
/// into) the historical calendar below it. A read-only projection of
/// `GoalVersion` history already written by `GoalService` (Epic 2, AD-6) —
/// this component adds no new write path.
class VersionTimeline extends StatelessWidget {
  const VersionTimeline({required this.goal, required this.versions, super.key});

  final Goal goal;
  final List<GoalVersion> versions;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    // `versionStartDate` is a naive ISO-8601 date-only string, so
    // lexicographic sort orders it correctly (the same client-side sort
    // every other consumer of unordered Version reads already applies).
    final sorted = [...versions]
      ..sort((a, b) => a.versionStartDate.compareTo(b.versionStartDate));

    return SizedBox(
      key: const Key('goal-detail-version-timeline'),
      height: 56,
      child: Row(
        children: [
          for (var i = 0; i < sorted.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: _VersionSegment(
                key: Key('goal-detail-version-segment-$i'),
                goal: goal,
                version: sorted[i],
                rangeLabel: _rangeLabel(sorted, i),
                colors: colors,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// AC 2's example format: "Jan 1–Mar 14" for a closed segment, or
  /// "Mar 15–present" for the segment currently in effect (always the
  /// latest by `versionStartDate`).
  String _rangeLabel(List<GoalVersion> sorted, int i) {
    final start = _formatDate(DateTime.parse(sorted[i].versionStartDate));
    if (i == sorted.length - 1) return '$start – present';
    final nextStart = DateTime.parse(sorted[i + 1].versionStartDate);
    final end = _formatDate(nextStart.subtract(const Duration(days: 1)));
    return '$start – $end';
  }
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime date) => '${_monthNames[date.month - 1]} ${date.day}';

class _VersionSegment extends StatelessWidget {
  const _VersionSegment({
    required this.goal,
    required this.version,
    required this.rangeLabel,
    required this.colors,
    super.key,
  });

  final Goal goal;
  final GoalVersion version;
  final String rangeLabel;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.bgSurface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => _showVersionDetail(context, goal, version),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.borderHairline),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
          child: Text(
            rangeLabel,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tap-on-segment detail (Subtask 4.2): that Version's rules restated as
/// plain text via the wizard's own Review-step sentence builder (UX-DR15) —
/// never a raw field-by-field diff.
Future<void> _showVersionDetail(
  BuildContext context,
  Goal goal,
  GoalVersion version,
) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      final colors = AppColors.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Text(
            buildReviewSentence(wizardStateForVersion(goal, version)),
            key: const Key('goal-detail-version-detail-text'),
            style: TextStyle(color: colors.textPrimary, fontSize: 16),
          ),
        ),
      );
    },
  );
}
