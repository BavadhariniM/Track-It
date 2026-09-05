import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/data/io/import/import_validation_result.dart';
import 'package:tracker/data/io/import/json_import_validator.dart';

/// Deep-copyable baseline: one Goal with one governing GoalVersion, no
/// overlaps, matching Story 6.1's export schema field-for-field.
Map<String, dynamic> _validFile() => {
  'meta': {'schemaVersion': '1.0', 'exportedAt': '2026-01-01T00:00:00'},
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
  'goalVersions': [
    {
      'id': 'version-1',
      'goalId': 'goal-1',
      'versionStartDate': '2026-01-01',
      'evaluationPeriod': 'daily',
      'eligibleDaysRule': '1,2,3,4,5,6,7',
      'targetComparison': 'at_least',
      'targetValue': '1',
      'trackingType': 'boolean',
      'cheatDayQuota': 0,
      'isPaused': false,
    },
  ],
  'goalLogs': [
    {
      'id': 'log-1',
      'goalId': 'goal-1',
      'date': '2026-01-02',
      'timestamp': '2026-01-02T08:00:00',
      'value': 1.0,
      'completed': true,
      'dnfMarked': false,
      'note': null,
    },
  ],
  'cheatDays': [
    {'id': 'cheat-1', 'goalId': 'goal-1', 'date': '2026-01-03', 'note': null},
  ],
  'blackoutDates': [
    {
      'id': 'blackout-1',
      'goalId': 'goal-1',
      'date': '2026-01-04',
      'reason': null,
    },
  ],
  'categories': [],
  'settings': {'weekStartDay': 'monday', 'reminderTime': null},
};

void main() {
  const validator = JsonImportValidator();

  ImportValidationResult validate(
    Map<String, dynamic> file, {
    Set<String> existingLocalGoalIds = const {},
  }) {
    return validator.validate(
      jsonEncode(file),
      existingLocalGoalIds: existingLocalGoalIds,
    );
  }

  group('Story 6.2 — JsonImportValidator', () {
    test('Subtask 7.1: a well-formed file with no overlaps is accepted', () {
      final result = validate(_validFile());

      expect(result, isA<ImportValidationValid>());
      final valid = result as ImportValidationValid;
      expect(valid.zeroGoalWarning, isFalse);
      expect(valid.file.goals, hasLength(1));
      expect(valid.file.goalVersions, hasLength(1));
      expect(valid.file.goalLogs, hasLength(1));
      expect(valid.file.cheatDays, hasLength(1));
      expect(valid.file.blackoutDates, hasLength(1));
    });

    test('Subtask 7.2: malformed JSON is rejected', () {
      final result = validator.validate(
        '{not valid json',
        existingLocalGoalIds: const {},
      );

      expect(result, isA<ImportValidationRejected>());
      expect(
        (result as ImportValidationRejected).reason,
        contains('not valid JSON'),
      );
    });

    test(
      'Subtask 7.3: a missing goals array is rejected, naming goals '
      'specifically',
      () {
        final file = _validFile()..remove('goals');

        final result = validate(file);

        expect(result, isA<ImportValidationRejected>());
        expect((result as ImportValidationRejected).reason, contains('goals'));
      },
    );

    test(
      'Subtask 7.4: a missing meta.schemaVersion is rejected, naming the '
      'missing field specifically',
      () {
        final file = _validFile();
        (file['meta'] as Map).remove('schemaVersion');

        final result = validate(file);

        expect(result, isA<ImportValidationRejected>());
        expect(
          (result as ImportValidationRejected).reason,
          contains('schemaVersion'),
        );
      },
    );

    test(
      'Subtask 7.5: an unsupported schemaVersion value is rejected as a '
      'version mismatch, naming the value',
      () {
        final file = _validFile();
        (file['meta'] as Map)['schemaVersion'] = '2.0';

        final result = validate(file);

        expect(result, isA<ImportValidationRejected>());
        expect((result as ImportValidationRejected).reason, contains('2.0'));
      },
    );

    test(
      'Subtask 7.6: a duplicate id within the file is rejected, naming the '
      'duplicate',
      () {
        final file = _validFile();
        (file['goals'] as List).add({
          'id': 'goal-1',
          'name': 'Duplicate',
          'description': null,
          'category': null,
          'archived': false,
          'startDate': '2026-02-01',
          'endDate': null,
        });

        final result = validate(file);

        expect(result, isA<ImportValidationRejected>());
        expect(
          (result as ImportValidationRejected).reason,
          contains('goal-1'),
        );
      },
    );

    test(
      'Subtask 7.7: an orphaned log referencing a nonexistent Goal is '
      'rejected, naming the missing Goal',
      () {
        final file = _validFile();
        (file['goalLogs'] as List).add({
          'id': 'log-2',
          'goalId': 'ghost-goal',
          'date': '2026-01-05',
          'timestamp': '2026-01-05T08:00:00',
          'value': 1.0,
          'completed': true,
          'dnfMarked': false,
          'note': null,
        });

        final result = validate(file);

        expect(result, isA<ImportValidationRejected>());
        expect(
          (result as ImportValidationRejected).reason,
          contains('no longer exists'),
        );
      },
    );

    test(
      'a goalId referencing existing local data (not in the file) is not '
      'an orphan',
      () {
        final file = _validFile();
        (file['goalLogs'] as List).add({
          'id': 'log-2',
          'goalId': 'local-goal',
          'date': '2026-01-05',
          'timestamp': '2026-01-05T08:00:00',
          'value': 1.0,
          'completed': true,
          'dnfMarked': false,
          'note': null,
        });

        final result = validate(
          file,
          existingLocalGoalIds: {'local-goal'},
        );

        expect(result, isA<ImportValidationValid>());
      },
    );

    test(
      'Subtask 7.8: an invalid date is rejected, naming the field',
      () {
        final file = _validFile();
        (file['goals'] as List<dynamic>).first['startDate'] = '2026-02-30';

        final result = validate(file);

        expect(result, isA<ImportValidationRejected>());
        expect(
          (result as ImportValidationRejected).reason,
          contains('startDate'),
        );
      },
    );

    test(
      'Subtask 7.9: a contradictory targetComparison is rejected, naming '
      'the contradiction',
      () {
        final file = _validFile();
        (file['goalVersions'] as List<dynamic>).first['targetComparison'] =
            'range';

        final result = validate(file);

        expect(result, isA<ImportValidationRejected>());
        expect(
          (result as ImportValidationRejected).reason,
          contains('targetComparison'),
        );
      },
    );

    test(
      'Subtask 7.9: a Range-shaped legacy record (min/max fields) is '
      'rejected, naming the contradiction',
      () {
        final file = _validFile();
        (file['goalVersions'] as List<dynamic>).first['min'] = 1;
        (file['goalVersions'] as List<dynamic>).first['max'] = 5;

        final result = validate(file);

        expect(result, isA<ImportValidationRejected>());
        expect(
          (result as ImportValidationRejected).reason,
          contains('Range-shaped'),
        );
      },
    );

    test(
      'Subtask 7.10: an invalid Cheat Day configuration (negative quota) '
      'is rejected, naming the problem',
      () {
        final file = _validFile();
        (file['goalVersions'] as List<dynamic>).first['cheatDayQuota'] = -1;

        final result = validate(file);

        expect(result, isA<ImportValidationRejected>());
        expect(
          (result as ImportValidationRejected).reason,
          contains('cheatDayQuota'),
        );
      },
    );

    test(
      'Subtask 7.11: a zero-goal file is accepted with a warning, not '
      'rejected',
      () {
        final file = _validFile();
        file['goals'] = <dynamic>[];
        file['goalVersions'] = <dynamic>[];
        file['goalLogs'] = <dynamic>[];
        file['cheatDays'] = <dynamic>[];
        file['blackoutDates'] = <dynamic>[];

        final result = validate(file);

        expect(result, isA<ImportValidationValid>());
        expect((result as ImportValidationValid).zeroGoalWarning, isTrue);
      },
    );

    test(
      'a missing goals key (not merely empty) is still a rejection, not a '
      'zero-goal acceptance',
      () {
        final file = _validFile()..remove('goals');

        final result = validate(file);

        expect(result, isA<ImportValidationRejected>());
      },
    );
  });
}
