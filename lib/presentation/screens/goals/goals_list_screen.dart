import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/goal.dart';
import '../../../domain/entities/goal_lifecycle_status.dart';
import '../../../domain/entities/goal_version.dart';
import '../../../domain/entities/rule_values.dart';
import '../../../domain/evaluator/date_format.dart';
import '../../../domain/evaluator/evaluate.dart';
import '../../../domain/services/goal_list_sort.dart';
import '../../components/design_tokens.dart';
import '../../components/goal_row.dart';
import '../../providers/goal_data_providers.dart';
import '../../providers/goal_wizard_provider.dart';
import '../goal_creation_wizard.dart';
import '../goal_detail_screen.dart';

/// A minimal, flat goals list (Story 2.1 Task 4.2) so goal rows are
/// reachable outside Day View — Day View's own goal-row tap toggles
/// Boolean/opens the Counter stepper (FR-21) and never navigates to Goal
/// Detail (see this story's Dev Notes). No persistent tab bar exists yet
/// (EXPERIENCE.md's eventual Today/Calendar/Goals/Settings bar is out of
/// this story's scope); reached instead from Month View's app-bar action —
/// a single entry point is enough to unblock Epic 2's edit/pause/archive
/// actions, which all need a UI home before that bar exists.
class GoalsListScreen extends ConsumerWidget {
  const GoalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final goalsAsync = ref.watch(allGoalsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Goals')),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Text(
                'No goals yet',
                style: TextStyle(color: colors.textSecondary),
              ),
            );
          }
          return _GroupedGoalsList(goals: goals);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Something went wrong: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('goals-list-add-goal-fab'),
        tooltip: 'Add goal',
        onPressed: () => _openCreateGoal(context, ref),
        backgroundColor: colors.accent,
        foregroundColor: colors.accentOn,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Unlike `DayViewScreen`, this FAB is never hidden for an empty/loading/
  // error `allGoalsProvider` state: this screen has no inline empty-state
  // create button (Day View's `_EmptyState` does), so hiding it would leave
  // no way to add a goal from here at all. Resets `goalWizardProvider`
  // explicitly on entry (matching `DayViewScreen._openCreateGoal`) rather
  // than relying on a previous session's exit path to have cleaned up,
  // since an abandoned create/edit attempt or an OS back-gesture pop
  // wouldn't otherwise clear stale wizard state.
  void _openCreateGoal(BuildContext context, WidgetRef ref) {
    ref.read(goalWizardProvider.notifier).reset();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const GoalCreationWizard()));
  }
}

/// Story 2.3 Subtask 3.3: groups goals by `resolveLifecycleStatus` (Active/
/// Paused/Archived/Expired) so Archived/Expired goals — hidden from every
/// active-tracking surface (AC 2) — stay reachable somewhere. This is the
/// lifecycle-status grouping only, not full category filtering (that's
/// Story 3.5's FR-25 scope).
class _GroupedGoalsList extends ConsumerWidget {
  const _GroupedGoalsList({required this.goals});

  final List<Goal> goals;

  static const _order = [
    GoalLifecycleStatus.active,
    GoalLifecycleStatus.paused,
    GoalLifecycleStatus.archived,
    GoalLifecycleStatus.expired,
  ];

  static const _labels = {
    GoalLifecycleStatus.active: 'Active',
    GoalLifecycleStatus.paused: 'Paused',
    GoalLifecycleStatus.archived: 'Archived',
    GoalLifecycleStatus.expired: 'Expired',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final today = formatDateOnly(DateTime.now());
    final grouped = <GoalLifecycleStatus, List<Goal>>{};
    // Story 3.5 AC 4/Subtask 4.4: each goal's current Evaluation Period
    // type, read from its current/active (latest by `versionStartDate`)
    // `GoalVersion` — the same "current schedule" read Goal Detail's
    // summary uses (`_latestVersion` there).
    final evaluationPeriodByGoalId = <String, String>{};
    for (final goal in goals) {
      final versions = ref.watch(goalVersionsProvider(goal.id)).value;
      if (versions == null) continue;
      final status = resolveLifecycleStatus(
        goal: goal,
        versions: versions,
        today: today,
      );
      // Bug 5 follow-up: a goal whose startDate is still in the future has
      // no lifecycle bucket of its own (resolveLifecycleStatus falls
      // through to `active`), but `_GoalListRow` now renders nothing for
      // it — so it must not count toward a group's header-visibility check
      // below, or the header would show with no rows beneath it.
      if (today.compareTo(goal.startDate) < 0) continue;
      grouped.putIfAbsent(status, () => []).add(goal);
      evaluationPeriodByGoalId[goal.id] =
          _latestVersion(versions)?.evaluationPeriod ?? '';
    }
    // Story 3.5 AC 4/Subtask 4.1-4.3: within each lifecycle-status group
    // (Story 2.3's grouping), order goals by Evaluation Period frequency —
    // a pure computed sort, never a stored ordering field.
    for (final status in grouped.keys) {
      grouped[status] = sortGoalsByEvaluationPeriod(
        grouped[status]!,
        (goalId) => evaluationPeriodByGoalId[goalId] ?? '',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4 + 56 + AppSpacing.s4,
      ),
      children: [
        for (final status in _order)
          if (grouped[status] case final groupGoals?
              when groupGoals.isNotEmpty) ...[
            Text(
              _labels[status]!,
              key: Key('goals-list-group-${status.name}'),
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            for (final goal in groupGoals) ...[
              _GoalListRow(goal: goal),
              const SizedBox(height: AppSpacing.s3),
            ],
            const SizedBox(height: AppSpacing.s2),
          ],
      ],
    );
  }
}

/// The current/active `GoalVersion` — latest by `versionStartDate` — the
/// same selection `goal_detail_screen.dart`'s own `_latestVersion` uses for
/// its rule summary, duplicated here as a small pure lookup rather than
/// exported cross-module (mirrors `goal_lifecycle_status.dart`'s existing
/// pattern for the same kind of helper).
GoalVersion? _latestVersion(List<GoalVersion> versions) {
  if (versions.isEmpty) return null;
  final sorted = [...versions]
    ..sort((a, b) => a.versionStartDate.compareTo(b.versionStartDate));
  return sorted.last;
}

/// Renders today's status via the same `evaluate()` call site pattern Day
/// View uses (AD-4) — this screen introduces no second evaluation path,
/// only a different tap target (Goal Detail instead of logging).
class _GoalListRow extends ConsumerWidget {
  const _GoalListRow({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versions = ref.watch(goalVersionsProvider(goal.id)).value;
    final logs = ref.watch(goalLogsProvider(goal.id)).value;
    final blackoutDates = ref.watch(blackoutDatesProvider(goal.id)).value;
    if (versions == null || logs == null || blackoutDates == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Bug 5: a goal whose startDate hasn't arrived yet has no governing
    // Version today, so evaluate() would return Empty with no targetValue
    // and the row would render a fallback "0/0" instead of being omitted.
    if (formatDateOnly(today).compareTo(goal.startDate) < 0) {
      return const SizedBox.shrink();
    }

    final dayStatus = evaluate(
      goal: goal,
      versions: versions,
      logs: logs,
      blackoutDates: blackoutDates,
      date: today,
    );
    final trackingType = versions.isNotEmpty
        ? versions.first.trackingType
        : TrackingType.boolean;
    final targetComparison = versions.isNotEmpty
        ? versions.first.targetComparison
        : null;

    return GoalRow(
      name: goal.name,
      status: dayStatus.status,
      trackingType: trackingType,
      currentValue: dayStatus.currentValue,
      targetValue: dayStatus.targetValue,
      targetComparison: targetComparison,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal))),
    );
  }
}
