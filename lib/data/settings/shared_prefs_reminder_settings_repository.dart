import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/time_of_day_value.dart';
import '../../domain/services/reminder_settings_repository.dart';

/// The `shared_preferences` key the global daily reminder time (FR-30) is
/// stored under — read by `dashboard_screen.dart` (Story 3.1's "next
/// reminder" display) via this same repository, so both sides always agree
/// on where the value lives.
const reminderTimeKey = 'global_reminder_time';

/// `shared_preferences`-backed implementation of [ReminderSettingsRepository]
/// — AD-3's one named exception to Drift-only persistence, since the
/// reminder time is a simple user setting, not Goal/Version/Log domain data.
/// Stores the time as a zero-padded `"HH:mm"` string (e.g. `"07:30"`).
class SharedPrefsReminderSettingsRepository
    implements ReminderSettingsRepository {
  const SharedPrefsReminderSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<TimeOfDayValue?> getReminderTime() async {
    final raw = _prefs.getString(reminderTimeKey);
    if (raw == null) return null;
    final parts = raw.split(':');
    return TimeOfDayValue(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  @override
  Future<void> setReminderTime(TimeOfDayValue time) async {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    await _prefs.setString(reminderTimeKey, '$hh:$mm');
  }

  @override
  Future<void> clear() => _prefs.remove(reminderTimeKey);
}
