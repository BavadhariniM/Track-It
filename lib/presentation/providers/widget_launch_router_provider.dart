import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../screens/day_view.dart';
import '../screens/month_view.dart';
import '../screens/week_view.dart';

part 'widget_launch_router_provider.g.dart';

/// The destination a `trackerapp://` widget-tap URI (Story 5.3's URI
/// contract, binding across both native platforms and this parser)
/// resolves to.
sealed class WidgetLaunchTarget {
  const WidgetLaunchTarget(this.date);

  final DateTime date;
}

class DayLaunchTarget extends WidgetLaunchTarget {
  const DayLaunchTarget(super.date);
}

class WeekLaunchTarget extends WidgetLaunchTarget {
  const WeekLaunchTarget(super.date);
}

class MonthLaunchTarget extends WidgetLaunchTarget {
  const MonthLaunchTarget(super.date);
}

/// Parses a widget-tap URI (`trackerapp://day|week|month?date=YYYY-MM-DD`)
/// into a [WidgetLaunchTarget]. Pure and unit-testable in isolation without
/// a real widget tap — given a URI string, this is the only place the
/// host/date shape is decoded (Task 1.4, Dev Notes' testing standard). Any
/// extra query items (e.g. iOS's `homeWidget` marker, added so
/// `home_widget`'s iOS plugin intercepts the URL at all) are ignored.
/// Returns `null` for anything that isn't one of the three known hosts, or
/// whose `date` isn't a parseable naive ISO-8601 date-only string.
WidgetLaunchTarget? parseWidgetLaunchUri(Uri? uri) {
  if (uri == null) return null;
  final dateParam = uri.queryParameters['date'];
  if (dateParam == null) return null;
  final date = DateTime.tryParse(dateParam);
  if (date == null) return null;
  return switch (uri.host) {
    'day' => DayLaunchTarget(date),
    'week' => WeekLaunchTarget(date),
    'month' => MonthLaunchTarget(date),
    _ => null,
  };
}

/// Pushes the screen a [WidgetLaunchTarget] names onto [navigatorKey]'s
/// current navigator — reusing the exact same screens/navigation any other
/// entry point uses (Task 1.4). The destination performs its own normal
/// live `evaluate()`-backed rendering exactly as it does when reached any
/// other way; tap-through changes only how the user arrived (AD-7).
void navigateToWidgetLaunchTarget(
  GlobalKey<NavigatorState> navigatorKey,
  WidgetLaunchTarget target,
) {
  final navigatorState = navigatorKey.currentState;
  if (navigatorState == null) return;
  final route = switch (target) {
    DayLaunchTarget() => MaterialPageRoute(
      builder: (_) => DayViewScreen(date: target.date),
    ),
    WeekLaunchTarget() => MaterialPageRoute(
      builder: (_) => WeekViewScreen(referenceDate: target.date),
    ),
    MonthLaunchTarget() => MaterialPageRoute(
      builder: (_) => MonthViewScreen(initialMonth: target.date),
    ),
  };
  navigatorState.push(route);
}

/// Composition root (AD-1): the app's root `Navigator` key, threaded into
/// `MaterialApp.navigatorKey` in `main.dart` so a deep-link tap can push a
/// route without a `BuildContext` of its own — no navigation key existed
/// before this story since every prior push already had a `BuildContext`
/// at hand.
final widgetLaunchNavigatorKey = GlobalKey<NavigatorState>();

/// Warm-start case (Task 1.3): `home_widget`'s `widgetClicked` stream fires
/// while the app is already running (foreground or background), so a
/// widget tap while the app is alive also routes correctly.
@Riverpod(keepAlive: true)
Stream<Uri?> widgetClicked(Ref ref) {
  return HomeWidget.widgetClicked;
}

/// Composition-root startup hook: detects a cold-start widget-tap launch
/// (Task 1.2, via `HomeWidget.initiallyLaunchedFromHomeWidget()`) and
/// subscribes to the warm-start stream (Task 1.3) for the app's whole
/// lifetime, routing both cases through the same
/// [navigateToWidgetLaunchTarget]/[widgetLaunchNavigatorKey].
@Riverpod(keepAlive: true)
Future<void> widgetLaunchWatcher(Ref ref) async {
  final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
  final initialTarget = parseWidgetLaunchUri(initialUri);
  if (initialTarget != null) {
    navigateToWidgetLaunchTarget(widgetLaunchNavigatorKey, initialTarget);
  }

  ref.listen<AsyncValue<Uri?>>(widgetClickedProvider, (previous, next) {
    next.whenData((uri) {
      final target = parseWidgetLaunchUri(uri);
      if (target != null) {
        navigateToWidgetLaunchTarget(widgetLaunchNavigatorKey, target);
      }
    });
  });
}
