import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/data/widget_bridge/widget_bridge_writer_impl.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';

import '../../domain/services/fakes.dart';

/// Story 5.1 Task 4: guardrail tests for the data-layer [WidgetBridgeWriterImpl]
/// — exact JSON envelope shape per scope (including the empty-state
/// envelope, AC4), the cache-only rule (AC5), and the `home_widget`
/// platform channel calls (Task 4.3), all against fixture cache rows via a
/// mocked `MethodChannel` rather than a real device/simulator.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('home_widget');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'saveWidgetData':
            case 'updateWidget':
              return true;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  const goal = Goal(
    id: 'goal-1',
    name: 'Drink Water',
    archived: false,
    startDate: '2026-01-01',
  );
  const version = GoalVersion(
    id: 'version-1',
    goalId: 'goal-1',
    versionStartDate: '2026-01-01',
    evaluationPeriod: EvaluationPeriod.daily,
    eligibleDaysRule: EligibleDaysRule.everyDay,
    targetComparison: TargetComparison.exactly,
    targetValue: '1',
    trackingType: TrackingType.boolean,
  );

  Map<String, dynamic> savedEnvelopeFor(String key) {
    final call = calls.firstWhere(
      (c) =>
          c.method == 'saveWidgetData' &&
          (c.arguments as Map)['id'] == key,
      orElse: () =>
          throw StateError('no saveWidgetData call recorded for key $key'),
    );
    final data = (call.arguments as Map)['data'] as String;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  WidgetBridgeWriterImpl writerFor(InMemoryStore store) {
    return WidgetBridgeWriterImpl(
      goalRepository: InMemoryGoalRepository(store),
      goalVersionRepository: InMemoryGoalVersionRepository(store),
      statusCacheRepository: InMemoryStatusCacheRepository(store),
    );
  }

  test(
    'writes a today cell sourced exactly from the cache, never from '
    'evaluate() (AC5) — the cache is seeded with a status a fresh '
    'evaluate() call could not produce for these inputs (no GoalLog exists, '
    'so a live evaluate() would say Pending, never Fail), and '
    'WidgetBridgeWriterImpl has no GoalLogRepository/evaluate() path to have '
    'derived Fail from at all',
    () async {
      final store = InMemoryStore()
        ..goals.add(goal)
        ..versions.add(version);
      store.statusCache['${goal.id}|2026-08-19'] = const DayStatus(
        goalId: 'goal-1',
        date: '2026-08-19',
        status: DayStatusValue.fail,
      );

      await writerFor(store).writeAll(DateTime(2026, 8, 19));

      final envelope = savedEnvelopeFor(
        WidgetBridgeWriterImpl.todayWidgetDataKey,
      );
      expect(envelope['scope'], 'today');
      expect(envelope['generatedAt'], '2026-08-19');
      expect(envelope['rangeStart'], '2026-08-19');
      expect(envelope['rangeEnd'], '2026-08-19');
      expect(envelope['isEmpty'], false);
      expect(envelope['cells'], [
        {
          'date': '2026-08-19',
          'goalId': 'goal-1',
          'goalName': 'Drink Water',
          'status': 'fail',
        },
      ]);
    },
  );

  test(
    'writes isEmpty:true with cells:[] for every scope when no goal is '
    'eligible (AC4) — never a skipped write',
    () async {
      final store = InMemoryStore();

      await writerFor(store).writeAll(DateTime(2026, 8, 19));

      for (final key in [
        WidgetBridgeWriterImpl.todayWidgetDataKey,
        WidgetBridgeWriterImpl.weekWidgetDataKey,
        WidgetBridgeWriterImpl.monthWidgetDataKey,
      ]) {
        final envelope = savedEnvelopeFor(key);
        expect(envelope['isEmpty'], true, reason: key);
        expect(envelope['cells'], isEmpty, reason: key);
      }
    },
  );

  test(
    'a cache miss for a date (no row ever written) is skipped, never '
    'falling back to a live evaluate() call',
    () async {
      final store = InMemoryStore()
        ..goals.add(goal)
        ..versions.add(version);
      // No statusCache entry for 2026-08-19 at all.

      await writerFor(store).writeAll(DateTime(2026, 8, 19));

      final envelope = savedEnvelopeFor(
        WidgetBridgeWriterImpl.todayWidgetDataKey,
      );
      expect(envelope['isEmpty'], true);
      expect(envelope['cells'], isEmpty);
    },
  );

  test('excludes archived and expired goals from every scope', () async {
    final archivedGoal = goal.copyWith(id: 'archived', archived: true);
    final archivedVersion = version.copyWith(
      id: 'v-archived',
      goalId: 'archived',
    );
    final expiredGoal = Goal(
      id: 'expired',
      name: 'Old Habit',
      archived: false,
      startDate: '2020-01-01',
      endDate: '2020-02-01',
    );
    final expiredVersion = version.copyWith(
      id: 'v-expired',
      goalId: 'expired',
      versionStartDate: '2020-01-01',
    );

    final store = InMemoryStore()
      ..goals.addAll([archivedGoal, expiredGoal])
      ..versions.addAll([archivedVersion, expiredVersion]);
    store.statusCache['archived|2026-08-19'] = const DayStatus(
      goalId: 'archived',
      date: '2026-08-19',
      status: DayStatusValue.success,
    );
    store.statusCache['expired|2026-08-19'] = const DayStatus(
      goalId: 'expired',
      date: '2026-08-19',
      status: DayStatusValue.success,
    );

    await writerFor(store).writeAll(DateTime(2026, 8, 19));

    final envelope = savedEnvelopeFor(
      WidgetBridgeWriterImpl.todayWidgetDataKey,
    );
    expect(envelope['isEmpty'], true);
    expect(envelope['cells'], isEmpty);
  });

  test(
    'excludes a (goal, date) cell that falls under a paused GoalVersion, '
    'mirroring Week/Month View\'s own per-day pause rule',
    () async {
      final pausedVersion = version.copyWith(isPaused: true);
      final store = InMemoryStore()
        ..goals.add(goal)
        ..versions.add(pausedVersion);
      store.statusCache['${goal.id}|2026-08-19'] = const DayStatus(
        goalId: 'goal-1',
        date: '2026-08-19',
        status: DayStatusValue.success,
      );

      await writerFor(store).writeAll(DateTime(2026, 8, 19));

      final envelope = savedEnvelopeFor(
        WidgetBridgeWriterImpl.todayWidgetDataKey,
      );
      expect(envelope['isEmpty'], true);
      expect(envelope['cells'], isEmpty);
    },
  );

  test(
    'excludes a (goal, date) cell that falls before the goal\'s own '
    'startDate, mirroring Week/Month View\'s own per-day pre-start rule '
    '(Bug 5)',
    () async {
      final futureStartGoal = goal.copyWith(startDate: '2026-08-20');
      final store = InMemoryStore()
        ..goals.add(futureStartGoal)
        ..versions.add(version);
      store.statusCache['${goal.id}|2026-08-19'] = const DayStatus(
        goalId: 'goal-1',
        date: '2026-08-19',
        status: DayStatusValue.success,
      );

      await writerFor(store).writeAll(DateTime(2026, 8, 19));

      final envelope = savedEnvelopeFor(
        WidgetBridgeWriterImpl.todayWidgetDataKey,
      );
      expect(envelope['isEmpty'], true);
      expect(envelope['cells'], isEmpty);

      // Week/month scopes don't exclude by status (excludeEmptyStatus:
      // false), so this cell being absent there proves the pre-start guard
      // — not the pre-existing Empty-status filter — is what excludes it.
      final week = savedEnvelopeFor(WidgetBridgeWriterImpl.weekWidgetDataKey);
      final weekCells = (week['cells'] as List).cast<Map<String, dynamic>>();
      expect(weekCells.where((c) => c['date'] == '2026-08-19'), isEmpty);

      final month = savedEnvelopeFor(
        WidgetBridgeWriterImpl.monthWidgetDataKey,
      );
      final monthCells = (month['cells'] as List)
          .cast<Map<String, dynamic>>();
      expect(monthCells.where((c) => c['date'] == '2026-08-19'), isEmpty);
    },
  );

  test(
    "today's scope excludes an Empty-status cell (mirrors "
    'StatsService.todayProgress\'s "eligible today" filter) while week/month '
    'scopes include the same Empty-status cell (mirrors in-app Week/Month '
    'View, which renders every non-paused day regardless of status)',
    () async {
      final store = InMemoryStore()
        ..goals.add(goal)
        ..versions.add(version);
      store.statusCache['${goal.id}|2026-08-19'] = const DayStatus(
        goalId: 'goal-1',
        date: '2026-08-19',
        status: DayStatusValue.empty,
      );

      await writerFor(store).writeAll(DateTime(2026, 8, 19));

      final today = savedEnvelopeFor(WidgetBridgeWriterImpl.todayWidgetDataKey);
      expect(today['cells'], isEmpty);

      final week = savedEnvelopeFor(WidgetBridgeWriterImpl.weekWidgetDataKey);
      final weekCells = (week['cells'] as List).cast<Map<String, dynamic>>();
      expect(
        weekCells.where((c) => c['date'] == '2026-08-19' && c['status'] == 'empty'),
        isNotEmpty,
      );
    },
  );

  test(
    'calls HomeWidget.saveWidgetData for all three keys and '
    'HomeWidget.updateWidget once per scope',
    () async {
      final store = InMemoryStore()
        ..goals.add(goal)
        ..versions.add(version);
      store.statusCache['${goal.id}|2026-08-19'] = const DayStatus(
        goalId: 'goal-1',
        date: '2026-08-19',
        status: DayStatusValue.success,
      );

      await writerFor(store).writeAll(DateTime(2026, 8, 19));

      final saveCalls = calls.where((c) => c.method == 'saveWidgetData');
      final savedKeys = saveCalls
          .map((c) => (c.arguments as Map)['id'] as String)
          .toSet();
      expect(savedKeys, {
        WidgetBridgeWriterImpl.todayWidgetDataKey,
        WidgetBridgeWriterImpl.weekWidgetDataKey,
        WidgetBridgeWriterImpl.monthWidgetDataKey,
      });

      final updateCalls = calls.where((c) => c.method == 'updateWidget');
      expect(updateCalls.length, 3);
    },
  );
}
