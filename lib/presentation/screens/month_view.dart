import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/blackout_date.dart';
import '../../domain/entities/cheat_day.dart';
import '../../domain/entities/day_status.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_lifecycle_status.dart';
import '../../domain/entities/goal_log.dart';
import '../../domain/entities/goal_version.dart';
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
import 'goals/goals_list_screen.dart';
import 'month_weeks_view.dart';
import 'week_view.dart';

/// Month View (FR-23): the app's default landing surface (AC #2). Renders
/// a full month grid, one `status-cell` per day, honoring the Week-Start
/// setting for its weekday-column layout (FR-24), with horizontal swipe to
/// adjacent months and a persistent "jump to today" affordance (AC #3,
/// UX-DR23).
///
/// Per-cell status is computed by calling the domain's `evaluate()` fresh
/// for every goal/day pair on every build — no caching, ad hoc or
/// otherwise (AD-7's "live calendar always calls evaluate() fresh"
/// principle, which this story establishes even though the read-optimized
/// cache itself doesn't exist until Epic 3).
class MonthViewScreen extends ConsumerStatefulWidget {
  const MonthViewScreen({this.initialMonth, super.key});

  /// The month to open on (Story 5.3 AC2/AC4: widget tap-through's
  /// `trackerapp://month?date=...` deep link). `null` (every pre-5.3 call
  /// site) preserves the original behavior of always opening on the
  /// current month.
  final DateTime? initialMonth;

  @override
  ConsumerState<MonthViewScreen> createState() => _MonthViewScreenState();
}

class _MonthViewScreenState extends ConsumerState<MonthViewScreen> {
  /// Halfway into a wide-but-finite page range (~100 years each direction)
  /// so swiping in either direction never runs out of pages, without the
  /// added complexity of a truly unbounded `PageView.builder`.
  static const _anchorPage = 1200;
  static const _pageCount = 2401;

  /// The month [_anchorPage] renders — established once, forever, from
  /// whatever "today" was at first launch. This is deliberately *not*
  /// re-derived from a live "today" on a midnight rollover: doing so would
  /// shift every already-visible page's month out from under a user who
  /// has swiped away from today (Story 1.11 Task 2). Instead, [_today]
  /// below is the only value that's ever refreshed, and callers that need
  /// "today's page" (e.g. [_jumpToToday]) compute its offset from this
  /// fixed epoch on demand.
  late final DateTime _pageEpochMonth;

  /// The live local calendar date (Story 1.11 Task 2). Unlike the old
  /// `late final` capture-once-in-initState field this replaces, this is
  /// refreshed reactively from [currentDateProvider] whenever the device's
  /// date changes while the app stays open — otherwise "jump to today"
  /// would jump to yesterday and the isToday ring would highlight the
  /// wrong day after a midnight rollover.
  late DateTime _today;
  late final PageController _controller;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    final epochTarget = widget.initialMonth ?? now;
    _pageEpochMonth = DateTime(epochTarget.year, epochTarget.month, 1);
    _currentPage = _anchorPage;
    _controller = PageController(initialPage: _anchorPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) {
    final offset = page - _anchorPage;
    return DateTime(_pageEpochMonth.year, _pageEpochMonth.month + offset, 1);
  }

  /// The page currently representing "today's month" — equal to
  /// [_anchorPage] only while [_today] hasn't crossed a month boundary
  /// since launch; a midnight rollover that also rolls the month (e.g.
  /// Aug 31 -> Sep 1) shifts this by exactly one page, computed fresh from
  /// [_today] rather than assumed fixed.
  int get _todayPage {
    final todayMonth = DateTime(_today.year, _today.month, 1);
    final monthsFromEpoch =
        (todayMonth.year - _pageEpochMonth.year) * 12 +
        (todayMonth.month - _pageEpochMonth.month);
    return _anchorPage + monthsFromEpoch;
  }

  void _jumpToToday() {
    _controller.animateToPage(
      _todayPage,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _openGoalsList() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const GoalsListScreen()));
  }

  void _openWeekView() {
    final displayedMonth = _monthForPage(_currentPage);
    final referenceDate =
        displayedMonth.year == _today.year &&
            displayedMonth.month == _today.month
        ? _today
        : DateTime(displayedMonth.year, displayedMonth.month, 1);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeekViewScreen(referenceDate: referenceDate),
      ),
    );
  }

  void _openMonthWeeksView() {
    final displayedMonth = _monthForPage(_currentPage);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MonthWeeksViewScreen(initialMonth: displayedMonth),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final displayedMonth = _monthForPage(_currentPage);

    // Story 1.11 Task 2: a silent full reload — no interstitial/toast
    // (UX-DR21) — of "today" whenever the local calendar date advances
    // while this screen stays mounted, so the isToday ring and
    // jump-to-today target recompute against the new local day rather
    // than staying pinned to whatever "today" was at first launch.
    ref.listen<AsyncValue<DateTime>>(currentDateProvider, (previous, next) {
      next.whenData((date) {
        if (date != _today) {
          setState(() => _today = date);
        }
      });
    });

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: Text(_monthLabel(displayedMonth)),
        actions: [
          // Story 2.1 Task 4.2: goal rows are reachable outside Day View so
          // Epic 2's Edit/Pause/Archive actions have a UI home — no
          // persistent tab bar exists yet (EXPERIENCE.md's eventual Today/
          // Calendar/Goals/Settings bar is a later, larger piece of work),
          // so a single app-bar entry point is the documented interim
          // choice.
          IconButton(
            tooltip: 'Goals',
            icon: const Icon(Icons.flag_outlined),
            onPressed: _openGoalsList,
          ),
          IconButton(
            tooltip: 'Week View',
            icon: const Icon(Icons.view_week),
            onPressed: _openWeekView,
          ),
          IconButton(
            tooltip: 'Weeks this month',
            icon: const Icon(Icons.table_rows_outlined),
            onPressed: _openMonthWeeksView,
          ),
          // AC #3: a persistent "jump to today" affordance, reachable
          // regardless of how many months have been swiped away.
          IconButton(
            tooltip: 'Jump to today',
            icon: const Icon(Icons.today),
            onPressed: _jumpToToday,
          ),
        ],
      ),
      body: Column(
        children: [
          const GoalFilterBar(),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pageCount,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, page) {
                return _MonthGrid(month: _monthForPage(page), today: _today);
              },
            ),
          ),
        ],
      ),
    );
  }
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _monthLabel(DateTime month) =>
    '${_monthNames[month.month - 1]} ${month.year}';

/// The Month View's multi-goal, no-filter aggregation rule (Story 1.10
/// Task 3.1). epics.md/FR-23 describes a single Derived Status per day but
/// doesn't specify how to combine multiple goals into one; full goal
/// filtering (all/single/category) isn't built until Epic 3 Story 3.5, so
/// until then Month View defaults to "all goals" and needs a defined
/// combination rule for one day's cell.
///
/// Chosen rule: **worst-status-wins**, in precedence order
/// Fail > Pending > Cheat > Success > Empty. A Fail anywhere is the most
/// actionable signal and must never be hidden behind an unrelated goal's
/// Success; Empty only wins when every goal is non-eligible/non-existent
/// that day. This is a documented default, not a directive from any source
/// document (see the story's Dev Notes) — subject to being superseded once
/// Story 3.5 adds real filtering.
DayStatusValue aggregateDayStatus(Iterable<DayStatusValue> statuses) {
  const precedence = [
    DayStatusValue.fail,
    DayStatusValue.pending,
    DayStatusValue.cheat,
    DayStatusValue.success,
    DayStatusValue.empty,
  ];
  final present = statuses.toSet();
  for (final candidate in precedence) {
    if (present.contains(candidate)) return candidate;
  }
  return DayStatusValue.empty;
}

/// One month's page: watches every goal's Versions/Logs/Blackout Dates once
/// (Day View's data-plumbing pattern, Story 1.1) and calls `evaluate()`
/// fresh per goal per grid day (AD-4 — the only evaluation call site;
/// AD-7 — never cached).
class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({required this.month, required this.today});

  final DateTime month;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(weekStartSettingProvider);
    final goalsAsync = ref.watch(filteredGoalsProvider);

    return goalsAsync.when(
      data: (goals) => _buildGrid(context, ref, goals, weekStart),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Something went wrong: $error')),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    List<Goal> goals,
    WeekStart weekStart,
  ) {
    final colors = AppColors.of(context);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    // Both ends of the padded grid reuse the exact same
    // `periodBoundaryFor` the evaluator's own Weekly-period math calls
    // (Subtask 2.3) — the grid's first/last column can never disagree with
    // what evaluate() considers a week's boundary for the same Week-Start
    // value, because it is literally the same function call, not a
    // reimplementation of its logic (AD-4).
    final gridStart = periodBoundaryFor(
      evaluationPeriod: EvaluationPeriod.weekly,
      date: month,
      goalStartDate: month,
      weekStart: weekStart,
    ).start;
    final gridEnd = periodBoundaryFor(
      evaluationPeriod: EvaluationPeriod.weekly,
      date: lastDayOfMonth,
      goalStartDate: lastDayOfMonth,
      weekStart: weekStart,
    ).end;
    final totalDays = gridEnd.difference(gridStart).inDays + 1;
    final days = List.generate(
      totalDays,
      (i) => gridStart.add(Duration(days: i)),
    );

    // Preload each goal's reactive data once per build, rather than inside
    // the per-cell itemBuilder, so evaluate() has everything it needs
    // synchronously for every day/goal pair below.
    final today = formatDateOnly(DateTime.now());
    final goalData = <String, _GoalEvalData>{};
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
      // active-tracking surface — excluded from `goalData` altogether, so
      // it drops out of both the day-cell aggregation and the long-press
      // goal picker below (both already key off `goalData`/`visibleGoals`).
      final lifecycle = resolveLifecycleStatus(
        goal: goal,
        versions: versions,
        today: today,
      );
      if (lifecycle == GoalLifecycleStatus.archived ||
          lifecycle == GoalLifecycleStatus.expired) {
        continue;
      }
      goalData[goal.id] = _GoalEvalData(
        versions: versions,
        logs: logs,
        blackoutDates: blackoutDates,
        cheatDays: cheatDays,
      );
    }
    final visibleGoals = [
      for (final goal in goals)
        if (goalData.containsKey(goal.id)) goal,
    ];

    // A plain-old Column of Rows (7 cells each), not a GridView.builder:
    // a month grid never exceeds 6 rows, so there is no lazy-loading
    // benefit, and building every cell eagerly means every date's
    // status-cell genuinely exists in the tree at all times — never
    // scroll-viewport-dependent (important for widget tests asserting the
    // full grid, and for AD-7: every cell's evaluate() call runs on every
    // build regardless of whether it happened to be scrolled into view).
    final rows = <Widget>[];
    for (var rowStart = 0; rowStart < days.length; rowStart += 7) {
      rows.add(
        Expanded(
          child: Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _dayCell(
                    context,
                    visibleGoals,
                    goalData,
                    weekStart,
                    colors,
                    days[rowStart + col],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _WeekdayHeaderRow(weekStart: weekStart),
        const Divider(height: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s2),
            child: Column(children: rows),
          ),
        ),
      ],
    );
  }

  /// One grid cell: aggregates every goal's `evaluate()` result for [date]
  /// via [aggregateDayStatus] (Task 3.1) and wires up tap (Day View, FR-21)
  /// and long-press (Cheat/Blackout sheet, AC #5).
  Widget _dayCell(
    BuildContext context,
    List<Goal> goals,
    Map<String, _GoalEvalData> goalData,
    WeekStart weekStart,
    AppColors colors,
    DateTime date,
  ) {
    final dateStr = formatDateOnly(date);
    // Story 2.2 AC 2: a paused (goal, date) pair never calls `evaluate()`
    // and never contributes to the aggregate — the same rule Day/Week View
    // apply, just expressed as "excluded from the aggregation pool" here
    // since Month View renders one combined cell per day, not a per-goal
    // row.
    final statuses = <DayStatusValue>[
      for (final goal in goals)
        if (goalData[goal.id] case final data?)
          // Bug 5: a date before the goal's own startDate is excluded from
          // the aggregate, same treatment as a paused (goal, date) pair.
          if (!isPausedOn(data.versions, dateStr) &&
              dateStr.compareTo(goal.startDate) >= 0)
            evaluate(
              goal: goal,
              versions: data.versions,
              logs: data.logs,
              blackoutDates: data.blackoutDates,
              cheatDays: data.cheatDays,
              date: date,
              today: today,
              weekStart: weekStart,
            ).status,
    ];
    final status = aggregateDayStatus(statuses);
    final inCurrentMonth = date.month == month.month && date.year == month.year;
    final isToday = date == today;

    return _MonthDayCell(
      date: date,
      status: status,
      inCurrentMonth: inCurrentMonth,
      isToday: isToday,
      colors: colors,
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => DayViewScreen(date: date))),
      onLongPress: goals.isEmpty
          ? null
          : () => _handleLongPress(context, goals, date),
    );
  }

  /// Long-press is reserved for the Cheat Day/Blackout sheet (AC #5). Month
  /// View's day cell is an aggregate across every goal (Task 3.1), so
  /// unlike Week View's unambiguous per-goal row, a multi-goal day needs a
  /// goal picked first; a single-goal day skips the picker and opens the
  /// sheet directly, matching Day View/Week View's one-tap-to-sheet feel.
  Future<void> _handleLongPress(
    BuildContext context,
    List<Goal> goals,
    DateTime date,
  ) async {
    if (goals.length == 1) {
      await showCheatBlackoutSheet(
        context: context,
        goal: goals.single,
        date: date,
      );
      return;
    }

    final selectedGoal = await showModalBottomSheet<Goal>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final goal in goals)
              ListTile(
                title: Text(goal.name),
                onTap: () => Navigator.of(context).pop(goal),
              ),
          ],
        ),
      ),
    );
    if (selectedGoal != null && context.mounted) {
      await showCheatBlackoutSheet(
        context: context,
        goal: selectedGoal,
        date: date,
      );
    }
  }
}

class _GoalEvalData {
  const _GoalEvalData({
    required this.versions,
    required this.logs,
    required this.blackoutDates,
    required this.cheatDays,
  });

  final List<GoalVersion> versions;
  final List<GoalLog> logs;
  final List<BlackoutDate> blackoutDates;
  final List<CheatDay> cheatDays;
}

/// Weekday-abbreviation header, ordered to match the Week-Start setting
/// (FR-24, Subtask 2.3) — reused by Week View's own header via the same
/// ordering rule (each screen keeps its own tiny copy per this story's
/// "only two new files" scope; the logic is a few lines, not a component).
class _WeekdayHeaderRow extends StatelessWidget {
  const _WeekdayHeaderRow({required this.weekStart});

  final WeekStart weekStart;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final labels = weekdayLabelsFor(weekStart);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: AppSpacing.s2,
      ),
      child: Row(
        children: [
          for (final label in labels)
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The 7 weekday abbreviations in Week-Start order (Monday-first or
/// Sunday-first, FR-24) — shared ordering rule for both Week View and Month
/// View's headers so they can never disagree about column order.
List<String> weekdayLabelsFor(WeekStart weekStart) {
  const mondayFirst = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const sundayFirst = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  return weekStart == WeekStart.monday ? mondayFirst : sundayFirst;
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.date,
    required this.status,
    required this.inCurrentMonth,
    required this.isToday,
    required this.colors,
    required this.onTap,
    required this.onLongPress,
  });

  final DateTime date;
  final DayStatusValue status;
  final bool inCurrentMonth;
  final bool isToday;
  final AppColors colors;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: isToday
            ? BoxDecoration(
                border: Border.all(color: colors.accent, width: 1.5),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: inCurrentMonth ? colors.textPrimary : colors.textMuted,
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            StatusCell(status: status, size: 24),
          ],
        ),
      ),
    );
  }
}
