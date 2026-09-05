import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'goals/goals_list_screen.dart';
import 'month_view.dart';
import 'settings_screen.dart';

/// The persistent bottom tab bar (UX-DR12): Today · Calendar · Goals ·
/// Settings, four tabs, no drawer (EXPERIENCE.md's Information Architecture)
/// — the app's composition-root navigation shell, wired in as `main.dart`'s
/// `home` (AC 6). Today (the Dashboard) is the default/active tab, matching
/// the IA table's "App open (cold start), tab bar" entry; Month View
/// remains Calendar's own default sub-view (FR-23).
///
/// Only the selected tab's screen is built at a time (not an eager
/// `IndexedStack` of all four) — simpler, and avoids every tab's data
/// providers/streams running while off-screen.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    MonthViewScreen(),
    GoalsListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
