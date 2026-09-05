import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/evaluator/period_boundary.dart';
import 'goal_service_provider.dart';
import 'reminder_settings_provider.dart';
import 'week_start_provider.dart';

part 'reset_provider.g.dart';

/// Story 6.3 (FR-36): the Settings screen's Reset/Erase-All write path. The
/// actual delete-everything/clear-settings logic lives entirely inside
/// `GoalService.resetAll()` (AD-6) — this controller's only job is
/// resolving the two settings repositories that method needs (unavoidably
/// async, since both sit behind `SharedPreferences.getInstance()`) and then
/// resetting the two live, synchronously-watched Settings values so every
/// screen reflects the fresh-install state immediately, with no app restart
/// required (AC #4). Every other screen (Dashboard, Goals, Calendar) needs
/// no equivalent nudge — they all read Goal/Version/Log data straight off
/// Drift's own `.watch()` streams, which already re-emit empty the instant
/// `resetAll()`'s transaction commits.
///
/// `keepAlive: true` for the same reason `ReminderTimeController`/
/// `WeekStartController` are: invoked via `ref.read` as a plain action call,
/// so nothing else keeps this provider's default auto-dispose lifetime
/// alive across its awaits.
@Riverpod(keepAlive: true)
class ResetController extends _$ResetController {
  @override
  FutureOr<void> build() {}

  Future<void> resetAll() async {
    final reminderSettingsRepository = await ref.read(
      reminderSettingsRepositoryProvider.future,
    );
    final weekStartSettingsRepository = await ref.read(
      weekStartSettingsRepositoryProvider.future,
    );

    await ref
        .read(goalServiceProvider)
        .resetAll(
          reminderSettingsRepository: reminderSettingsRepository,
          weekStartSettingsRepository: weekStartSettingsRepository,
        );

    ref.read(weekStartSettingProvider.notifier).set(WeekStart.monday);
    ref.invalidate(reminderTimeProvider);
  }
}
