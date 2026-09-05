import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/day_status.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_lifecycle_status.dart';
import '../../domain/entities/rule_values.dart';
import '../../domain/evaluator/date_format.dart';
import '../../domain/evaluator/evaluate.dart';
import '../../domain/evaluator/period_boundary.dart';
import '../../domain/services/paused_range_helper.dart';
import '../components/cheat_blackout_sheet.dart';
import '../components/design_tokens.dart';
import '../components/goal_filter_bar.dart';
import '../components/status_cell.dart';
import '../providers/current_date_provider.dart';
import '../providers/goal_data_providers.dart';
import '../providers/week_start_provider.dart';
import 'day_view.dart';
import 'month_view.dart' show aggregateDayStatus, weekdayLabelsFor;

/// Week View (FR-22): a 7-day grid showing, for every active goal, its
/// per-day `status-cell` across the week plus a week-level overall progress
/// summary. Reachable from Month View via the app-bar action there.
///
/// Pageable to any week (not just the one containing [referenceDate]) via a
/// fixed-size `PageView.builder`, mirroring `MonthViewScreen`'s own
/// anchor-page paging pattern exactly (`month_view.dart`'s `_anchorPage`/
/// `_pageCount`/`_monthForPage`, here adapted to 7-day steps instead of
/// calendar months) — swiping never runs out of pages in either direction,
/// and a persistent "jump to this week" affordance is always reachable.
///
/// Per-cell status is computed via `evaluateDayOnly()` — "did this specific
/// day get logged," distinct from `evaluate()`'s period-aggregate "is the
/// goal on track" question a Weekly/Monthly-period goal would otherwise
/// show identically on every day of its period. `evaluateDayOnly()` itself
/// falls back to the real `evaluate()` for summed Counter goals, which have
/// no per-day target of their own — see `evaluate.dart`'s doc comment.
class WeekViewScreen extends ConsumerStatefulWidget {
  const WeekViewScreen({required this.referenceDate, super.key});

  /// Any date within the week to open on; the grid renders the whole
  /// Week-Start-anchored week containing it, then pages freely from there.
  final DateTime referenceDate;

  @override
  ConsumerState<WeekViewScreen> createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends ConsumerState<WeekViewScreen> {
  /// Halfway into a wide-but-finite page range (~23 years each direction at
  /// 7 days/page) so swiping in either direction never runs out of pages,
  /// matching `MonthViewScreen`'s own choice of range shape.
  static const _anchorPage = 1200;
  static const _pageCount = 2401;

  /// The Monday-or-Sunday (per Week-Start) start-of-week [_anchorPage]
  /// renders — established once from whatever week [referenceDate] fell in
  /// and whatever the Week-Start setting was at open time, exactly
  /// mirroring `MonthViewScreen._pageEpochMonth`'s "fixed epoch, never
  /// re-derived from a live setting" choice.
  late final DateTime _pageEpochWeekStart;

  /// The live local calendar date (mirrors `MonthViewScreen._today`):
  /// refreshed reactively from `currentDateProvider` so the jump-to-today
  /// target and any today-relative cell math stay correct across a
  /// midnight rollover, without shifting which week is currently on screen.
  late DateTime _today;
  late final PageController _controller;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    final refDate = DateTime(
      widget.referenceDate.year,
      widget.referenceDate.month,
      widget.referenceDate.day,
    );
    final weekStart = ref.read(weekStartSettingProvider);
    _pageEpochWeekStart = periodBoundaryFor(
      evaluationPeriod: EvaluationPeriod.weekly,
      date: refDate,
      goalStartDate: refDate,
      weekStart: weekStart,
    ).start;
    _currentPage = _anchorPage;
    _controller = PageController(initialPage: _anchorPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _weekStartForPage(int page) {
    return _pageEpochWeekStart.add(Duration(days: 7 * (page - _anchorPage)));
  }

  /// The page representing the week containing [_today] under the given
  /// (possibly since-changed) Week-Start setting.
  int _todayPage(WeekStart weekStart) {
    final todayWeekStart = periodBoundaryFor(
      evaluationPeriod: EvaluationPeriod.weekly,
      date: _today,
      goalStartDate: _today,
      weekStart: weekStart,
    ).start;
    final weeksFromEpoch =
        todayWeekStart.difference(_pageEpochWeekStart).inDays ~/ 7;
    return _anchorPage + weeksFromEpoch;
  }

  void _jumpToToday(WeekStart weekStart) {
    _controller.animateToPage(
      _todayPage(weekStart),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final weekStart = ref.watch(weekStartSettingProvider);
    final allGoalsAsync = ref.watch(allGoalsProvider);
    final filteredGoalsAsync = ref.watch(filteredGoalsProvider);

    // Mirrors MonthViewScreen: a silent refresh of "today" whenever the
    // local calendar date advances while this screen stays mounted, so
    // jump-to-today and any today-relative cell math recompute against the
    // new local day rather than staying pinned to launch-time "today."
    ref.listen<AsyncValue<DateTime>>(currentDateProvider, (previous, next) {
      next.whenData((date) {
        if (date != _today) {
          setState(() => _today = date);
        }
      });
    });

    final displayedWeekStart = _weekStartForPage(_currentPage);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: Text('Week of ${_shortDate(displayedWeekStart)}'),
        actions: [
          IconButton(
            tooltip: 'Jump to this week',
            icon: const Icon(Icons.today),
            onPressed: () => _jumpToToday(weekStart),
          ),
        ],
      ),
      body: Column(
        children: [
          const GoalFilterBar(),
          Expanded(
            child: allGoalsAsync.when(
              data: (allGoals) {
                if (allGoals.isEmpty) {
                  return Center(
                    child: Text(
                      'No goals yet',
                      style: TextStyle(color: colors.textSecondary),
                    ),
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
                return PageView.builder(
                  controller: _controller,
                  itemCount: _pageCount,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (context, page) {
                    final pageWeekStart = _weekStartForPage(page);
                    final days = List.generate(
                      7,
                      (i) => pageWeekStart.add(Duration(days: i)),
                    );
                    return _WeekBody(
                      goals: goals,
                      days: days,
                      weekStart: weekStart,
                      today: _today,
                    );
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
    );
  }
}

String _shortDate(DateTime date) =>
    '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';

/// Watches every goal's Versions/Logs/Blackout Dates once (Day View's
/// data-plumbing pattern, Story 1.1) and calls `evaluateDayOnly()` fresh per
/// goal per day of the week — each cell answers "did this exact day get
/// logged," not the whole period's aggregate status (Subtask 3.2's original
/// per-goal-row layout, unchanged; only the per-cell evaluation call
/// changed).
class _WeekBody extends ConsumerWidget {
  const _WeekBody({
    required this.goals,
    required this.days,
    required this.weekStart,
    required this.today,
  });

  final List<Goal> goals;
  final List<DateTime> days;
  final WeekStart weekStart;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    // Per goal, per day: the evaluateDayOnly() result for every cell in the
    // grid, computed once per build so both the per-goal rows and the week
    // rollup summary below read from the same values. A `null` entry means
    // that (goal, day) pair is paused (Story 2.2 AC 2): evaluation is never
    // run for it, and it renders no status-cell color at all — never
    // Empty, never Pending.
    final statusesByGoal = <String, List<DayStatusValue?>>{};
    for (final goal in goals) {
      final versions = ref.watch(goalVersionsProvider(goal.id)).value;
      final logs = ref.watch(goalLogsProvider(goal.id)).value;
      final blackoutDates = ref.watch(blackoutDatesProvider(goal.id)).value;
      final cheatDays = ref.watch(cheatDaysProvider(goal.id)).value;
      if (versions == null ||
          logs == null ||
          blackoutDates == null ||
          cheatDays == null) {
        continue;
      }
      // Story 2.3 AC 2: an Archived/Expired goal never appears on this
      // active-tracking surface — its row is omitted for the whole week,
      // same as the loading-data skip above (`_WeekGoalRow` already
      // no-ops on a missing `statusesByGoal` entry).
      final lifecycle = resolveLifecycleStatus(
        goal: goal,
        versions: versions,
        today: formatDateOnly(DateTime.now()),
      );
      if (lifecycle == GoalLifecycleStatus.archived ||
          lifecycle == GoalLifecycleStatus.expired) {
        continue;
      }
      statusesByGoal[goal.id] = [
        for (final day in days)
          // Bug 5: a day before the goal's own startDate renders no
          // status-cell color at all, same treatment as a paused day.
          (isPausedOn(versions, formatDateOnly(day)) ||
                  formatDateOnly(day).compareTo(goal.startDate) < 0)
              ? null
              : evaluateDayOnly(
                  goal: goal,
                  versions: versions,
                  logs: logs,
                  blackoutDates: blackoutDates,
                  cheatDays: cheatDays,
                  date: day,
                  today: today,
                ).status,
      ];
    }

    final successDays = days.indexed.where((entry) {
      final (index, _) = entry;
      final statusesThatDay = <DayStatusValue>[
        for (final goal in goals) ?statusesByGoal[goal.id]?[index],
      ];
      return aggregateDayStatus(statusesThatDay) == DayStatusValue.success;
    }).length;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        _WeekHeaderRow(days: days, weekStart: weekStart),
        const SizedBox(height: AppSpacing.s3),
        for (final goal in goals) ...[
          _WeekGoalRow(
            goal: goal,
            days: days,
            statuses: statusesByGoal[goal.id],
          ),
          const SizedBox(height: AppSpacing.s3),
        ],
        const Divider(),
        const SizedBox(height: AppSpacing.s2),
        Text(
          'Week progress: $successDays/7 days on track',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _WeekHeaderRow extends StatelessWidget {
  const _WeekHeaderRow({required this.days, required this.weekStart});

  final List<DateTime> days;
  final WeekStart weekStart;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final labels = weekdayLabelsFor(weekStart);
    return Row(
      children: [
        const SizedBox(width: 96),
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Column(
              children: [
                Text(
                  labels[i],
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${days[i].day}',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One goal's row: name label, then a `status-cell` per day of the week
/// (FR-22's "each Goal's per-day status", Subtask 3.2). Tapping a cell opens
/// Day View for that date (FR-21); long-press opens the Cheat Day/Blackout
/// sheet for this goal on that date (AC #5) — unambiguous here since each
/// row is already scoped to one goal, unlike Month View's aggregated cell.
class _WeekGoalRow extends StatelessWidget {
  const _WeekGoalRow({
    required this.goal,
    required this.days,
    required this.statuses,
  });

  final Goal goal;
  final List<DateTime> days;

  /// `null` (the outer list) while this goal's reactive data hasn't loaded
  /// yet; a `null` entry within the list means that day is paused (Story
  /// 2.2 AC 2) and renders no status-cell color.
  final List<DayStatusValue?>? statuses;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (statuses == null) return const SizedBox.shrink();

    return Column(
      key: Key('week-goal-row-${goal.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          goal.name,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s1),
        Row(
          children: [
            const SizedBox(width: 96),
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DayViewScreen(date: days[i]),
                      ),
                    ),
                    onLongPress: () => showCheatBlackoutSheet(
                      context: context,
                      goal: goal,
                      date: days[i],
                    ),
                    // Story 2.2 AC 2: a paused day (null entry) renders no
                    // status-cell color at all, never Empty, never Pending.
                    child: statuses![i] == null
                        ? const SizedBox(width: 32, height: 32)
                        : StatusCell(status: statuses![i]!),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
