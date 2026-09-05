import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracker/data/settings/shared_prefs_reminder_settings_repository.dart';
import 'package:tracker/domain/entities/time_of_day_value.dart';

/// Story 4.1 Subtask 4.1: the `shared_preferences`-backed repository's
/// set/get round-trip and its default (unset) behavior — both fully
/// unit-testable without any real device I/O.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPrefsReminderSettingsRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = SharedPrefsReminderSettingsRepository(prefs);
  });

  test('returns null when no reminder time has ever been configured', () async {
    expect(await repository.getReminderTime(), isNull);
  });

  test('set/get round-trips the exact hour and minute', () async {
    await repository.setReminderTime(
      const TimeOfDayValue(hour: 7, minute: 30),
    );

    final result = await repository.getReminderTime();

    expect(result, const TimeOfDayValue(hour: 7, minute: 30));
  });

  test('zero-pads single-digit hour and minute in storage', () async {
    await repository.setReminderTime(const TimeOfDayValue(hour: 9, minute: 5));

    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getString(reminderTimeKey), '09:05');
  });

  test('a later write overwrites the previous reminder time', () async {
    await repository.setReminderTime(
      const TimeOfDayValue(hour: 7, minute: 30),
    );
    await repository.setReminderTime(
      const TimeOfDayValue(hour: 20, minute: 15),
    );

    expect(
      await repository.getReminderTime(),
      const TimeOfDayValue(hour: 20, minute: 15),
    );
  });
}
