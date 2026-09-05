import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/notifications/flutter_local_notifications_reminder_scheduler.dart';
import '../../data/settings/shared_prefs_reminder_settings_repository.dart';
import '../../domain/entities/time_of_day_value.dart';
import '../../domain/services/reminder_scheduler.dart';
import '../../domain/services/reminder_settings_repository.dart';
import '../../domain/services/reminder_suppression_service.dart';
import 'current_date_provider.dart';
import 'repository_providers.dart';
import 'week_start_provider.dart';

part 'reminder_settings_provider.g.dart';

/// Story 4.2 (FR-30): the suppression-aware [ReminderContentBuilder] wired
/// into every call site that (re)registers the daily notification (this
/// file's [ReminderTimeController] and [reminderInitializer], plus
/// `midnight_rollover_provider.dart`'s own re-registration hook) — replacing
/// Story 4.1's fixed, unconditional body. Reads every non-Archived Goal plus
/// its Versions/Logs/CheatDays/BlackoutDates once, filters them through
/// `filterRemindableGoals` (the domain's single source of suppression truth,
/// itself built on `evaluate()`), and returns `null` when nothing remains so
/// the scheduler never fires an empty reminder (AC #5).
///
/// Built fresh (closing over the current [ref]) at each registration call
/// rather than once at startup, since `flutter_local_notifications` bakes
/// notification content in at scheduling time, not at the moment it actually
/// fires — see [ReminderContentBuilder]'s doc comment. Re-invoking this at
/// the midnight-rollover boundary (in addition to app-open and Settings
/// writes) is what keeps that baked-in content from going stale for an
/// entire day at a time.
ReminderContentBuilder buildSuppressionAwareReminderContent(Ref ref) {
  return () async {
    final goalRepository = ref.read(goalRepositoryProvider);
    final versionRepository = ref.read(goalVersionRepositoryProvider);
    final logRepository = ref.read(goalLogRepositoryProvider);
    final cheatDayRepository = ref.read(cheatDayRepositoryProvider);
    final blackoutDateRepository = ref.read(blackoutDateRepositoryProvider);
    final weekStart = ref.read(weekStartSettingProvider);
    final date = todayDateOnly();

    final goals = await goalRepository.watchAllGoals().first;
    final inputs = <GoalReminderInput>[];
    for (final goal in goals) {
      if (goal.archived) continue;
      inputs.add(
        GoalReminderInput(
          goal: goal,
          versions: await versionRepository.findAllForGoal(goal.id),
          logs: await logRepository.findAllForGoal(goal.id),
          cheatDays: await cheatDayRepository.findAllForGoal(goal.id),
          blackoutDates: await blackoutDateRepository.findAllForGoal(goal.id),
        ),
      );
    }

    final remindable = filterRemindableGoals(
      goals: inputs,
      date: date,
      weekStart: weekStart,
    );
    if (remindable.isEmpty) return null;

    // UX-DR19: plain, declarative — states what's outstanding as fact,
    // never cheerleading/exclamation-marked copy.
    final names = remindable.map((goal) => goal.name).join(', ');
    return ReminderContent(title: 'Reminder', body: 'Not yet logged: $names');
  };
}

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) {
  return SharedPreferences.getInstance();
}

/// This is the composition root (AD-1/AD-2): the only place that binds
/// [ReminderSettingsRepository] to its `shared_preferences`-backed
/// implementation (AD-3's settings exception).
@Riverpod(keepAlive: true)
Future<ReminderSettingsRepository> reminderSettingsRepository(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SharedPrefsReminderSettingsRepository(prefs);
}

/// This is the composition root (AD-1/AD-2): the only place that binds
/// [ReminderScheduler] to its `flutter_local_notifications`-backed
/// implementation. `keepAlive` so the plugin instance is never recreated.
@Riverpod(keepAlive: true)
ReminderScheduler reminderScheduler(Ref ref) {
  return FlutterLocalNotificationsReminderScheduler(
    FlutterLocalNotificationsPlugin(),
  );
}

/// The configured global reminder time (FR-30), or `null` if Panda has never
/// set one yet. Read by both the Settings screen (pre-filling the time
/// picker) and the Dashboard (Story 3.1's "next reminder" display).
@riverpod
Future<TimeOfDayValue?> reminderTime(Ref ref) async {
  final repo = await ref.watch(reminderSettingsRepositoryProvider.future);
  return repo.getReminderTime();
}

/// The Settings screen's write path (Task 1.4): persists a new reminder
/// time and re-registers the daily notification for it in one step, then
/// invalidates [reminderTimeProvider] so every reader (Settings, Dashboard)
/// picks up the change reactively.
/// `keepAlive: true`: `setReminderTime` is invoked via `ref.read` (a plain
/// action call, not a `watch`), so nothing keeps this provider's default
/// auto-dispose lifetime alive across the awaits inside it — without this,
/// Riverpod tears the notifier down mid-method as soon as the synchronous
/// call returns, which surfaces as an `UnmountedRefException` once
/// `setReminderTime` reaches its first `await`.
@Riverpod(keepAlive: true)
class ReminderTimeController extends _$ReminderTimeController {
  @override
  FutureOr<void> build() {}

  Future<void> setReminderTime(TimeOfDayValue time) async {
    final repo = await ref.read(reminderSettingsRepositoryProvider.future);
    await repo.setReminderTime(time);

    final scheduler = ref.read(reminderSchedulerProvider);
    await scheduler.scheduleDaily(
      time: time,
      contentBuilder: buildSuppressionAwareReminderContent(ref),
    );

    ref.invalidate(reminderTimeProvider);
  }
}

/// Composition-root startup hook (Story 4.1 AC #4): initializes the
/// notification plugin once per app launch, then re-registers whatever
/// reminder time was already configured (if any). Android reboots are
/// re-armed by the plugin's own boot receiver (see
/// `FlutterLocalNotificationsReminderScheduler`'s doc comment); this covers
/// the force-quit-then-relaunch case, where no reboot occurs but the
/// process (and any of its in-memory scheduling state) starts fresh.
@Riverpod(keepAlive: true)
Future<void> reminderInitializer(Ref ref) async {
  final scheduler = ref.watch(reminderSchedulerProvider);
  await scheduler.initialize();

  final time = await ref.watch(reminderTimeProvider.future);
  if (time == null) return;

  await scheduler.scheduleDaily(
    time: time,
    contentBuilder: buildSuppressionAwareReminderContent(ref),
  );
}
