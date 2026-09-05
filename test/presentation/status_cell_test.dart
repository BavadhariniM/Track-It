import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/presentation/components/status_cell.dart';

void main() {
  testWidgets(
    'Empty status renders the dash glyph with a "Not eligible" label',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusCell(status: DayStatusValue.empty)),
        ),
      );

      expect(find.text('–'), findsOneWidget);
      expect(find.bySemanticsLabel('Not eligible'), findsOneWidget);
      handle.dispose();
    },
  );

  // Story 1.8 (Subtask 3.1/4.6): the certain-failure Fail and Pending
  // states must render with their own distinct glyph/label too, completing
  // the five-state vocabulary (UX-DR6) for the first time.
  testWidgets(
    'Fail status renders the X glyph with a "Failed, certain" label',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusCell(status: DayStatusValue.fail)),
        ),
      );

      expect(find.text('✕'), findsOneWidget);
      expect(find.bySemanticsLabel('Failed, certain'), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets(
    'Pending status renders the ellipsis glyph with a "Pending" label',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusCell(status: DayStatusValue.pending)),
        ),
      );

      expect(find.text('…'), findsOneWidget);
      expect(find.bySemanticsLabel('Pending'), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets(
    'Pending, Empty, and Fail each render a visually distinct fill color '
    '(UX-DR11/UX-DR20) — Pending never collapses into a shared gray with '
    'Empty, nor a disguised red with Fail',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusCell(
                  status: DayStatusValue.pending,
                  key: Key('pending-cell'),
                ),
                StatusCell(
                  status: DayStatusValue.empty,
                  key: Key('empty-cell'),
                ),
                StatusCell(status: DayStatusValue.fail, key: Key('fail-cell')),
              ],
            ),
          ),
        ),
      );

      Color fillColorOf(String keyValue) {
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byKey(Key(keyValue)),
            matching: find.byType(Container),
          ),
        );
        return (container.decoration! as BoxDecoration).color!;
      }

      final pendingColor = fillColorOf('pending-cell');
      final emptyColor = fillColorOf('empty-cell');
      final failColor = fillColorOf('fail-cell');

      expect(pendingColor, isNot(equals(emptyColor)));
      expect(pendingColor, isNot(equals(failColor)));
      expect(emptyColor, isNot(equals(failColor)));
    },
  );
}
