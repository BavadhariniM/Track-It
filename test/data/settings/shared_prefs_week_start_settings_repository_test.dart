import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracker/data/settings/shared_prefs_week_start_settings_repository.dart';
import 'package:tracker/domain/evaluator/period_boundary.dart';

/// Story 6.1: the `shared_preferences`-backed Week-Start repository's
/// set/get round-trip and its default (unset) behavior — mirrors
/// `shared_prefs_reminder_settings_repository_test.dart`'s coverage shape.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPrefsWeekStartSettingsRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = SharedPrefsWeekStartSettingsRepository(prefs);
  });

  test('returns null when Panda has never changed the Week-Start setting', () async {
    expect(await repository.getWeekStart(), isNull);
  });

  test('set/get round-trips monday', () async {
    await repository.setWeekStart(WeekStart.monday);

    expect(await repository.getWeekStart(), WeekStart.monday);
  });

  test('set/get round-trips sunday', () async {
    await repository.setWeekStart(WeekStart.sunday);

    expect(await repository.getWeekStart(), WeekStart.sunday);
  });

  test('stores the value as its plain enum name', () async {
    await repository.setWeekStart(WeekStart.sunday);

    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getString(weekStartDayKey), 'sunday');
  });

  test('a later write overwrites the previous choice', () async {
    await repository.setWeekStart(WeekStart.sunday);
    await repository.setWeekStart(WeekStart.monday);

    expect(await repository.getWeekStart(), WeekStart.monday);
  });
}
