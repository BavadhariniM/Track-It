import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/presentation/components/goal_row.dart';
import 'package:tracker/presentation/components/status_cell.dart';

/// Bug 8: `GoalRow` gains an optional `onNameTap` that splits the row into
/// two independent tap zones. When omitted, the row must keep its legacy
/// single-`InkWell`-over-the-whole-row behavior exactly (Day View, Goals
/// List, Week View all rely on this).
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets(
    'onNameTap null: tapping the name area fires onTap (legacy single-zone '
    'behavior preserved)',
    (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        wrap(
          GoalRow(
            name: 'Read',
            status: DayStatusValue.pending,
            trackingType: TrackingType.boolean,
            onTap: () => tapCount++,
          ),
        ),
      );

      await tester.tap(find.text('Read'));
      await tester.pump();

      expect(tapCount, 1);
    },
  );

  testWidgets(
    'onNameTap null: tapping the trailing area also fires onTap (legacy '
    'single-zone behavior preserved)',
    (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        wrap(
          GoalRow(
            name: 'Read',
            status: DayStatusValue.pending,
            trackingType: TrackingType.boolean,
            onTap: () => tapCount++,
          ),
        ),
      );

      await tester.tap(find.text('Done'));
      await tester.pump();

      expect(tapCount, 1);
    },
  );

  testWidgets(
    'onNameTap null: tapping the status dot (neither text label) still '
    'fires onTap, proving the whole row — not just the two text widgets — '
    'is one legacy tap zone',
    (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        wrap(
          GoalRow(
            name: 'Read',
            status: DayStatusValue.pending,
            trackingType: TrackingType.boolean,
            onTap: () => tapCount++,
          ),
        ),
      );

      await tester.tap(find.byType(StatusCell));
      await tester.pump();

      expect(tapCount, 1);
    },
  );

  testWidgets(
    'onNameTap set: tapping the name area fires onNameTap, not onTap',
    (tester) async {
      var nameTapCount = 0;
      var tapCount = 0;
      await tester.pumpWidget(
        wrap(
          GoalRow(
            name: 'Read',
            status: DayStatusValue.pending,
            trackingType: TrackingType.boolean,
            onTap: () => tapCount++,
            onNameTap: () => nameTapCount++,
          ),
        ),
      );

      await tester.tap(find.text('Read'));
      await tester.pump();

      expect(nameTapCount, 1);
      expect(tapCount, 0);
    },
  );

  testWidgets(
    'onNameTap set: tapping the trailing area fires onTap, not onNameTap',
    (tester) async {
      var nameTapCount = 0;
      var tapCount = 0;
      await tester.pumpWidget(
        wrap(
          GoalRow(
            name: 'Read',
            status: DayStatusValue.pending,
            trackingType: TrackingType.boolean,
            onTap: () => tapCount++,
            onNameTap: () => nameTapCount++,
          ),
        ),
      );

      await tester.tap(find.text('Done'));
      await tester.pump();

      expect(tapCount, 1);
      expect(nameTapCount, 0);
    },
  );

  testWidgets(
    'onNameTap set: long-pressing the name zone fires onLongPress',
    (tester) async {
      var longPressCount = 0;
      await tester.pumpWidget(
        wrap(
          GoalRow(
            name: 'Read',
            status: DayStatusValue.pending,
            trackingType: TrackingType.boolean,
            onNameTap: () {},
            onLongPress: () => longPressCount++,
          ),
        ),
      );

      await tester.longPress(find.text('Read'));
      await tester.pump();

      expect(longPressCount, 1);
    },
  );

  testWidgets(
    'onNameTap set: long-pressing the trailing zone also fires onLongPress',
    (tester) async {
      var longPressCount = 0;
      await tester.pumpWidget(
        wrap(
          GoalRow(
            name: 'Read',
            status: DayStatusValue.pending,
            trackingType: TrackingType.boolean,
            onNameTap: () {},
            onLongPress: () => longPressCount++,
          ),
        ),
      );

      await tester.longPress(find.text('Done'));
      await tester.pump();

      expect(longPressCount, 1);
    },
  );

  group('Counter fraction display distinguishes floor/ceiling/exact targets', () {
    testWidgets('At Least renders a bare fraction, no comparison symbol', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          GoalRow(
            name: 'Water',
            status: DayStatusValue.success,
            trackingType: TrackingType.counter,
            currentValue: 1,
            targetValue: 2,
            targetComparison: TargetComparison.atLeast,
          ),
        ),
      );

      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets(
      'At Most prefixes the target with "≤" so "0/≤2" cannot be misread as '
      '"0 of 2 needed"',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            GoalRow(
              name: 'Coffee',
              status: DayStatusValue.success,
              trackingType: TrackingType.counter,
              currentValue: 0,
              targetValue: 2,
              targetComparison: TargetComparison.atMost,
            ),
          ),
        );

        expect(find.text('0/≤2'), findsOneWidget);
      },
    );

    testWidgets('Exactly prefixes the target with "="', (tester) async {
      await tester.pumpWidget(
        wrap(
          GoalRow(
            name: 'Stairs',
            status: DayStatusValue.success,
            trackingType: TrackingType.counter,
            currentValue: 2,
            targetValue: 2,
            targetComparison: TargetComparison.exactly,
          ),
        ),
      );

      expect(find.text('2/=2'), findsOneWidget);
    });

    testWidgets('a null targetComparison (Boolean callers) falls back to a bare fraction', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          GoalRow(
            name: 'Water',
            status: DayStatusValue.pending,
            trackingType: TrackingType.counter,
            currentValue: 1,
            targetValue: 2,
          ),
        ),
      );

      expect(find.text('1/2'), findsOneWidget);
    });
  });
}
