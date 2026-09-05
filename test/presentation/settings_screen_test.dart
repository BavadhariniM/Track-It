import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/time_of_day_value.dart';
import 'package:tracker/domain/evaluator/period_boundary.dart';
import 'package:tracker/domain/services/import_file_reader.dart';
import 'package:tracker/domain/services/reminder_settings_repository.dart';
import 'package:tracker/domain/services/week_start_settings_repository.dart';
import 'package:tracker/presentation/providers/import_provider.dart';
import 'package:tracker/presentation/providers/reminder_settings_provider.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';
import 'package:tracker/presentation/providers/week_start_provider.dart';
import 'package:tracker/presentation/screens/settings_screen.dart';

import '../domain/services/fakes.dart';

/// In-memory fake standing in for `SharedPrefsWeekStartSettingsRepository`.
class _FakeWeekStartSettingsRepository
    implements WeekStartSettingsRepository {
  WeekStart? stored;

  @override
  Future<WeekStart?> getWeekStart() async => stored;

  @override
  Future<void> setWeekStart(WeekStart value) async => stored = value;

  @override
  Future<void> clear() async => stored = null;
}

/// Story 6.2 Task 6: a controllable stand-in for the platform file picker —
/// tests set [nextPick] to whatever `pickAndReadFile` should return next.
class _FakeImportFileReader implements ImportFileReader {
  String? nextPick;

  @override
  Future<String?> pickAndReadFile() async => nextPick;
}

/// In-memory fake standing in for `SharedPrefsReminderSettingsRepository` —
/// avoids `jsonImporterProvider` reaching the real `SharedPreferences`
/// plugin in these widget tests.
class _FakeReminderSettingsRepository implements ReminderSettingsRepository {
  TimeOfDayValue? stored;

  @override
  Future<TimeOfDayValue?> getReminderTime() async => stored;

  @override
  Future<void> setReminderTime(TimeOfDayValue time) async => stored = time;

  @override
  Future<void> clear() async => stored = null;
}

/// Story 4.1 Subtask 4.3 (Settings side of the same reactive-read pattern
/// Dashboard's own test covers): the reminder row reflects
/// [reminderTimeProvider] reactively, including the not-yet-configured
/// state — the picker dialog itself is a native platform widget and, like
/// this codebase's date pickers elsewhere, is not driven end-to-end here.
void main() {
  late _FakeWeekStartSettingsRepository weekStartRepository;
  late _FakeImportFileReader importFileReader;
  late InMemoryStore store;

  Widget buildApp({TimeOfDayValue? reminderTime}) {
    store = InMemoryStore();
    return ProviderScope(
      overrides: [
        reminderTimeProvider.overrideWith((ref) async => reminderTime),
        weekStartSettingsRepositoryProvider.overrideWith(
          (ref) => weekStartRepository,
        ),
        importFileReaderProvider.overrideWithValue(importFileReader),
        reminderSettingsRepositoryProvider.overrideWith(
          (ref) async => _FakeReminderSettingsRepository(),
        ),
        goalRepositoryProvider.overrideWithValue(InMemoryGoalRepository(store)),
        goalVersionRepositoryProvider.overrideWithValue(
          InMemoryGoalVersionRepository(store),
        ),
        goalLogRepositoryProvider.overrideWithValue(
          InMemoryGoalLogRepository(store),
        ),
        blackoutDateRepositoryProvider.overrideWithValue(
          InMemoryBlackoutDateRepository(store),
        ),
        cheatDayRepositoryProvider.overrideWithValue(
          InMemoryCheatDayRepository(store),
        ),
        transactionRunnerProvider.overrideWithValue(
          SnapshotTransactionRunner(store),
        ),
        statusCacheRepositoryProvider.overrideWithValue(
          InMemoryStatusCacheRepository(store),
        ),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  setUp(() {
    weekStartRepository = _FakeWeekStartSettingsRepository();
    importFileReader = _FakeImportFileReader();
  });

  testWidgets('shows "Not set" when no reminder time is configured', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Not set'), findsOneWidget);
  });

  testWidgets('shows the configured reminder time', (tester) async {
    await tester.pumpWidget(
      buildApp(reminderTime: const TimeOfDayValue(hour: 7, minute: 30)),
    );
    await tester.pumpAndSettle();

    expect(find.text('07:30'), findsOneWidget);
  });

  group('Story 6.1 — Week-Start setting', () {
    testWidgets('defaults to Monday selected', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final monday = tester.widget<OutlinedButton>(
        find.byKey(const Key('settings-week-start-monday')),
      );
      expect(monday.style?.backgroundColor?.resolve({}), isNotNull);
    });

    testWidgets(
      'tapping Sunday persists the choice and updates the live setting',
      (tester) async {
        late WidgetRef capturedRef;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              weekStartSettingsRepositoryProvider.overrideWith(
                (ref) => weekStartRepository,
              ),
            ],
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return const SettingsScreen();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('settings-week-start-sunday')));
        await tester.pumpAndSettle();

        expect(weekStartRepository.stored, WeekStart.sunday);
        expect(
          capturedRef.read(weekStartSettingProvider),
          WeekStart.sunday,
        );
      },
    );
  });

  group('Story 6.2 — Import data action', () {
    testWidgets('the Import data button exists in Settings', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings-import-button')), findsOneWidget);
    });

    testWidgets(
      'cancelling the file picker (a null pick) shows no snackbar and '
      'writes nothing',
      (tester) async {
        importFileReader.nextPick = null;
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('settings-import-button')));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsNothing);
        expect(store.goals, isEmpty);
      },
    );

    testWidgets(
      'Subtask 6.4: a rejected file shows the specific rejection reason, '
      'never a generic message',
      (tester) async {
        importFileReader.nextPick = '{not valid json';
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('settings-import-button')));
        await tester.pumpAndSettle();

        expect(find.textContaining('not valid JSON'), findsOneWidget);
        expect(store.goals, isEmpty);
      },
    );

    testWidgets(
      'Subtask 6.1: a well-formed, no-conflict file shows a silent-success '
      'confirmation and actually merges the data',
      (tester) async {
        importFileReader.nextPick = jsonEncode({
          'meta': {
            'schemaVersion': '1.0',
            'exportedAt': '2026-01-01T00:00:00',
          },
          'goals': [
            {
              'id': 'goal-1',
              'name': 'Read',
              'description': null,
              'category': null,
              'archived': false,
              'startDate': '2026-01-01',
              'endDate': null,
            },
          ],
          'goalVersions': [],
          'goalLogs': [],
          'cheatDays': [],
          'blackoutDates': [],
          'categories': [],
          'settings': {'weekStartDay': 'monday', 'reminderTime': null},
        });
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('settings-import-button')));
        await tester.pumpAndSettle();

        expect(find.textContaining('Import complete'), findsOneWidget);
        expect(store.goals, hasLength(1));
        expect(store.goals.single.id, 'goal-1');
      },
    );

    testWidgets(
      'Subtask 6.3: a zero-goal file shows warning copy distinct from '
      'plain success',
      (tester) async {
        importFileReader.nextPick = jsonEncode({
          'meta': {
            'schemaVersion': '1.0',
            'exportedAt': '2026-01-01T00:00:00',
          },
          'goals': <dynamic>[],
          'goalVersions': <dynamic>[],
          'goalLogs': <dynamic>[],
          'cheatDays': <dynamic>[],
          'blackoutDates': <dynamic>[],
          'categories': <dynamic>[],
          'settings': {'weekStartDay': 'monday', 'reminderTime': null},
        });
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('settings-import-button')));
        await tester.pumpAndSettle();

        expect(find.textContaining('no Goals to restore'), findsOneWidget);
        expect(find.text('Import complete.'), findsNothing);
      },
    );
  });
}
