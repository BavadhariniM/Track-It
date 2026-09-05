import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/time_of_day_value.dart';
import '../../domain/services/reminder_scheduler.dart';

/// The single notification id this app ever schedules — there is only ever
/// one global reminder (FR-30), so re-scheduling always replaces it rather
/// than accumulating separate pending notifications.
const reminderNotificationId = 1;

const _channelId = 'daily_reminder';
const _channelName = 'Daily reminder';

/// `flutter_local_notifications`-backed [ReminderScheduler] (AD-1: the
/// plugin import lives here, in `data`, never in `domain`). Entirely
/// on-device — no remote push registration, no network call (NFR-1, NFR-2).
///
/// Android's `RECEIVE_BOOT_COMPLETED` permission (declared in
/// `AndroidManifest.xml`) lets the plugin's own boot receiver re-arm this
/// scheduled notification after a device reboot (AC #4) without this class
/// doing anything extra; iOS local notifications are OS-persisted across
/// reboots by design.
class FlutterLocalNotificationsReminderScheduler implements ReminderScheduler {
  FlutterLocalNotificationsReminderScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _timezoneReady = false;

  @override
  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Without these, every scheduleDaily call below still "succeeds" but the
    // OS silently drops the notification — Android 13+ (API 33+) denies
    // POST_NOTIFICATIONS by default, and Android 12+ (API 31+) can similarly
    // withhold exact-alarm scheduling. `resolvePlatformSpecificImplementation`
    // returns `null` on iOS (no Android-specific implementation there); iOS's
    // own alert/badge/sound permission prompt is instead requested by the
    // `DarwinInitializationSettings()` defaults passed to `_plugin.initialize`
    // above.
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  Future<void> _ensureTimezone() async {
    if (_timezoneReady) return;
    tz_data.initializeTimeZones();
    final localName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localName.identifier));
    _timezoneReady = true;
  }

  @override
  Future<void> scheduleDaily({
    required TimeOfDayValue time,
    required ReminderContentBuilder contentBuilder,
  }) async {
    await _ensureTimezone();

    final content = await contentBuilder();
    if (content == null) {
      await cancel();
      return;
    }

    await _plugin.zonedSchedule(
      id: reminderNotificationId,
      title: content.title,
      body: content.body,
      scheduledDate: _nextInstanceOf(time),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel() => _plugin.cancel(id: reminderNotificationId);

  tz.TZDateTime _nextInstanceOf(TimeOfDayValue time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
