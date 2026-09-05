import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/presentation/components/eligible_days_selector.dart';

void main() {
  Widget buildSelector(Set<int> selected, ValueChanged<Set<int>> onChanged) {
    return MaterialApp(
      home: Scaffold(
        body: EligibleDaysSelector(
          selectedWeekdays: selected,
          onChanged: onChanged,
        ),
      ),
    );
  }

  testWidgets(
    'selecting Workdays checks Mon–Fri and leaves Sat/Sun unchecked',
    (tester) async {
      Set<int>? result;
      await tester.pumpWidget(
        buildSelector({1, 2, 3, 4, 5, 6, 7}, (weekdays) => result = weekdays),
      );

      await tester.tap(find.text('Workdays'));
      await tester.pump();

      expect(result, {1, 2, 3, 4, 5});
    },
  );

  testWidgets(
    'toggling an individual day after a preset mutates the same underlying set',
    (tester) async {
      Set<int> current = {1, 2, 3, 4, 5};
      Set<int>? result;
      await tester.pumpWidget(
        buildSelector(current, (weekdays) => result = weekdays),
      );

      // Untoggle Friday (weekday 5) individually.
      await tester.tap(find.text('Fri'));
      await tester.pump();

      expect(result, {1, 2, 3, 4});
    },
  );
}
