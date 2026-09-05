import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/presentation/components/version_timeline.dart';

/// Story 3.2 Subtask 6.2: widget coverage for the Version Timeline
/// (UX-DR17) — segment ordering, the single-Version case (Subtask 4.3),
/// and the tap-on-segment plain-text detail sheet (Subtask 4.2).
void main() {
  const goal = Goal(
    id: 'goal-1',
    name: 'Run',
    archived: false,
    startDate: '2026-01-01',
  );

  Widget buildApp(List<GoalVersion> versions) {
    return MaterialApp(
      home: Scaffold(body: VersionTimeline(goal: goal, versions: versions)),
    );
  }

  GoalVersion version({
    required String id,
    required String versionStartDate,
    String eligibleDaysRule = EligibleDaysRule.everyDay,
  }) {
    return GoalVersion(
      id: id,
      goalId: goal.id,
      versionStartDate: versionStartDate,
      evaluationPeriod: EvaluationPeriod.daily,
      eligibleDaysRule: eligibleDaysRule,
      targetComparison: TargetComparison.exactly,
      targetValue: '1',
      trackingType: TrackingType.boolean,
    );
  }

  testWidgets(
    'a goal with only one Version renders a single full-width segment, '
    'not a hidden component (Subtask 4.3)',
    (tester) async {
      await tester.pumpWidget(
        buildApp([version(id: 'v1', versionStartDate: '2026-01-01')]),
      );

      expect(find.byKey(const Key('goal-detail-version-timeline')), findsOneWidget);
      expect(find.byKey(const Key('goal-detail-version-segment-0')), findsOneWidget);
      expect(find.byKey(const Key('goal-detail-version-segment-1')), findsNothing);
      expect(find.textContaining('present'), findsOneWidget);
    },
  );

  testWidgets(
    'multiple Versions render in date order regardless of input order, '
    'each labeled with its effective date range',
    (tester) async {
      // Deliberately passed out of order — the widget must sort by
      // versionStartDate itself, never assume caller ordering.
      await tester.pumpWidget(
        buildApp([
          version(id: 'v2', versionStartDate: '2026-03-15'),
          version(id: 'v1', versionStartDate: '2026-01-01'),
        ]),
      );

      expect(find.byKey(const Key('goal-detail-version-segment-0')), findsOneWidget);
      expect(find.byKey(const Key('goal-detail-version-segment-1')), findsOneWidget);

      final firstRect = tester.getTopLeft(
        find.byKey(const Key('goal-detail-version-segment-0')),
      );
      final secondRect = tester.getTopLeft(
        find.byKey(const Key('goal-detail-version-segment-1')),
      );
      expect(firstRect.dx, lessThan(secondRect.dx));

      expect(find.textContaining('Jan 1'), findsOneWidget);
      expect(find.textContaining('Mar 14'), findsOneWidget);
      expect(find.textContaining('Mar 15'), findsOneWidget);
      expect(find.textContaining('present'), findsOneWidget);
    },
  );

  testWidgets(
    "tapping a segment shows that Version's rules restated as plain text "
    '(Subtask 4.2), not a raw diff',
    (tester) async {
      await tester.pumpWidget(
        buildApp([
          version(
            id: 'v1',
            versionStartDate: '2026-01-01',
            eligibleDaysRule: EligibleDaysRule.workdays,
          ),
        ]),
      );

      await tester.tap(find.byKey(const Key('goal-detail-version-segment-0')));
      await tester.pumpAndSettle();

      final detail = find.byKey(const Key('goal-detail-version-detail-text'));
      expect(detail, findsOneWidget);
      expect(
        tester.widget<Text>(detail).data,
        'Done each eligible day, workdays only, starting Jan 1.',
      );
    },
  );
}
