import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/evaluator/period_boundary.dart';
import '../../domain/services/week_start_settings_repository.dart';

/// The `shared_preferences` key the Week-Start setting (FR-24) is stored
/// under — read by `week_start_provider.dart`'s startup hydration hook and
/// written by the Settings screen's Week-Start control, so both sides always
/// agree on where the value lives.
const weekStartDayKey = 'week_start_day';

/// `shared_preferences`-backed implementation of [WeekStartSettingsRepository]
/// — AD-3's one named exception to Drift-only persistence, since the
/// Week-Start setting is a simple user preference, not Goal/Version/Log
/// domain data. Stores the value as its enum name (`"monday"`/`"sunday"`).
class SharedPrefsWeekStartSettingsRepository
    implements WeekStartSettingsRepository {
  const SharedPrefsWeekStartSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<WeekStart?> getWeekStart() async {
    final raw = _prefs.getString(weekStartDayKey);
    return switch (raw) {
      'monday' => WeekStart.monday,
      'sunday' => WeekStart.sunday,
      _ => null,
    };
  }

  @override
  Future<void> setWeekStart(WeekStart value) async {
    await _prefs.setString(weekStartDayKey, value.name);
  }

  @override
  Future<void> clear() => _prefs.remove(weekStartDayKey);
}
