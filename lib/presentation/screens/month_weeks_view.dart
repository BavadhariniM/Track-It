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
import '../components/design_tokens.dart';
import '../components/goal_filter_bar.dart';
import '../components/status_cell.dart';
import '../providers/current_date_provider.dart';
import '../providers/goal_data_providers.dart';
import '../providers/week_start_provider.dart';

/// A month-level rollup: which weeks were a full success, per goal,
/// uniformly across Daily/Weekly/Monthly(-or-longer) goals — distinct from
/// `MonthViewScreen`'s single aggregated cell per calendar day. Pageable to
/// any month via the same fixed-size `PageView.builder` anchor-page pattern
/// `MonthViewScreen` already uses.
///
/// One row per filtered goal, one `StatusCell` per week the displayed month
/// spans. Per goal, the cell rule depends on that goal's own governing
/// `evaluationPeriod` (never a single uniform rule, since Daily/Weekly/
/// Monthly goals resolve at genuinely different granularities):
/// - Daily: a week cell is Success only if every one of that goal's own
///   eligible, non-paused, post-start days that week (via
///   `evaluateDayOnly()`) individually succeeded; any such day that's
///   certainly failed makes the whole week cell Fail; otherwise Pending
///   while some day is still open.
/// - Weekly: a single `evaluate()` call for that week IS the week's status,
///   as-is — no reinterpretation needed, it already resolves per week.
/// - Monthly or longer (Biweekly/Quarterly/Yearly/Rolling Window/Custom):
///   a single `evaluate()` call for the whole month, and that SAME result
///   is repeated across every week-column for that goal, since none of
///   these period types resolve at week granularity — this repetition is
///   intended, not a bug.
class MonthWeeksViewScreen extends ConsumerStatefulWidget {
  const MonthWeeksViewScreen({this.initialMonth, super.key});

  final DateTime? initialMonth;

  @override
  ConsumerState<MonthWeeksViewScreen> createState() =>
      _MonthWeeksViewScreenState();
}

class _MonthWeeksViewScreenState extends ConsumerState<MonthWeeksViewScreen> {
  static const _anchorPage = 1200;
  static const _pageCount = 2401;

  late final DateTime _pageEpochMonth;
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final displayedMonth = _monthForPage(_currentPage);

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
        title: Text('${_monthLabel(displayedMonth)} — weeks'),
        actions: [
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
                return _MonthWeeksGrid(month: _monthForPage(page), today: _today);
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

class _MonthWeeksGrid extends ConsumerWidget {
  const _MonthWeeksGrid({required this.month, required this.today});

  final DateTime month;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(weekStartSettingProvider);
    final goalsAsync = ref.watch(filteredGoalsProvider);

    return goalsAsync.when(
      data: (goals) => _buildBody(context, ref, goals, weekStart),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Something went wrong: $error')),
    );
  }

  /// This month's constituent weeks, as their Week-Start-anchored start
  /// dates — reuses the exact same `periodBoundaryFor` primitive Week View
  /// and Month View's own day-grid padding already call, so a week here can
  /// never disagree with what `evaluate()` considers a week's boundary.
  List<DateTime> _weekStartsFor(WeekStart weekStart) {
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final firstWeekStart = periodBoundaryFor(
      evaluationPeriod: EvaluationPeriod.weekly,
      date: month,
      goalStartDate: month,
      weekStart: weekStart,
    ).start;
    final lastWeekEnd = periodBoundaryFor(
      evaluationPeriod: EvaluationPeriod.weekly,
      date: monthEnd,
      goalStartDate: monthEnd,
      weekStart: weekStart,
    ).end;
    final totalDays = lastWeekEnd.difference(firstWeekStart).inDays + 1;
    final weekCount = totalDays ~/ 7;
    return List.generate(
      weekCount,
      (i) => firstWeekStart.add(Duration(days: 7 * i)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<Goal> goals,
    WeekStart weekStart,
  ) {
    final colors = AppColors.of(context);
    if (goals.isEmpty) {
      return Center(
        child: Text(
          'No goals match this filter',
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }

    final weekStarts = _weekStartsFor(weekStart);

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
      final lifecycle = resolveLifecycleStatus(
        goal: goal,
        versions: versions,
        today: formatDateOnly(DateTime.now()),
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

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        _WeeksHeaderRow(weekStarts: weekStarts),
        const SizedBox(height: AppSpacing.s3),
        for (final goal in visibleGoals) ...[
          _GoalWeeksRow(
            goal: goal,
            weekStarts: weekStarts,
            statuses: _weekStatusesFor(
              goal: goal,
              data: goalData[goal.id]!,
              weekStarts: weekStarts,
              weekStart: weekStart,
              displayedMonth: month,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
        ],
      ],
    );
  }

  /// One [DayStatusValue]-or-`null` per week-column for [goal], per the
  /// per-period-type rule documented on this file's class doc comment.
  /// `null` means "this whole week has no countable data for this goal"
  /// (fully paused or entirely before the goal's own start date) — rendered
  /// as a blank cell, the same convention Day/Week/Month View already use
  /// for a paused/pre-start date.
  List<DayStatusValue?> _weekStatusesFor({
    required Goal goal,
    required _GoalEvalData data,
    required List<DateTime> weekStarts,
    required WeekStart weekStart,
    required DateTime displayedMonth,
  }) {
    final goalStartDate = DateTime.parse(goal.startDate);

    return [
      for (final ws in weekStarts)
        _weekStatusFor(
          goal: goal,
          data: data,
          weekStartDate: ws,
          goalStartDate: goalStartDate,
          weekStart: weekStart,
          displayedMonth: displayedMonth,
        ),
    ];
  }

  DayStatusValue? _weekStatusFor({
    required Goal goal,
    required _GoalEvalData data,
    required DateTime weekStartDate,
    required DateTime goalStartDate,
    required WeekStart weekStart,
    required DateTime displayedMonth,
  }) {
    final weekStartStr = formatDateOnly(weekStartDate);
    final governing = _governingVersion(data.versions, weekStartStr);
    if (governing == null) return null;

    if (governing.evaluationPeriod == EvaluationPeriod.daily) {
      final days = List.generate(
        7,
        (i) => weekStartDate.add(Duration(days: i)),
      );
      final countable = <DayStatusValue>[];
      for (final day in days) {
        final dayStr = formatDateOnly(day);
        if (isPausedOn(data.versions, dayStr) ||
            dayStr.compareTo(goal.startDate) < 0) {
          continue;
        }
        final status = evaluateDayOnly(
          goal: goal,
          versions: data.versions,
          logs: data.logs,
          blackoutDates: data.blackoutDates,
          cheatDays: data.cheatDays,
          date: day,
          today: today,
        ).status;
        if (status == DayStatusValue.empty) continue;
        countable.add(status);
      }
      if (countable.isEmpty) return null;
      if (countable.contains(DayStatusValue.fail)) return DayStatusValue.fail;
      if (countable.contains(DayStatusValue.pending)) {
        return DayStatusValue.pending;
      }
      return DayStatusValue.success;
    }

    // Weekly resolves per-week as-is, queried at this specific week's own
    // start date (correct regardless of which calendar month that week
    // visually spills into). Monthly-or-longer must instead be queried with
    // a date guaranteed to fall inside the DISPLAYED month — never a
    // boundary week's own start date, which can spill into the adjacent
    // month and would otherwise resolve the wrong month's period entirely
    // — so its single result is deliberately repeated across every
    // week-column for this goal (see class doc comment) via one shared
    // query date.
    final queryDate = governing.evaluationPeriod == EvaluationPeriod.weekly
        ? weekStartDate
        : displayedMonth;
    return evaluate(
      goal: goal,
      versions: data.versions,
      logs: data.logs,
      blackoutDates: data.blackoutDates,
      cheatDays: data.cheatDays,
      date: queryDate,
      today: today,
      weekStart: weekStart,
    ).status;
  }

  GoalVersion? _governingVersion(List<GoalVersion> versions, String dateStr) {
    GoalVersion? governing;
    final sorted = [...versions]
      ..sort((a, b) => a.versionStartDate.compareTo(b.versionStartDate));
    for (final version in sorted) {
      if (version.versionStartDate.compareTo(dateStr) <= 0) {
        governing = version;
      } else {
        break;
      }
    }
    return governing;
  }
}

class _WeeksHeaderRow extends StatelessWidget {
  const _WeeksHeaderRow({required this.weekStarts});

  final List<DateTime> weekStarts;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        const SizedBox(width: 96),
        for (final weekStart in weekStarts)
          Expanded(
            child: Center(
              child: Text(
                '${weekStart.month}/${weekStart.day}',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GoalWeeksRow extends StatelessWidget {
  const _GoalWeeksRow({
    required this.goal,
    required this.weekStarts,
    required this.statuses,
  });

  final Goal goal;
  final List<DateTime> weekStarts;
  final List<DayStatusValue?> statuses;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      key: Key('month-weeks-goal-row-${goal.id}'),
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
            for (var i = 0; i < weekStarts.length; i++)
              Expanded(
                child: Center(
                  child: statuses[i] == null
                      ? const SizedBox(width: 32, height: 32)
                      : StatusCell(status: statuses[i]!),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
