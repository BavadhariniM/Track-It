import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_lifecycle_status.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';

/// Story 2.2 Subtask 3.2: unit coverage for `resolveLifecycleStatus`'s
/// `paused` branch — a date exactly on the pause's `versionStartDate`, a
/// date exactly on the resume's `versionStartDate` (Active again, per AC
/// 3's "from the resume date forward"), and a date strictly inside the
/// paused range.
void main() {
  const goal = Goal(
    id: 'goal-1',
    name: 'Read',
    archived: false,
    startDate: '2026-08-01',
  );

  GoalVersion versionAt(String startDate, {bool isPaused = false}) =>
      GoalVersion(
        id: 'version-$startDate-$isPaused',
        goalId: goal.id,
        versionStartDate: startDate,
        evaluationPeriod: EvaluationPeriod.daily,
        eligibleDaysRule: EligibleDaysRule.everyDay,
        targetComparison: TargetComparison.exactly,
        targetValue: '1',
        trackingType: TrackingType.boolean,
        isPaused: isPaused,
      );

  test('a goal with a single unpaused Version resolves Active', () {
    final status = resolveLifecycleStatus(
      goal: goal,
      versions: [versionAt('2026-08-01')],
      today: '2026-08-15',
    );
    expect(status, GoalLifecycleStatus.active);
  });

  test('a date exactly on the pause Version\'s start date resolves Paused', () {
    final status = resolveLifecycleStatus(
      goal: goal,
      versions: [
        versionAt('2026-08-01'),
        versionAt('2026-08-10', isPaused: true),
      ],
      today: '2026-08-10',
    );
    expect(status, GoalLifecycleStatus.paused);
  });

  test('a date strictly inside the paused range resolves Paused', () {
    final status = resolveLifecycleStatus(
      goal: goal,
      versions: [
        versionAt('2026-08-01'),
        versionAt('2026-08-10', isPaused: true),
      ],
      today: '2026-08-15',
    );
    expect(status, GoalLifecycleStatus.paused);
  });

  test('a date exactly on the resume Version\'s start date resolves Active '
      'again (AC 3: "from the resume date forward")', () {
    final status = resolveLifecycleStatus(
      goal: goal,
      versions: [
        versionAt('2026-08-01'),
        versionAt('2026-08-10', isPaused: true),
        versionAt('2026-08-20'),
      ],
      today: '2026-08-20',
    );
    expect(status, GoalLifecycleStatus.active);
  });

  test('a date after the resume date stays Active', () {
    final status = resolveLifecycleStatus(
      goal: goal,
      versions: [
        versionAt('2026-08-01'),
        versionAt('2026-08-10', isPaused: true),
        versionAt('2026-08-20'),
      ],
      today: '2026-08-25',
    );
    expect(status, GoalLifecycleStatus.active);
  });

  test(
    'a date before every Version resolves Active (no governing Version)',
    () {
      final status = resolveLifecycleStatus(
        goal: goal,
        versions: [versionAt('2026-08-01')],
        today: '2026-07-01',
      );
      expect(status, GoalLifecycleStatus.active);
    },
  );

  group('archived / expired precedence (Story 2.3 Subtask 2.2)', () {
    test('an archived goal resolves Archived, even with no end date', () {
      const archivedGoal = Goal(
        id: 'goal-1',
        name: 'Read',
        archived: true,
        startDate: '2026-08-01',
      );
      final status = resolveLifecycleStatus(
        goal: archivedGoal,
        versions: [versionAt('2026-08-01')],
        today: '2026-08-15',
      );
      expect(status, GoalLifecycleStatus.archived);
    });

    test('an archived-and-past-end-date goal resolves Archived (archived '
        'outranks expired)', () {
      const archivedGoal = Goal(
        id: 'goal-1',
        name: 'Read',
        archived: true,
        startDate: '2026-08-01',
        endDate: '2026-08-10',
      );
      final status = resolveLifecycleStatus(
        goal: archivedGoal,
        versions: [versionAt('2026-08-01')],
        today: '2026-08-20',
      );
      expect(status, GoalLifecycleStatus.archived);
    });

    test('a paused-and-past-end-date goal resolves Expired (expired outranks '
        'paused)', () {
      const endedGoal = Goal(
        id: 'goal-1',
        name: 'Read',
        archived: false,
        startDate: '2026-08-01',
        endDate: '2026-08-10',
      );
      final status = resolveLifecycleStatus(
        goal: endedGoal,
        versions: [versionAt('2026-08-01', isPaused: true)],
        today: '2026-08-20',
      );
      expect(status, GoalLifecycleStatus.expired);
    });

    test('a goal exactly on its end date (not yet past) is not Expired — the '
        'boundary is strictly after, not on', () {
      const endingTodayGoal = Goal(
        id: 'goal-1',
        name: 'Read',
        archived: false,
        startDate: '2026-08-01',
        endDate: '2026-08-10',
      );
      final status = resolveLifecycleStatus(
        goal: endingTodayGoal,
        versions: [versionAt('2026-08-01')],
        today: '2026-08-10',
      );
      expect(status, GoalLifecycleStatus.active);
    });

    test(
      'a goal past its end date but not archived/paused resolves Expired',
      () {
        const endedGoal = Goal(
          id: 'goal-1',
          name: 'Read',
          archived: false,
          startDate: '2026-08-01',
          endDate: '2026-08-10',
        );
        final status = resolveLifecycleStatus(
          goal: endedGoal,
          versions: [versionAt('2026-08-01')],
          today: '2026-08-11',
        );
        expect(status, GoalLifecycleStatus.expired);
      },
    );
  });
}
