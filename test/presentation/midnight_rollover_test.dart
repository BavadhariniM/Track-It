import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/entities/time_of_day_value.dart';
import 'package:tracker/domain/evaluator/period_boundary.dart';
import 'package:tracker/domain/services/reminder_scheduler.dart';
import 'package:tracker/domain/services/reminder_settings_repository.dart';
import 'package:tracker/presentation/components/goal_row.dart';
import 'package:tracker/presentation/components/status_cell.dart';
import 'package:tracker/presentation/providers/current_date_provider.dart';
import 'package:tracker/presentation/providers/midnight_rollover_provider.dart';
import 'package:tracker/presentation/providers/reminder_settings_provider.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';
import 'package:tracker/presentation/screens/day_view.dart';
import 'package:tracker/presentation/screens/month_view.dart';

import '../domain/services/fakes.dart';

/// Local fakes standing in for the reminder settings repository/scheduler —
/// same shape as `reminder_settings_provider_test.dart`'s own, kept
/// file-local since each of this suite's `flutter_local_notifications`-
/// adjacent fakes only needs to satisfy this file's own scenarios.
class _FakeReminderSettingsRepository implements ReminderSettingsRepository {
  TimeOfDayValue? stored;

  @override
  Future<TimeOfDayValue?> getReminderTime() async => stored;

  @override
  Future<void> setReminderTime(TimeOfDayValue time) async => stored = time;

  @override
  Future<void> clear() async => stored = null;
}

class _FakeReminderScheduler implements ReminderScheduler {
  final List<ReminderContent?> builtContent = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleDaily({
    required TimeOfDayValue time,
    required ReminderContentBuilder contentBuilder,
  }) async {
    builtContent.add(await contentBuilder());
  }

  @override
  Future<void> cancel() async {}
}

/// Covers Story 1.11's midnight-rollover behavior: Subtask 5.1 (the
/// in-flight Counter direct-entry auto-commits against the pre-rollover
/// date), and Subtask 5.2 (the rollover is a silent, no-interstitial full
/// reload of "today"-dependent UI state — Month View's isToday ring and
/// jump-to-today target, per this story's `MonthViewScreen` staleness
/// fix).
void main() {
  late InMemoryStore store;
  late StreamController<DateTime> dateController;
  late _FakeReminderSettingsRepository reminderRepo;
  late _FakeReminderScheduler reminderScheduler;

  const counterGoal = Goal(
    id: 'goal-counter',
    name: 'Water',
    archived: false,
    startDate: '2026-08-01',
  );
  final counterVersion = GoalVersion(
    id: 'version-counter',
    goalId: counterGoal.id,
    versionStartDate: '2026-08-01',
    evaluationPeriod: EvaluationPeriod.daily,
    eligibleDaysRule: EligibleDaysRule.everyDay,
    targetComparison: TargetComparison.atLeast,
    targetValue: '8',
    trackingType: TrackingType.counter,
  );

  baseOverrides() => [
    goalRepositoryProvider.overrideWithValue(InMemoryGoalRepository(store)),
    goalVersionRepositoryProvider.overrideWithValue(
      InMemoryGoalVersionRepository(store),
    ),
    goalLogRepositoryProvider.overrideWithValue(
      InMemoryGoalLogRepository(store),
    ),
    blackoutDateRepositoryProvider.overrideWithValue(
      InMemoryBlackoutDateRepository(store),
    ),
    cheatDayRepositoryProvider.overrideWithValue(
      InMemoryCheatDayRepository(store),
    ),
    transactionRunnerProvider.overrideWithValue(
      SnapshotTransactionRunner(store),
    ),
    statusCacheRepositoryProvider.overrideWithValue(
      InMemoryStatusCacheRepository(store),
    ),
    currentDateProvider.overrideWith((ref) => dateController.stream),
    reminderSettingsRepositoryProvider.overrideWith((ref) => reminderRepo),
    reminderSchedulerProvider.overrideWith((ref) => reminderScheduler),
  ];

  setUp(() {
    dateController = StreamController<DateTime>();
    reminderRepo = _FakeReminderSettingsRepository();
    reminderScheduler = _FakeReminderScheduler();
  });

  tearDown(() async {
    if (!dateController.isClosed) {
      await dateController.close();
    }
  });

  testWidgets(
    'a midnight rollover auto-commits an in-flight Counter direct-entry '
    'edit against the pre-rollover date, not the new day (Subtask 5.1)',
    (tester) async {
      store = InMemoryStore()
        ..goals.add(counterGoal)
        ..versions.add(counterVersion);

      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                // Activates the watcher, matching main.dart's composition
                // root (Task 1).
                ref.watch(midnightRolloverWatcherProvider);
                return DayViewScreen(date: DateTime(2026, 8, 30));
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Establish the pre-rollover baseline date.
      dateController.add(DateTime(2026, 8, 30));
      await tester.pump();

      // Open the goal row's Counter dialog, then its direct-entry field,
      // and start typing — but never tap Save.
      await tester.tap(find.widgetWithText(GoalRow, 'Water'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Enter an amount'));
      await tester.pumpAndSettle();
      expect(find.text('Log an amount'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '5');
      await tester.pump();

      // The clock rolls over to the next day while the dialog is still
      // open with unsaved text.
      dateController.add(DateTime(2026, 8, 31));
      await tester.pumpAndSettle();

      // Auto-committed against 2026-08-30 (the day it was entered on),
      // never 2026-08-31 (FR-20, AC #1).
      expect(store.logs, hasLength(1));
      expect(store.logs.single.goalId, counterGoal.id);
      expect(store.logs.single.date, '2026-08-30');
      expect(store.logs.single.value, 5);

      // The direct-entry dialog closed itself silently — no leftover
      // modal asking the user to confirm anything, no toast (UX-DR21).
      expect(find.text('Log an amount'), findsNothing);
      // The outer Counter dialog (a live, reactive view — not in-flight
      // state) is untouched and still open, now reflecting the committed
      // total.
      expect(find.text('Done'), findsOneWidget);
    },
  );

  testWidgets(
    'typing nothing valid before a rollover discards the in-flight edit '
    'without writing a log',
    (tester) async {
      store = InMemoryStore()
        ..goals.add(counterGoal)
        ..versions.add(counterVersion);

      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                ref.watch(midnightRolloverWatcherProvider);
                return DayViewScreen(date: DateTime(2026, 8, 30));
              },
            ),
          ),
        ),
      );
      await tester.pump();
      dateController.add(DateTime(2026, 8, 30));
      await tester.pump();

      await tester.tap(find.widgetWithText(GoalRow, 'Water'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Enter an amount'));
      await tester.pumpAndSettle();

      // Leave the field empty/unparseable.
      dateController.add(DateTime(2026, 8, 31));
      await tester.pumpAndSettle();

      expect(store.logs, isEmpty);
      expect(find.text('Log an amount'), findsNothing);
    },
  );

  testWidgets(
    'Story 4.2: a midnight rollover re-registers an already-configured '
    'reminder with freshly-computed suppression-aware content',
    (tester) async {
      store = InMemoryStore()
        ..goals.add(counterGoal)
        ..versions.add(counterVersion);
      reminderRepo.stored = const TimeOfDayValue(hour: 20, minute: 0);

      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                ref.watch(midnightRolloverWatcherProvider);
                return DayViewScreen(date: DateTime(2026, 8, 30));
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Establishes the baseline date; not itself a rollover, so no
      // reschedule happens yet.
      dateController.add(DateTime(2026, 8, 30));
      await tester.pump();
      expect(reminderScheduler.builtContent, isEmpty);

      // The date advances — this IS a rollover, so the reminder is
      // re-registered with fresh content reflecting the new day.
      dateController.add(DateTime(2026, 8, 31));
      await tester.pumpAndSettle();

      expect(reminderScheduler.builtContent, hasLength(1));
      final content = reminderScheduler.builtContent.single;
      expect(content, isNotNull);
      expect(content!.body, contains('Water'));
    },
  );

  testWidgets(
    'Story 4.2: a midnight rollover does not touch the scheduler when no '
    'reminder time has ever been configured',
    (tester) async {
      store = InMemoryStore()
        ..goals.add(counterGoal)
        ..versions.add(counterVersion);
      // reminderRepo.stored left null (never configured).

      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                ref.watch(midnightRolloverWatcherProvider);
                return DayViewScreen(date: DateTime(2026, 8, 30));
              },
            ),
          ),
        ),
      );
      await tester.pump();

      dateController.add(DateTime(2026, 8, 30));
      await tester.pump();
      dateController.add(DateTime(2026, 8, 31));
      await tester.pumpAndSettle();

      expect(reminderScheduler.builtContent, isEmpty);
    },
  );

  testWidgets(
    'after a same-month rollover, Month View quietly moves the isToday '
    'ring with no interstitial (Subtask 5.2, MonthViewScreen staleness fix)',
    (tester) async {
      store = InMemoryStore();

      // `MonthViewScreen`'s page anchor is established from the real
      // wall-clock month at `initState` (deliberately never re-derived —
      // see the field doc on `_pageEpochMonth`), so the two synthetic
      // "today"s this test injects must fall inside *that* real month to
      // land on the page that's actually built/visible without swiping.
      // Picking day 10 -> day 11 of the real current month keeps this
      // fully independent of which real month the suite happens to run
      // in, and avoids any weekday-alignment edge cases at a month
      // boundary.
      final now = DateTime.now();
      final preRollover = DateTime(now.year, now.month, 10);
      final postRollover = DateTime(now.year, now.month, 11);

      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: const MaterialApp(home: MonthViewScreen()),
        ),
      );
      await tester.pump();

      dateController.add(preRollover);
      await tester.pumpAndSettle();

      final grid = _monthGrid(
        DateTime(now.year, now.month, 1),
        WeekStart.monday,
      );
      final preIndex = preRollover.difference(grid.gridStart).inDays;
      final postIndex = postRollover.difference(grid.gridStart).inDays;

      expect(_cellHasTodayRing(tester, preIndex), isTrue);
      expect(_cellHasTodayRing(tester, postIndex), isFalse);

      dateController.add(postRollover);
      await tester.pumpAndSettle();

      // Silent refresh: no dialog, no snackbar, no navigation — the same
      // MonthViewScreen, same page, just a quietly-updated ring.
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(MonthViewScreen), findsOneWidget);

      expect(_cellHasTodayRing(tester, preIndex), isFalse);
      expect(_cellHasTodayRing(tester, postIndex), isTrue);
    },
  );

  testWidgets(
    '"jump to today" retargets the new month after a rollover that also '
    'crosses a month boundary, not the launch-time month',
    (tester) async {
      store = InMemoryStore();

      // Deliberately cross a real month boundary (last day of the real
      // current month -> first day of the next) to prove `_todayPage` is
      // recomputed from the live "today", not the fixed launch-time page
      // anchor (`_pageEpochMonth`) — this is the concrete bug described in
      // this story's orientation notes ("jump to today would jump to
      // yesterday['s month]").
      final now = DateTime.now();
      final preRollover = DateTime(now.year, now.month + 1, 0); // last day
      final postRollover = DateTime(
        now.year,
        now.month + 1,
        1,
      ); // next month, day 1

      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: const MaterialApp(home: MonthViewScreen()),
        ),
      );
      await tester.pump();

      dateController.add(preRollover);
      await tester.pumpAndSettle();
      dateController.add(postRollover);
      await tester.pumpAndSettle();

      // Swipe away from the launch-time page first, so a jump that
      // secretly still targeted the stale launch-time anchor page
      // wouldn't be indistinguishable from a no-op.
      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Jump to today'));
      await tester.pumpAndSettle();

      final title = tester
          .widget<Text>(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.byType(Text),
            ),
          )
          .data;
      expect(title, _monthLabel(postRollover));
    },
  );
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

({DateTime gridStart, DateTime gridEnd}) _monthGrid(
  DateTime month,
  WeekStart weekStart,
) {
  final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
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
  return (gridStart: gridStart, gridEnd: gridEnd);
}

/// Locates the day cell hosting the [index]-th `StatusCell` in grid order
/// and reports whether its nearest `Container` ancestor renders the
/// isToday accent-color ring border.
bool _cellHasTodayRing(WidgetTester tester, int index) {
  final containerFinder = find
      .ancestor(
        of: find.byType(StatusCell).at(index),
        matching: find.byType(Container),
      )
      .first;
  final container = tester.widget<Container>(containerFinder);
  final decoration = container.decoration;
  if (decoration is! BoxDecoration) return false;
  return decoration.border != null;
}
