import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/day_status.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_lifecycle_status.dart';
import '../../domain/entities/rule_values.dart';
import '../../domain/evaluator/date_format.dart';
import '../../domain/evaluator/evaluate.dart';
import '../../domain/services/paused_range_helper.dart';
import '../components/cheat_blackout_sheet.dart';
import '../components/counter_stepper.dart';
import '../components/design_tokens.dart';
import '../components/goal_filter_bar.dart';
import '../components/goal_row.dart';
import '../components/primary_button.dart';
import '../providers/current_date_provider.dart';
import '../providers/goal_data_providers.dart';
import '../providers/goal_service_provider.dart';
import '../providers/goal_wizard_provider.dart';
import 'goal_creation_wizard.dart';

/// Satisfies FR-21: tap any calendar date to view/log that day's eligible
/// goals. Only "today" is reachable this story, but the screen accepts an
/// arbitrary [date] so Story 1.10's calendar navigation can push a
/// different date into this same screen without a rewrite. Doubles as the
/// first-run empty-state Dashboard (UX-DR26) since Epic 1 has not yet split
/// Dashboard and Calendar into separate surfaces.
class DayViewScreen extends ConsumerWidget {
  const DayViewScreen({required this.date, super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final allGoalsAsync = ref.watch(allGoalsProvider);
    final filteredGoalsAsync = ref.watch(filteredGoalsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: Text(_titleFor(date))),
      body: Column(
        children: [
          const GoalFilterBar(),
          Expanded(
            child: allGoalsAsync.when(
              data: (allGoals) {
                if (allGoals.isEmpty) {
                  return _EmptyState(
                    onCreate: () => _openCreateGoal(context, ref),
                  );
                }
                final goals = filteredGoalsAsync.value ?? const [];
                if (goals.isEmpty) {
                  return Center(
                    child: Text(
                      'No goals match this filter',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  itemCount: goals.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.s3),
                  itemBuilder: (context, index) {
                    return _GoalRowForDate(goal: goals[index], date: date);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Something went wrong: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: allGoalsAsync.maybeWhen(
        data: (goals) => goals.isEmpty
            ? null
            : FloatingActionButton(
                onPressed: () => _openCreateGoal(context, ref),
                backgroundColor: colors.accent,
                foregroundColor: colors.accentOn,
                child: const Icon(Icons.add),
              ),
        orElse: () => null,
      ),
    );
  }

  /// "Today" is only correct for the actual current calendar date — every
  /// other [date] (reachable via Story 1.10's calendar navigation) must show
  /// its own date instead, or the title lies about which day is on screen.
  /// Uses `todayDateOnly()` (a one-shot read, per its own doc comment) since
  /// a stale title after a midnight rollover is an acceptable tradeoff for a
  /// screen the user navigated to by picking an explicit date.
  static String _titleFor(DateTime date) {
    if (formatDateOnly(date) == formatDateOnly(todayDateOnly())) {
      return 'Today';
    }
    return formatDisplayDate(date);
  }

  void _openCreateGoal(BuildContext context, WidgetRef ref) {
    // Story 2.1: `goalWizardProvider` is now `keepAlive` (so edit-mode
    // pre-fill survives the navigation to the wizard) — reset explicitly
    // on entry rather than relying on a previous session's exit path to
    // have cleaned up, since an abandoned create/edit attempt or an OS
    // back-gesture pop wouldn't otherwise clear stale state.
    ref.read(goalWizardProvider.notifier).reset();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const GoalCreationWizard()));
  }
}

/// First-run empty state (UX-DR26): no login/account step, straight to a
/// prompt to create the first Goal.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No goals yet',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Create your first one to start tracking.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s5),
            PrimaryButton(label: 'Create Goal', onPressed: onCreate),
          ],
        ),
      ),
    );
  }
}

/// Watches one goal's Versions/Logs and calls the domain's `evaluate()`
/// directly — this is the "evaluate() call site" Day View owns; no second
/// evaluation path exists anywhere in presentation (AD-4).
class _GoalRowForDate extends ConsumerWidget {
  const _GoalRowForDate({required this.goal, required this.date});

  final Goal goal;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionsAsync = ref.watch(goalVersionsProvider(goal.id));
    final logsAsync = ref.watch(goalLogsProvider(goal.id));
    final blackoutDatesAsync = ref.watch(blackoutDatesProvider(goal.id));
    final cheatDaysAsync = ref.watch(cheatDaysProvider(goal.id));

    final versions = versionsAsync.value;
    final logs = logsAsync.value;
    final blackoutDates = blackoutDatesAsync.value;
    final cheatDays = cheatDaysAsync.value;
    if (versions == null ||
        logs == null ||
        blackoutDates == null ||
        cheatDays == null) {
      return const SizedBox.shrink();
    }

    // Story 2.3 AC 2: Archived/Expired goals never appear on this
    // active-tracking surface at all (Goal Detail/the Goals list remain
    // their reachable historical home).
    final lifecycle = resolveLifecycleStatus(
      goal: goal,
      versions: versions,
      today: formatDateOnly(DateTime.now()),
    );
    if (lifecycle == GoalLifecycleStatus.archived ||
        lifecycle == GoalLifecycleStatus.expired) {
      return const SizedBox.shrink();
    }

    // Story 2.2 AC 2: a paused date never renders a goal-row for that goal
    // at all — never Empty, never Pending, never any of the five
    // status-cell colors — so `evaluate()` is never even called for this
    // specific (goal, date) pair.
    if (isPausedOn(versions, formatDateOnly(date))) {
      return const SizedBox.shrink();
    }

    // Bug 5: a date before the goal's own start date has no governing
    // Version, so evaluate() returns Empty with no targetValue — without
    // this guard the row still rendered with a fallback "0/0" instead of
    // being omitted like a paused date is.
    if (formatDateOnly(date).compareTo(goal.startDate) < 0) {
      return const SizedBox.shrink();
    }

    // Bug 7: a Daily-period goal's own weekday/recurrence rule excluding
    // `date` never renders a row for it, the same treatment as paused/
    // pre-start dates above — narrower than `DayStatus.status == empty`
    // (which blackout dates also produce and must stay visible; see
    // `isIneligibleDailyDayOn`'s doc comment). A blackout is a deliberate
    // per-date user action, so it always wins over the recurrence-rule
    // guard: a goal blacked out on a date its own rule already excludes
    // (e.g. a Workdays-only goal blacked out on a Saturday) must still
    // render, same as any other blackout.
    final isBlackedOutToday = blackoutDates.any(
      (blackoutDate) =>
          blackoutDate.goalId == goal.id &&
          blackoutDate.date == formatDateOnly(date),
    );
    if (!isBlackedOutToday &&
        isIneligibleDailyDayOn(versions, date, DateTime.parse(goal.startDate))) {
      return const SizedBox.shrink();
    }

    // The period-aggregate status still governs the DNF badge (its copy is
    // literally "pending period close") and remains the single evaluate()
    // call site AD-4 mandates for that question.
    final dayStatus = evaluate(
      goal: goal,
      versions: versions,
      logs: logs,
      blackoutDates: blackoutDates,
      cheatDays: cheatDays,
      date: date,
      today: todayDateOnly(),
    );
    // What's actually rendered in the row's status-cell: "did THIS date get
    // logged done," not "is the whole period on track" — a Weekly/Monthly
    // goal's period can still be short of its target while today's own
    // action was completed, and the row must show that immediately rather
    // than waiting for the period to resolve (see `evaluate.dart`'s
    // `evaluateDayOnly` doc comment).
    final dayOnlyStatus = evaluateDayOnly(
      goal: goal,
      versions: versions,
      logs: logs,
      blackoutDates: blackoutDates,
      cheatDays: cheatDays,
      date: date,
      today: todayDateOnly(),
    );
    final trackingType = versions.isNotEmpty
        ? versions.first.trackingType
        : TrackingType.boolean;
    final targetComparison = versions.isNotEmpty
        ? versions.first.targetComparison
        : null;

    // Story 2.5 Task 4.2: the DNF badge is gated strictly on the period's
    // own `DayStatus == pending` — once the period resolves, `evaluate()`
    // never read `dnfMarked` in the first place, so no explicit "clear the
    // flag" write is needed; the badge just stops rendering (Task 4.3).
    final dateStr = formatDateOnly(date);
    final logsForDate = logs.where((log) => log.date == dateStr);
    final logForDate = logsForDate.isEmpty ? null : logsForDate.last;
    final showDnfBadge =
        dayStatus.status == DayStatusValue.pending &&
        (logForDate?.dnfMarked ?? false);

    void openCheatBlackoutSheet() {
      showCheatBlackoutSheet(context: context, goal: goal, date: date);
    }

    if (trackingType == TrackingType.counter) {
      return GoalRow(
        name: goal.name,
        status: dayOnlyStatus.status,
        trackingType: trackingType,
        currentValue: dayOnlyStatus.currentValue,
        targetValue: dayOnlyStatus.targetValue,
        targetComparison: targetComparison,
        showDnfBadge: showDnfBadge,
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (_) => CounterStepperDialog(goal: goal, date: date),
          );
        },
        onLongPress: openCheatBlackoutSheet,
      );
    }

    // Bug 4: gate on whether *this date's own* log completed it, not on
    // the rendered status — now that the row renders `evaluateDayOnly()`
    // rather than the period aggregate, a rendered Success always
    // coincides with `ownLogCompleted` for Boolean goals (day-only Success
    // literally means this date's own log is completed), so this guard is
    // no longer reachable for Boolean, but stays in place unchanged as
    // defensive parity with the Counter branch above.
    final ownLogCompleted = logForDate?.completed ?? false;
    final periodResolvedElsewhere =
        dayOnlyStatus.status == DayStatusValue.success && !ownLogCompleted;

    return GoalRow(
      name: goal.name,
      status: dayOnlyStatus.status,
      trackingType: trackingType,
      showDnfBadge: showDnfBadge,
      onTap: periodResolvedElsewhere
          ? null
          : () {
              final goalService = ref.read(goalServiceProvider);
              if (ownLogCompleted) {
                goalService.undoBooleanLog(
                  goalId: goal.id,
                  logId: logForDate!.id,
                  date: formatDateOnly(date),
                );
              } else {
                goalService.logBoolean(
                  goalId: goal.id,
                  date: formatDateOnly(date),
                  completed: true,
                );
              }
            },
      onLongPress: openCheatBlackoutSheet,
    );
  }
}
