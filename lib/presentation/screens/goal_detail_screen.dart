import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/day_status.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_lifecycle_status.dart';
import '../../domain/entities/goal_version.dart';
import '../../domain/evaluator/date_format.dart';
import '../components/design_tokens.dart';
import '../components/secondary_button.dart';
import '../components/stat_card.dart';
import '../components/status_cell.dart';
import '../components/version_timeline.dart';
import '../components/wizard/review_sentence.dart';
import '../providers/goal_data_providers.dart';
import '../providers/goal_service_provider.dart';
import '../providers/goal_wizard_provider.dart';
import '../providers/stats_providers.dart';
import 'goal_creation_wizard.dart';

/// The first version of Goal Detail (Story 2.1 Task 4.1): goal name, a
/// plain-language summary of the current (latest) Version's rules, and the
/// `button-secondary` Edit action (UX-DR10 — this component's first use in
/// the app). Story 2.2 adds Pause/Resume here, Story 2.3 adds Archive-state
/// handling, and Story 3.2 (Epic 3) extends this same file with stat-cards,
/// the Version Timeline, and the historical calendar — one continuously
/// extended screen across Stories 2.1 -> 2.2 -> 2.3 -> 3.2, never a second
/// competing implementation (this story's Dev Notes, "Screen ownership").
class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({required this.goal, super.key});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final versionsAsync = ref.watch(goalVersionsProvider(goal.id));

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: Text(goal.name)),
      body: versionsAsync.when(
        data: (versions) {
          if (versions.isEmpty) return const SizedBox.shrink();
          final latest = _latestVersion(versions);
          final today = formatDateOnly(DateTime.now());
          final isPaused =
              resolveLifecycleStatus(
                goal: goal,
                versions: versions,
                today: today,
              ) ==
              GoalLifecycleStatus.paused;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  buildReviewSentence(wizardStateForVersion(goal, latest)),
                  key: const Key('goal-detail-rule-summary'),
                  style: TextStyle(color: colors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.s5),
                Wrap(
                  spacing: AppSpacing.s3,
                  runSpacing: AppSpacing.s3,
                  children: [
                    SecondaryButton(
                      key: const Key('goal-detail-edit-button'),
                      label: 'Edit',
                      onPressed: () => _openEditWizard(context, ref, latest),
                    ),
                    // Story 2.2 Subtask 4.2: single-tap, no confirmation
                    // step (UX-DR24 reserves two-step confirmation for
                    // Reset/Erase-All only — pause/resume is reversible and
                    // history-preserving).
                    SecondaryButton(
                      key: const Key('goal-detail-pause-resume-button'),
                      label: isPaused ? 'Resume' : 'Pause',
                      onPressed: () =>
                          _togglePause(ref, goal.id, isPaused, today),
                    ),
                    // Story 2.3 Subtask 3.4: single-tap, no confirmation
                    // dialog (UX-DR24 — archive is reversible/
                    // history-preserving, unlike Reset/Erase-All).
                    SecondaryButton(
                      key: const Key('goal-detail-archive-button'),
                      label: 'Archive',
                      onPressed: () => _archiveGoal(context, ref, goal.id),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s5),
                _StatCardRow(goalId: goal.id),
                const SizedBox(height: AppSpacing.s5),
                Text(
                  'Version Timeline',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                VersionTimeline(goal: goal, versions: versions),
                const SizedBox(height: AppSpacing.s5),
                Text(
                  'Historical Calendar',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                _HistoricalCalendar(goalId: goal.id),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Something went wrong: $error')),
      ),
    );
  }

  void _openEditWizard(
    BuildContext context,
    WidgetRef ref,
    GoalVersion latest,
  ) {
    ref
        .read(goalWizardProvider.notifier)
        .loadForEdit(goal: goal, version: latest);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const GoalCreationWizard()));
  }

  /// Task 4.3: effective date defaults to today, consistent with Story
  /// 2.1's edit flow — pause/resume has no wizard step to override it from.
  void _togglePause(WidgetRef ref, String goalId, bool isPaused, String today) {
    final service = ref.read(goalServiceProvider);
    if (isPaused) {
      service.resumeGoal(goalId: goalId, effectiveDate: today);
    } else {
      service.pauseGoal(goalId: goalId, effectiveDate: today);
    }
  }

  /// Story 2.3 Subtask 3.4: archives [goalId] and shows a brief,
  /// non-blocking confirmation of consequence — the exact copy from
  /// EXPERIENCE.md's Voice and Tone (UX-DR19), not paraphrased.
  Future<void> _archiveGoal(
    BuildContext context,
    WidgetRef ref,
    String goalId,
  ) async {
    await ref.read(goalServiceProvider).archiveGoal(goalId: goalId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Archived Goals leave active views but keep full history',
        ),
      ),
    );
  }
}

/// `versionStartDate` is a naive ISO-8601 date-only string (Data
/// conventions), so lexicographic comparison sorts it correctly.
GoalVersion _latestVersion(List<GoalVersion> versions) {
  final sorted = [...versions]
    ..sort((a, b) => a.versionStartDate.compareTo(b.versionStartDate));
  return sorted.last;
}

/// AC 1's full statistics grid (Story 3.2 Subtask 3.1/3.2, extended by
/// Story 3.4 Subtask 2.1/2.2) — one bundled [GoalStats] fetch, never a
/// locally-computed number (AD-8), rendered as `stat-card`s in a `Wrap`
/// grid rather than a single fixed `Row` now that the card count varies per
/// goal. Story 3.3 AC 3/Subtask 3.1: a Rolling Window goal has no Streak
/// stat at all — [GoalStats.currentStreak] is `null` for it, and this row
/// substitutes [_CurrentPaceCard] for the two streak cards rather than
/// rendering a fabricated 0. Story 3.4 AC 1: successful/failed period
/// counts are omitted the same way for a Rolling Window goal (`null`), and
/// average/total value cards only appear for a Counter goal (Subtask 2.2)
/// — never a zero or N/A card for a Boolean goal, which simply never
/// receives those two cards at all.
class _StatCardRow extends ConsumerWidget {
  const _StatCardRow({required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(goalStatsProvider(goalId));
    return statsAsync.when(
      data: (stats) {
        final currentStreak = stats.currentStreak;
        final longestStreak = stats.longestStreak;
        final successfulPeriods = stats.successfulPeriods;
        final failedPeriods = stats.failedPeriods;
        final averageValue = stats.averageValue;
        final totalValue = stats.totalValue;

        final cards = <Widget>[
          if (currentStreak != null && longestStreak != null) ...[
            StatCard(
              key: const Key('goal-detail-current-streak-card'),
              label: 'Current Streak',
              value: '$currentStreak',
            ),
            StatCard(
              key: const Key('goal-detail-longest-streak-card'),
              label: 'Longest Streak',
              value: '$longestStreak',
            ),
          ] else
            _CurrentPaceCard(goalId: goalId),
          StatCard(
            key: const Key('goal-detail-completion-card'),
            label: 'Completion %',
            value: '${formatNumeric(stats.completionPercentage)}%',
          ),
          if (successfulPeriods != null)
            StatCard(
              key: const Key('goal-detail-successful-periods-card'),
              label: 'Successful Periods',
              value: '$successfulPeriods',
            ),
          if (failedPeriods != null)
            StatCard(
              key: const Key('goal-detail-failed-periods-card'),
              label: 'Failed Periods',
              value: '$failedPeriods',
            ),
          StatCard(
            key: const Key('goal-detail-cheat-days-card'),
            label: 'Cheat Days',
            value: '${stats.cheatDayCount}',
          ),
          if (averageValue != null)
            StatCard(
              key: const Key('goal-detail-average-value-card'),
              label: 'Average Value',
              value: formatNumeric(averageValue),
            ),
          if (totalValue != null)
            StatCard(
              key: const Key('goal-detail-total-value-card'),
              label: 'Total Value',
              value: formatNumeric(totalValue),
            ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - AppSpacing.s3) / 2;
            return Wrap(
              key: const Key('goal-detail-stat-card-grid'),
              spacing: AppSpacing.s3,
              runSpacing: AppSpacing.s3,
              children: [
                for (final card in cards)
                  SizedBox(width: cardWidth, child: card),
              ],
            );
          },
        );
      },
      loading: () => const SizedBox(
        height: 88,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text('Something went wrong: $error'),
    );
  }
}

/// Story 3.3 Subtask 3.1: a Rolling Window goal's "current pace/status" in
/// place of a Streak stat-card — sourced from [historicalStatusesProvider],
/// the same provider the Historical Calendar already watches (its last
/// entry is today's status, per that provider's own doc), never a second
/// live-status fetch. A Counter goal (the common Rolling Window case, e.g.
/// "10x in any trailing 14 days") shows its numeric current/target
/// fraction; a Boolean goal falls back to today's status label.
class _CurrentPaceCard extends ConsumerWidget {
  const _CurrentPaceCard({required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesAsync = ref.watch(historicalStatusesProvider(goalId));
    return statusesAsync.when(
      data: (statuses) {
        final today = statuses.isEmpty ? null : statuses.last;
        return StatCard(
          key: const Key('goal-detail-current-pace-card'),
          label: 'Current Pace',
          value: today == null ? '—' : _paceValue(today),
        );
      },
      loading: () => const StatCard(label: 'Current Pace', value: '…'),
      error: (error, _) => const StatCard(label: 'Current Pace', value: '—'),
    );
  }

  String _paceValue(DayStatus today) {
    final target = today.targetValue;
    if (target != null) {
      return '${formatNumeric(today.currentValue ?? 0)}/${formatNumeric(target)}';
    }
    return switch (today.status) {
      DayStatusValue.success => 'On track',
      DayStatusValue.fail => 'Missed',
      DayStatusValue.cheat => 'Cheat day used',
      DayStatusValue.pending => 'In progress',
      DayStatusValue.empty => 'Not eligible',
    };
  }
}

/// AC 1's historical calendar (Task 2): reuses `status-cell` (Epic 1,
/// UX-DR6) per day, sourced from [historicalStatusesProvider] — a
/// cache-reading surface distinct from the live Day/Week/Month calendar
/// (AD-7's cache-exclusion rule is scoped to that live surface only).
class _HistoricalCalendar extends ConsumerWidget {
  const _HistoricalCalendar({required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesAsync = ref.watch(historicalStatusesProvider(goalId));
    return statusesAsync.when(
      data: (statuses) => Wrap(
        key: const Key('goal-detail-historical-calendar'),
        spacing: 2,
        runSpacing: 2,
        children: [
          for (final status in statuses)
            StatusCell(status: status.status, size: 16),
        ],
      ),
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text('Something went wrong: $error'),
    );
  }
}
