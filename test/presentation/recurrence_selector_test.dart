import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/eligible_days_rule.dart';
import 'package:tracker/presentation/components/recurrence_selector.dart';

void main() {
  testWidgets('defaults to Days of the week / every-day', (tester) async {
    EligibleDaysPattern? emitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecurrenceSelector(onChanged: (pattern) => emitted = pattern),
        ),
      ),
    );

    expect(emitted, isA<WeekdaySet>());
    expect((emitted as WeekdaySet).weekdays, {1, 2, 3, 4, 5, 6, 7});
  });

  testWidgets('switching to Every N days and entering N emits EveryNDays', (
    tester,
  ) async {
    EligibleDaysPattern? emitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecurrenceSelector(onChanged: (pattern) => emitted = pattern),
        ),
      ),
    );

    await tester.tap(find.text('Days of the week'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Every N days').last);
    await tester.pumpAndSettle();

    expect(emitted, isA<EveryNDays>());

    await tester.enterText(find.byType(TextField), '3');
    await tester.pump();

    expect((emitted as EveryNDays).n, 3);
  });

  testWidgets('switching to Nth weekday of month emits NthWeekdayOfMonth', (
    tester,
  ) async {
    EligibleDaysPattern? emitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecurrenceSelector(onChanged: (pattern) => emitted = pattern),
        ),
      ),
    );

    await tester.tap(find.text('Days of the week'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nth weekday of month').last);
    await tester.pumpAndSettle();

    expect(emitted, isA<NthWeekdayOfMonth>());
    expect((emitted as NthWeekdayOfMonth).nth, 1);
    expect((emitted as NthWeekdayOfMonth).weekday, 1);
  });
}
