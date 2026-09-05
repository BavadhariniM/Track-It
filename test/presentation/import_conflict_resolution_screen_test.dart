import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/data/io/import/import_conflict.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/presentation/components/primary_button.dart';
import 'package:tracker/presentation/screens/import_conflict_resolution_screen.dart';

/// Story 6.2 Task 4 (AC #9, UX-DR14): per-conflict resolution, no bulk
/// "accept all," Finish only enabled once every conflict has a decision.
void main() {
  ImportConflict goalConflict(String id, String label) => ImportConflict(
    type: ImportEntityType.goal,
    id: id,
    mine: const Goal(
      id: 'x',
      name: 'Mine',
      archived: false,
      startDate: '2026-01-01',
    ),
    imported: const Goal(
      id: 'x',
      name: 'Imported',
      archived: false,
      startDate: '2026-01-01',
    ),
    label: label,
  );

  Future<Map<String, ConflictChoice>?> pumpAndPop(
    WidgetTester tester,
    List<ImportConflict> conflicts,
  ) async {
    Map<String, ConflictChoice>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context)
                      .push<Map<String, ConflictChoice>>(
                        MaterialPageRoute(
                          builder: (_) => ImportConflictResolutionScreen(
                            conflicts: conflicts,
                          ),
                        ),
                      );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('renders one card per conflict with specific-entity copy', (
    tester,
  ) async {
    await pumpAndPop(tester, [
      goalConflict('goal-1', 'Goal "Read"'),
      goalConflict('goal-2', 'Goal "Run"'),
    ]);

    expect(find.text('Goal "Read"'), findsOneWidget);
    expect(find.text('Goal "Run"'), findsOneWidget);
  });

  testWidgets(
    'no bulk accept-all control exists anywhere on the screen (UX-DR14)',
    (tester) async {
      await pumpAndPop(tester, [goalConflict('goal-1', 'Goal "Read"')]);

      expect(find.textContaining('Accept All', findRichText: true), findsNothing);
      expect(find.textContaining('Accept all', findRichText: true), findsNothing);
    },
  );

  testWidgets(
    'Finish Import is disabled until every conflict has a decision',
    (tester) async {
      Map<String, ConflictChoice>? result;
      final conflicts = [
        goalConflict('goal-1', 'Goal "Read"'),
        goalConflict('goal-2', 'Goal "Run"'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await Navigator.of(context)
                        .push<Map<String, ConflictChoice>>(
                          MaterialPageRoute(
                            builder: (_) => ImportConflictResolutionScreen(
                              conflicts: conflicts,
                            ),
                          ),
                        );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final finishButtonFinder = find.byKey(
        const Key('import-conflict-finish-button'),
      );
      expect(
        tester.widget<PrimaryButton>(finishButtonFinder).onPressed,
        isNull,
      );

      await tester.tap(
        find.byKey(const Key('goal:goal-1-keep-mine')),
      );
      await tester.pump();
      expect(
        tester.widget<PrimaryButton>(finishButtonFinder).onPressed,
        isNull,
      );

      await tester.tap(
        find.byKey(const Key('goal:goal-2-keep-imported')),
      );
      await tester.pump();
      expect(
        tester.widget<PrimaryButton>(finishButtonFinder).onPressed,
        isNotNull,
      );

      await tester.tap(finishButtonFinder);
      await tester.pumpAndSettle();

      expect(result, {
        'goal:goal-1': ConflictChoice.keepMine,
        'goal:goal-2': ConflictChoice.keepImported,
      });
    },
  );
}
