import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/services/goal_filter.dart';

part 'goal_filter_provider.g.dart';

/// Story 3.5 Subtask 3.2: the Calendar's currently-applied [GoalFilter],
/// defaulting to "all Goals" (AC 3). `keepAlive: true` — same reasoning as
/// `GoalWizard` (Story 2.1) — so the selection survives navigating between
/// the Day/Week/Month calendar screens within a session rather than
/// resetting to All on every screen push, without persisting across app
/// restarts (not specified, Subtask 3.2).
@Riverpod(keepAlive: true)
class SelectedGoalFilter extends _$SelectedGoalFilter {
  @override
  GoalFilter build() => const GoalFilter.all();

  void setFilter(GoalFilter filter) => state = filter;
}
