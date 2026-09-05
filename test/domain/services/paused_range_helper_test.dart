import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/services/paused_range_helper.dart';

/// Story 2.2 Subtask 3.3: unit coverage for `isPausedOn` — a date exactly
/// on the pause's `versionStartDate`, a date exactly on the resume's
/// `versionStartDate` (not paused, per AC 3's "from the resume date
/// forward"), and a date strictly inside the paused range.
void main() {
  GoalVersion versionAt(
    String goalId,
    String startDate, {
    bool isPaused = false,
  }) => GoalVersion(
    id: 'version-$startDate-$isPaused',
    goalId: goalId,
    versionStartDate: startDate,
    evaluationPeriod: EvaluationPeriod.daily,
    eligibleDaysRule: EligibleDaysRule.everyDay,
    targetComparison: TargetComparison.exactly,
    targetValue: '1',
    trackingType: TrackingType.boolean,
    isPaused: isPaused,
  );

  test('false for a goal with no Versions', () {
    expect(isPausedOn(const [], '2026-08-15'), isFalse);
  });

  test('false before any Version has started', () {
    final versions = [versionAt('goal-1', '2026-08-01')];
    expect(isPausedOn(versions, '2026-07-01'), isFalse);
  });

  test("true exactly on the pause Version's start date", () {
    final versions = [
      versionAt('goal-1', '2026-08-01'),
      versionAt('goal-1', '2026-08-10', isPaused: true),
    ];
    expect(isPausedOn(versions, '2026-08-10'), isTrue);
  });

  test('true strictly inside the paused range', () {
    final versions = [
      versionAt('goal-1', '2026-08-01'),
      versionAt('goal-1', '2026-08-10', isPaused: true),
    ];
    expect(isPausedOn(versions, '2026-08-15'), isTrue);
  });

  test("false exactly on the resume Version's start date (AC 3: 'from the "
      "resume date forward')", () {
    final versions = [
      versionAt('goal-1', '2026-08-01'),
      versionAt('goal-1', '2026-08-10', isPaused: true),
      versionAt('goal-1', '2026-08-20'),
    ];
    expect(isPausedOn(versions, '2026-08-20'), isFalse);
  });

  test('false after the resume date', () {
    final versions = [
      versionAt('goal-1', '2026-08-01'),
      versionAt('goal-1', '2026-08-10', isPaused: true),
      versionAt('goal-1', '2026-08-20'),
    ];
    expect(isPausedOn(versions, '2026-08-25'), isFalse);
  });

  test('unordered input is sorted internally before use', () {
    final versions = [
      versionAt('goal-1', '2026-08-20'),
      versionAt('goal-1', '2026-08-10', isPaused: true),
      versionAt('goal-1', '2026-08-01'),
    ];
    expect(isPausedOn(versions, '2026-08-15'), isTrue);
    expect(isPausedOn(versions, '2026-08-20'), isFalse);
  });

  group('isIneligibleDailyDayOn (Bug 7)', () {
    GoalVersion versionWith(
      String startDate, {
      String evaluationPeriod = EvaluationPeriod.daily,
      String eligibleDaysRule = EligibleDaysRule.everyDay,
    }) => GoalVersion(
      id: 'version-$startDate-$evaluationPeriod-$eligibleDaysRule',
      goalId: 'goal-1',
      versionStartDate: startDate,
      evaluationPeriod: evaluationPeriod,
      eligibleDaysRule: eligibleDaysRule,
      targetComparison: TargetComparison.exactly,
      targetValue: '1',
      trackingType: TrackingType.boolean,
    );

    // 2026-08-15 is a Saturday; 2026-08-17 is a Monday.
    final saturday = DateTime(2026, 8, 15);
    final monday = DateTime(2026, 8, 17);
    final goalStart = DateTime(2026, 8, 1);

    test('false for a goal with no governing Version', () {
      expect(isIneligibleDailyDayOn(const [], saturday, goalStart), isFalse);
    });

    test('true for a Daily/Workdays-only goal on a Saturday', () {
      final versions = [
        versionWith('2026-08-01', eligibleDaysRule: EligibleDaysRule.workdays),
      ];
      expect(isIneligibleDailyDayOn(versions, saturday, goalStart), isTrue);
    });

    test('false for a Daily/Workdays-only goal on a Monday (eligible day)', () {
      final versions = [
        versionWith('2026-08-01', eligibleDaysRule: EligibleDaysRule.workdays),
      ];
      expect(isIneligibleDailyDayOn(versions, monday, goalStart), isFalse);
    });

    test(
      'false for a Weekly goal on a Saturday even with a Workdays-only '
      'eligibleDaysRule — period-type goals never hide via this predicate, '
      "only evaluate()'s own period aggregation governs them",
      () {
        final versions = [
          versionWith(
            '2026-08-01',
            evaluationPeriod: EvaluationPeriod.weekly,
            eligibleDaysRule: EligibleDaysRule.workdays,
          ),
        ];
        expect(isIneligibleDailyDayOn(versions, saturday, goalStart), isFalse);
      },
    );
  });
}
