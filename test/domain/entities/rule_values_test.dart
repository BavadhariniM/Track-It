import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/rule_values.dart';

void main() {
  group('EligibleDaysRule presets', () {
    test('everyDay makes all 7 ISO weekdays eligible', () {
      for (var weekday = 1; weekday <= 7; weekday++) {
        expect(
          EligibleDaysRule.isEligible(EligibleDaysRule.everyDay, weekday),
          isTrue,
        );
      }
    });

    test('workdays is Mon–Fri only', () {
      for (var weekday = 1; weekday <= 5; weekday++) {
        expect(
          EligibleDaysRule.isEligible(EligibleDaysRule.workdays, weekday),
          isTrue,
        );
      }
      expect(
        EligibleDaysRule.isEligible(EligibleDaysRule.workdays, 6),
        isFalse,
      );
      expect(
        EligibleDaysRule.isEligible(EligibleDaysRule.workdays, 7),
        isFalse,
      );
    });

    test('weekends is Sat–Sun only', () {
      expect(EligibleDaysRule.isEligible(EligibleDaysRule.weekends, 6), isTrue);
      expect(EligibleDaysRule.isEligible(EligibleDaysRule.weekends, 7), isTrue);
      for (var weekday = 1; weekday <= 5; weekday++) {
        expect(
          EligibleDaysRule.isEligible(EligibleDaysRule.weekends, weekday),
          isFalse,
        );
      }
    });
  });

  group('EligibleDaysRule arbitrary selection', () {
    test(
      'an arbitrary subset (Mon/Tue/Thu/Sat) is built and read back exactly',
      () {
        final rule = EligibleDaysRule.fromWeekdays({1, 2, 4, 6});

        expect(EligibleDaysRule.isEligible(rule, 1), isTrue); // Mon
        expect(EligibleDaysRule.isEligible(rule, 2), isTrue); // Tue
        expect(EligibleDaysRule.isEligible(rule, 3), isFalse); // Wed
        expect(EligibleDaysRule.isEligible(rule, 4), isTrue); // Thu
        expect(EligibleDaysRule.isEligible(rule, 5), isFalse); // Fri
        expect(EligibleDaysRule.isEligible(rule, 6), isTrue); // Sat
        expect(EligibleDaysRule.isEligible(rule, 7), isFalse); // Sun
      },
    );

    test(
      'presets are themselves built via the same fromWeekdays mechanism',
      () {
        expect(
          EligibleDaysRule.fromWeekdays({1, 2, 3, 4, 5}),
          EligibleDaysRule.workdays,
        );
        expect(
          EligibleDaysRule.fromWeekdays({6, 7}),
          EligibleDaysRule.weekends,
        );
      },
    );
  });
}
