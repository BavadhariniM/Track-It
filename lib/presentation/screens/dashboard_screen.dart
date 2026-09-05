import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/day_status.dart';
import '../../domain/entities/rule_values.dart';
import '../../domain/evaluator/date_format.dart';
import '../../domain/evaluator/evaluate.dart';
import '../../domain/services/stats_service.dart';
import '../components/cheat_blackout_sheet.dart';
import '../components/counter_stepper.dart';
import '../components/design_tokens.dart';
import '../components/goal_row.dart';
import '../providers/goal_data_providers.dart';
import '../providers/goal_service_provider.dart';
import '../providers/reminder_settings_provider.dart';
import '../providers/stats_providers.dart';
import 'goal_detail_screen.dart';

/// The Today tab (FR-26): today's eligible goals with progress, this week's/
/// month's in-progress rollups, and the next reminder time — the app's
/// landing surface (EXPERIENCE.md's Information Architecture table).
///
/// Which goals appear, plus the Week/Month rollup sections, are sourced
/// from [StatsService] (AD-7/AD-8, its cached period-aggregate status).
/// Each row's own rendered status-cell, however, calls `evaluateDayOnly()`
/// fresh (mirroring Day View's `_GoalRowForDate`) — "did today get logged
/// done" needs to be live, not cache-derived, the same reason Day/Week/
/// Month View never read the cache either (AD-7). Bug 8: rows also wire up
/// `GoalService` writes (toggle/counter/Cheat/Blackout) scoped to today —
/// those write paths call `evaluate()` internally elsewhere
/// (`CounterStepperDialog`, `showCheatBlackoutSheet`).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final todayAsync = ref.watch(todayProgressProvider);
    final reminderAsync = ref.watch(reminderTimeProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Today')),
      body: todayAsync.when(
        data: (todayGoals) => ListView(
          padding: const EdgeInsets.all(AppSpacing.s4),
          children: [
            if (reminderAsync.value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                child: Text(
                  'Next reminder: ${reminderAsync.value!.toString()}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ),
            if (todayGoals.isEmpty)
              Text(
                'No goals eligible today',
                style: TextStyle(color: colors.textSecondary),
              )
            else
              for (final goalStatus in todayGoals) ...[
                _DashboardGoalRow(goalStatus: goalStatus),
                const SizedBox(height: AppSpacing.s3),
              ],
            const SizedBox(height: AppSpacing.s6),
            _RollupSection(
              title: 'This Week',
              watch: (ref) => ref.watch(weekRollupProvider),
            ),
            const SizedBox(height: AppSpacing.s6),
            _RollupSection(
              title: 'This Month',
              watch: (ref) => ref.watch(monthRollupProvider),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Something went wrong: $error')),
      ),
    );
  }
}

class _RollupSection extends ConsumerWidget {
  const _RollupSection({required this.title, required this.watch});

  final String title;
  final AsyncValue<List<GoalStatus>> Function(WidgetRef ref) watch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final rollupAsync = watch(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        rollupAsync.when(
          data: (goals) => goals.isEmpty
              ? Text(
                  'Nothing in progress',
                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                )
              : Column(
                  children: [
                    for (final goalStatus in goals) ...[
                      _DashboardGoalRow(goalStatus: goalStatus),
                      const SizedBox(height: AppSpacing.s3),
                    ],
                  ],
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Text('Something went wrong: $error', style: TextStyle(color: colors.statusFail)),
        ),
      ],
    );
  }
}

/// Renders one [GoalStatus] via the shared `goal-row` component (Subtask
/// 4.1) — reads the goal's Version stream only to pick the Boolean/Counter
/// display variant (a display field, not a status computation), the same
/// pattern `goals_list_screen.dart`'s row already uses. Bug 8: also reads
/// today's own log (`goalLogsProvider`) to gate the right-side toggle/undo,
/// mirroring `_GoalRowForDate`'s Bug 4 guard, scoped to today.
class _DashboardGoalRow extends ConsumerWidget {
  const _DashboardGoalRow({required this.goalStatus});

  final GoalStatus goalStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = goalStatus.goal;
    final versions = ref.watch(goalVersionsProvider(goal.id)).value;
    final trackingType = versions != null && versions.isNotEmpty
        ? versions.first.trackingType
        : TrackingType.boolean;
    final targetComparison = versions != null && versions.isNotEmpty
        ? versions.first.targetComparison
        : null;
    final streakAsync = ref.watch(currentStreakProvider(goal.id));
    final logs = ref.watch(goalLogsProvider(goal.id)).value ?? const [];
    final blackoutDates = ref.watch(blackoutDatesProvider(goal.id)).value;
    final cheatDays = ref.watch(cheatDaysProvider(goal.id)).value;

    final today = formatDateOnly(DateTime.now());
    final logsForToday = logs.where((log) => log.date == today);
    final logForToday = logsForToday.isEmpty ? null : logsForToday.last;
    final ownLogCompleted = logForToday?.completed ?? false;

    // What's actually rendered: "did today get logged done," not "is the
    // whole period on track" (mirrors Day View's `_GoalRowForDate` — see
    // `evaluate.dart`'s `evaluateDayOnly` doc comment). Falls back to
    // `goalStatus.dayStatus` (StatsService's cached period-aggregate) only
    // while this goal's own Versions/blackout/cheat data hasn't loaded yet.
    final dayOnlyStatus = versions == null || blackoutDates == null || cheatDays == null
        ? goalStatus.dayStatus
        : evaluateDayOnly(
            goal: goal,
            versions: versions,
            logs: logs,
            blackoutDates: blackoutDates,
            cheatDays: cheatDays,
            date: DateTime.now(),
          );
    final periodResolvedElsewhere =
        dayOnlyStatus.status == DayStatusValue.success && !ownLogCompleted;

    void openCheatBlackoutSheet() {
      showCheatBlackoutSheet(context: context, goal: goal, date: DateTime.now());
    }

    VoidCallback? onTap;
    if (trackingType == TrackingType.counter) {
      onTap = () {
        showDialog<void>(
          context: context,
          builder: (_) => CounterStepperDialog(goal: goal, date: DateTime.now()),
        );
      };
    } else if (!periodResolvedElsewhere) {
      onTap = () {
        final goalService = ref.read(goalServiceProvider);
        if (ownLogCompleted) {
          goalService.undoBooleanLog(
            goalId: goal.id,
            logId: logForToday!.id,
            date: today,
          );
        } else {
          goalService.logBoolean(goalId: goal.id, date: today, completed: true);
        }
      };
    }

    return GoalRow(
      name: goal.name,
      status: dayOnlyStatus.status,
      trackingType: trackingType,
      currentValue: dayOnlyStatus.currentValue,
      targetValue: dayOnlyStatus.targetValue,
      targetComparison: targetComparison,
      streak: streakAsync.value,
      onNameTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
      ),
      onTap: onTap,
      onLongPress: openCheatBlackoutSheet,
    );
  }
}
