import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/components/design_tokens.dart';
import 'presentation/providers/midnight_rollover_provider.dart';
import 'presentation/providers/reminder_settings_provider.dart';
import 'presentation/providers/week_start_provider.dart';
import 'presentation/providers/widget_bridge_provider.dart';
import 'presentation/providers/widget_launch_router_provider.dart';
import 'presentation/screens/app_shell.dart';

void main() {
  runApp(const ProviderScope(child: TrackerApp()));
}

class TrackerApp extends ConsumerWidget {
  const TrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activates the midnight-rollover watcher (Story 1.11 Task 1) for the
    // app's whole lifetime — a composition-root concern (AD-1), not
    // something any individual screen should be responsible for starting.
    ref.watch(midnightRolloverWatcherProvider);

    // Story 4.1 AC #4: initializes the notification plugin and re-registers
    // whatever reminder time was already set (if any), so a force-quit-then
    // -relaunch (not just a reboot) also re-arms it.
    ref.watch(reminderInitializerProvider);

    // Story 6.1: hydrates the Week-Start setting from `shared_preferences`
    // once at launch, so a value Panda chose in a previous session is
    // reflected before Week/Month View (and export) ever read it.
    ref.watch(weekStartInitializerProvider);

    // Story 5.1 Task 6.2: sets the iOS App Group id once per launch so every
    // widget-bridge write targets the shared container a future WidgetKit
    // extension (Story 5.2) reads from.
    ref.watch(widgetBridgeInitializerProvider);

    // Story 5.3 Task 1.2/1.3: detects a cold-start widget-tap launch and
    // subscribes to the warm-start `widgetClicked` stream, for the app's
    // whole lifetime.
    ref.watch(widgetLaunchWatcherProvider);

    return MaterialApp(
      title: 'Tracker',
      navigatorKey: widgetLaunchNavigatorKey,
      theme: _themeFor(AppColors.light, Brightness.light),
      darkTheme: _themeFor(AppColors.dark, Brightness.dark),
      home: const AppShell(),
    );
  }

  ThemeData _themeFor(AppColors colors, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.bgBase,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accent,
        onPrimary: colors.accentOn,
        secondary: colors.accent,
        onSecondary: colors.accentOn,
        error: colors.statusFail,
        onError: colors.statusFailOn,
        surface: colors.bgSurface,
        onSurface: colors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgBase,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
    );
  }
}
