import '../entities/time_of_day_value.dart';

/// Domain-defined, storage-agnostic interface for the single global reminder
/// time (FR-30). Implemented by `SharedPrefsReminderSettingsRepository` in
/// `data/settings/` — `shared_preferences` is AD-3's one named exception to
/// Drift-only persistence, since this is a simple user setting, not
/// Goal/Version/Log domain data (AD-1).
abstract interface class ReminderSettingsRepository {
  /// The configured global reminder time, or `null` if Panda has never set
  /// one yet.
  Future<TimeOfDayValue?> getReminderTime();

  /// Persists [time] as the single global reminder time. There is no
  /// per-goal variant of this — FR-30 is explicit that only one time ever
  /// exists across the whole app.
  Future<void> setReminderTime(TimeOfDayValue time);

  /// Erases the persisted reminder time entirely, back to the "never set"
  /// (`null`) fresh-install state — Story 6.3's Reset/Erase-All (FR-36).
  Future<void> clear();
}
