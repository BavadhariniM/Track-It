import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';
import 'package:tracker/presentation/providers/widget_launch_router_provider.dart';
import 'package:tracker/presentation/screens/day_view.dart';
import 'package:tracker/presentation/screens/month_view.dart';
import 'package:tracker/presentation/screens/week_view.dart';

import '../domain/services/fakes.dart';

/// Story 5.3 Task 1.4/Dev Notes' testing standard: the URI-parsing/routing
/// logic is unit-testable in isolation (given a URI string, assert the
/// correct screen/date is targeted) without needing a real widget tap.
void main() {
  group('parseWidgetLaunchUri', () {
    test('parses a day URI', () {
      final target = parseWidgetLaunchUri(
        Uri.parse('trackerapp://day?date=2026-08-31'),
      );
      expect(target, isA<DayLaunchTarget>());
      expect(target!.date, DateTime(2026, 8, 31));
    });

    test('parses a week URI', () {
      final target = parseWidgetLaunchUri(
        Uri.parse('trackerapp://week?date=2026-08-24'),
      );
      expect(target, isA<WeekLaunchTarget>());
      expect(target!.date, DateTime(2026, 8, 24));
    });

    test('parses a month URI', () {
      final target = parseWidgetLaunchUri(
        Uri.parse('trackerapp://month?date=2026-08-01'),
      );
      expect(target, isA<MonthLaunchTarget>());
      expect(target!.date, DateTime(2026, 8, 1));
    });

    test('ignores extra query items, e.g. iOS homeWidget marker', () {
      final target = parseWidgetLaunchUri(
        Uri.parse('trackerapp://day?date=2026-08-31&homeWidget=true'),
      );
      expect(target, isA<DayLaunchTarget>());
      expect(target!.date, DateTime(2026, 8, 31));
    });

    test('returns null for an unknown host', () {
      final target = parseWidgetLaunchUri(
        Uri.parse('trackerapp://year?date=2026-08-31'),
      );
      expect(target, isNull);
    });

    test('returns null when the date query parameter is missing', () {
      final target = parseWidgetLaunchUri(Uri.parse('trackerapp://day'));
      expect(target, isNull);
    });

    test('returns null for an unparseable date', () {
      final target = parseWidgetLaunchUri(
        Uri.parse('trackerapp://day?date=not-a-date'),
      );
      expect(target, isNull);
    });

    test('returns null for a null uri', () {
      expect(parseWidgetLaunchUri(null), isNull);
    });
  });

  group('navigateToWidgetLaunchTarget', () {
    late InMemoryStore store;
    late GlobalKey<NavigatorState> navigatorKey;

    Widget buildApp() {
      store = InMemoryStore();
      navigatorKey = GlobalKey<NavigatorState>();
      return ProviderScope(
        overrides: [
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
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );
    }

    testWidgets('a day target pushes DayViewScreen at that date', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      navigateToWidgetLaunchTarget(
        navigatorKey,
        DayLaunchTarget(DateTime(2026, 8, 31)),
      );
      await tester.pumpAndSettle();

      final screen = tester.widget<DayViewScreen>(find.byType(DayViewScreen));
      expect(screen.date, DateTime(2026, 8, 31));
    });

    testWidgets('a week target pushes WeekViewScreen at that date', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      navigateToWidgetLaunchTarget(
        navigatorKey,
        WeekLaunchTarget(DateTime(2026, 8, 24)),
      );
      await tester.pumpAndSettle();

      final screen = tester.widget<WeekViewScreen>(
        find.byType(WeekViewScreen),
      );
      expect(screen.referenceDate, DateTime(2026, 8, 24));
    });

    testWidgets('a month target pushes MonthViewScreen at that month', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      navigateToWidgetLaunchTarget(
        navigatorKey,
        MonthLaunchTarget(DateTime(2026, 8, 1)),
      );
      await tester.pumpAndSettle();

      final screen = tester.widget<MonthViewScreen>(
        find.byType(MonthViewScreen),
      );
      expect(screen.initialMonth, DateTime(2026, 8, 1));
    });

    testWidgets('no-ops when the navigator has no current state yet', (
      tester,
    ) async {
      final detachedKey = GlobalKey<NavigatorState>();
      expect(
        () => navigateToWidgetLaunchTarget(
          detachedKey,
          DayLaunchTarget(DateTime(2026, 8, 31)),
        ),
        returnsNormally,
      );
    });
  });
}
