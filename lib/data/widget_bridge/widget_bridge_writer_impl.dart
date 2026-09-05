import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../../domain/entities/day_status.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_lifecycle_status.dart';
import '../../domain/entities/goal_version.dart';
import '../../domain/entities/rule_values.dart';
import '../../domain/evaluator/date_format.dart';
import '../../domain/evaluator/period_boundary.dart';
import '../../domain/services/goal_repository.dart';
import '../../domain/services/goal_version_repository.dart';
import '../../domain/services/paused_range_helper.dart';
import '../../domain/services/status_cache_repository.dart';
import '../../domain/services/widget_bridge_writer.dart';

/// The single [WidgetBridgeWriter] implementation (Story 5.1): a pure
/// serializer from [StatusCacheRepository] rows to the three `home_widget`
/// shared-container keys this story's Dev Notes fix as the binding contract
/// for Story 5.2/5.3. Never calls `evaluate()` and never reads
/// `GoalLog`/`GoalVersion` rows for a *status* value — the one non-cache read
/// is [GoalRepository]/[GoalVersionRepository] metadata (name, archived
/// flag, pause state), needed because `DayStatus` carries neither a display
/// name nor lifecycle/pause information.
class WidgetBridgeWriterImpl implements WidgetBridgeWriter {
  WidgetBridgeWriterImpl({
    required GoalRepository goalRepository,
    required GoalVersionRepository goalVersionRepository,
    required StatusCacheRepository statusCacheRepository,
    WeekStart weekStart = WeekStart.monday,
    String? appGroupId,
  }) : _goalRepository = goalRepository,
       _goalVersionRepository = goalVersionRepository,
       _statusCacheRepository = statusCacheRepository,
       _weekStart = weekStart,
       _appGroupId = appGroupId;

  final GoalRepository _goalRepository;
  final GoalVersionRepository _goalVersionRepository;
  final StatusCacheRepository _statusCacheRepository;
  final WeekStart _weekStart;
  final String? _appGroupId;

  static const todayWidgetDataKey = 'today_widget_data';
  static const weekWidgetDataKey = 'week_widget_data';
  static const monthWidgetDataKey = 'month_widget_data';

  /// Provider names registered by Story 5.2's native widgets: the Android
  /// names are the `GlanceAppWidgetReceiver` class names registered as
  /// `<receiver>` components in `AndroidManifest.xml`
  /// (`lib/platform/android/*Receiver.kt`); the iOS names are the
  /// `kind` strings each `Widget` declares in its `WidgetConfiguration`
  /// (`lib/platform/ios/*.swift`).
  static const _androidWidgetNames = {
    'today': 'TodayWidgetReceiver',
    'week': 'WeekWidgetReceiver',
    'month': 'MonthWidgetReceiver',
  };
  static const _iOSWidgetNames = {
    'today': 'TodayWidget',
    'week': 'WeekWidget',
    'month': 'MonthWidget',
  };

  @override
  Future<void> writeAll(DateTime today) async {
    final todayOnly = DateTime(today.year, today.month, today.day);
    final todayStr = formatDateOnly(todayOnly);

    final eligibleGoals = <_EligibleGoal>[];
    for (final goal in await _goalRepository.watchAllGoals().first) {
      if (goal.archived) continue;
      final versions = await _goalVersionRepository.findAllForGoal(goal.id);
      final lifecycle = resolveLifecycleStatus(
        goal: goal,
        versions: versions,
        today: todayStr,
      );
      // Story 2.3/Week/Month View precedent: an Archived/Expired goal never
      // appears on an active-tracking surface. Paused goals remain in the
      // pool — their individual paused dates are excluded per-cell below,
      // mirroring Week/Month View's own per-day pause check.
      if (lifecycle == GoalLifecycleStatus.archived ||
          lifecycle == GoalLifecycleStatus.expired) {
        continue;
      }
      eligibleGoals.add(_EligibleGoal(goal: goal, versions: versions));
    }

    await _writeScope(
      key: todayWidgetDataKey,
      scope: 'today',
      generatedAt: todayOnly,
      rangeStart: todayOnly,
      rangeEnd: todayOnly,
      dates: [todayOnly],
      goals: eligibleGoals,
      // AC 1/Dev Notes: "today" cells are goals *eligible today* — mirrors
      // StatsService.todayProgress's own "status != empty" filter.
      excludeEmptyStatus: true,
    );

    final weekBoundary = periodBoundaryFor(
      evaluationPeriod: EvaluationPeriod.weekly,
      date: todayOnly,
      goalStartDate: todayOnly,
      weekStart: _weekStart,
    );
    await _writeScope(
      key: weekWidgetDataKey,
      scope: 'week',
      generatedAt: todayOnly,
      rangeStart: weekBoundary.start,
      rangeEnd: weekBoundary.end,
      dates: _datesInRange(weekBoundary.start, weekBoundary.end),
      goals: eligibleGoals,
      // Dev Notes: mirrors in-app Week View, which renders a status-cell
      // for every non-paused day regardless of status (including Empty) —
      // not filtered down to "eligible" the way the Today scope is.
      excludeEmptyStatus: false,
    );

    final monthBoundary = periodBoundaryFor(
      evaluationPeriod: EvaluationPeriod.monthly,
      date: todayOnly,
      goalStartDate: todayOnly,
    );
    await _writeScope(
      key: monthWidgetDataKey,
      scope: 'month',
      generatedAt: todayOnly,
      rangeStart: monthBoundary.start,
      rangeEnd: monthBoundary.end,
      dates: _datesInRange(monthBoundary.start, monthBoundary.end),
      goals: eligibleGoals,
      excludeEmptyStatus: false,
    );
  }

  Future<void> _writeScope({
    required String key,
    required String scope,
    required DateTime generatedAt,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required List<DateTime> dates,
    required List<_EligibleGoal> goals,
    required bool excludeEmptyStatus,
  }) async {
    final cells = <Map<String, Object?>>[];
    for (final date in dates) {
      final dateStr = formatDateOnly(date);
      for (final entry in goals) {
        // Week/Month View precedent (paused_range_helper.dart): a paused
        // (goal, date) pair is omitted entirely, never rendered as any
        // status — cosmetic exclusion, not a cache read.
        if (isPausedOn(entry.versions, dateStr)) continue;

        // Bug 5: a (goal, date) pair before the goal's own startDate is
        // omitted entirely, same treatment as a paused pair — the cache
        // would otherwise carry an Empty-status cell for it.
        if (dateStr.compareTo(entry.goal.startDate) < 0) continue;

        // Cache-only rule (AC 5): a cache miss is skipped rather than
        // falling back to a live evaluate() call — this bridge only ever
        // serializes what CacheWriter already computed and persisted.
        final status = await _statusCacheRepository.getStatus(
          entry.goal.id,
          dateStr,
        );
        if (status == null) continue;
        if (excludeEmptyStatus && status.status == DayStatusValue.empty) {
          continue;
        }

        cells.add({
          'date': dateStr,
          'goalId': entry.goal.id,
          'goalName': entry.goal.name,
          'status': _statusString(status.status),
        });
      }
    }

    final envelope = {
      'scope': scope,
      'generatedAt': formatDateOnly(generatedAt),
      'rangeStart': formatDateOnly(rangeStart),
      'rangeEnd': formatDateOnly(rangeEnd),
      'isEmpty': cells.isEmpty,
      'cells': cells,
    };

    await HomeWidget.saveWidgetData<String>(
      key,
      jsonEncode(envelope),
      appGroupId: _appGroupId,
    );
    await HomeWidget.updateWidget(
      androidName: _androidWidgetNames[scope],
      iOSName: _iOSWidgetNames[scope],
    );
  }

  String _statusString(DayStatusValue status) => switch (status) {
    DayStatusValue.success => 'success',
    DayStatusValue.fail => 'fail',
    DayStatusValue.cheat => 'cheat',
    DayStatusValue.empty => 'empty',
    DayStatusValue.pending => 'pending',
  };

  List<DateTime> _datesInRange(DateTime start, DateTime end) => [
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) d,
  ];
}

class _EligibleGoal {
  const _EligibleGoal({required this.goal, required this.versions});

  final Goal goal;
  final List<GoalVersion> versions;
}
