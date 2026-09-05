import '../evaluator/period_boundary.dart';

/// Domain-defined, storage-agnostic interface for the persisted Week-Start
/// setting (FR-24). Implemented by `SharedPrefsWeekStartSettingsRepository`
/// in `data/settings/` — `shared_preferences` is AD-3's one named exception
/// to Drift-only persistence, since this is a simple user setting, not
/// Goal/Version/Log domain data (AD-1). Mirrors
/// `ReminderSettingsRepository`'s shape.
abstract interface class WeekStartSettingsRepository {
  /// The persisted Week-Start setting, or `null` if Panda has never changed
  /// it away from the [WeekStart.monday] default yet.
  Future<WeekStart?> getWeekStart();

  /// Persists [value] as the Week-Start setting.
  Future<void> setWeekStart(WeekStart value);

  /// Erases the persisted Week-Start choice entirely, back to the "never
  /// changed" (`null`) fresh-install state — Story 6.3's Reset/Erase-All
  /// (FR-36).
  Future<void> clear();
}
