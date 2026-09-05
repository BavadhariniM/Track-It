import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/eligible_days_rule.dart';

void main() {
  group('EveryNDays', () {
    test('N=3 anchored to Jan 1 is eligible on Jan 1, 4, 7, 10…', () {
      final anchor = DateTime(2026, 1, 1);
      final rule = EveryNDays(3);

      for (final day in [1, 4, 7, 10]) {
        expect(
          rule.isEligible(date: DateTime(2026, 1, day), goalStartDate: anchor),
          isTrue,
          reason: 'Jan $day should be eligible',
        );
      }
      for (final day in [2, 3, 5, 6, 8, 9]) {
        expect(
          rule.isEligible(date: DateTime(2026, 1, day), goalStartDate: anchor),
          isFalse,
          reason: 'Jan $day should not be eligible',
        );
      }
    });

    test('the anchor is goalStartDate, unaffected by unrelated rule edits', () {
      // Simulates editing other rule fields (target/period) without
      // touching eligible-days: the caller still passes the same
      // Goal.startDate, never a Version's versionStartDate, so the cycle
      // does not move (FR-9).
      final anchor = DateTime(2026, 1, 1);
      final rule = EveryNDays(3);
      final laterVersionStartDate = DateTime(2026, 6, 15); // irrelevant here

      expect(
        rule.isEligible(date: DateTime(2026, 1, 10), goalStartDate: anchor),
        isTrue,
      );
      // Using the (wrong) versionStartDate as the anchor would shift the
      // cycle; using goalStartDate must not.
      expect(
        rule.isEligible(
          date: DateTime(2026, 1, 10),
          goalStartDate: laterVersionStartDate,
        ),
        isFalse,
        reason: 'proves the two anchors genuinely differ if swapped',
      );
    });

    test('encode/decode round-trips', () {
      final decoded = EligibleDaysPattern.decode(const EveryNDays(3).encode());
      expect(decoded, isA<EveryNDays>());
      expect((decoded as EveryNDays).n, 3);
    });
  });

  group('EveryNWeeks', () {
    test('every 2 weeks on Mon/Wed/Fri, anchored to the start week', () {
      final anchor = DateTime(2026, 8, 3); // a Monday
      final rule = EveryNWeeks(2, {1, 3, 5});

      // Same (anchor) week: Mon/Wed/Fri eligible.
      expect(
        rule.isEligible(date: DateTime(2026, 8, 3), goalStartDate: anchor),
        isTrue,
      );
      expect(
        rule.isEligible(date: DateTime(2026, 8, 5), goalStartDate: anchor),
        isTrue,
      );
      expect(
        rule.isEligible(date: DateTime(2026, 8, 7), goalStartDate: anchor),
        isTrue,
      );
      // Same week, Tuesday: not a selected weekday.
      expect(
        rule.isEligible(date: DateTime(2026, 8, 4), goalStartDate: anchor),
        isFalse,
      );
      // Next week (skip week): not eligible even on Monday.
      expect(
        rule.isEligible(date: DateTime(2026, 8, 10), goalStartDate: anchor),
        isFalse,
      );
      // Two weeks later: eligible again on Monday.
      expect(
        rule.isEligible(date: DateTime(2026, 8, 17), goalStartDate: anchor),
        isTrue,
      );
    });
  });

  group('EveryNMonths', () {
    test('every 3 months on the same day-of-month as the anchor', () {
      final anchor = DateTime(2026, 1, 15);
      final rule = EveryNMonths(3);

      expect(
        rule.isEligible(date: DateTime(2026, 1, 15), goalStartDate: anchor),
        isTrue,
      );
      expect(
        rule.isEligible(date: DateTime(2026, 4, 15), goalStartDate: anchor),
        isTrue,
      );
      expect(
        rule.isEligible(date: DateTime(2026, 2, 15), goalStartDate: anchor),
        isFalse,
      );
      expect(
        rule.isEligible(date: DateTime(2026, 4, 14), goalStartDate: anchor),
        isFalse,
      );
    });
  });

  group('NthWeekdayOfMonth', () {
    test(
      '2nd Tuesday is computed per calendar month, not from goalStartDate',
      () {
        final rule = NthWeekdayOfMonth(2, DateTime.tuesday);
        final unrelatedAnchor = DateTime(2020, 1, 1); // deliberately irrelevant

        // August 2026: Aug 4 is a Tuesday (1st), Aug 11 is the 2nd Tuesday.
        expect(
          rule.isEligible(
            date: DateTime(2026, 8, 11),
            goalStartDate: unrelatedAnchor,
          ),
          isTrue,
        );
        expect(
          rule.isEligible(
            date: DateTime(2026, 8, 4),
            goalStartDate: unrelatedAnchor,
          ),
          isFalse,
        );

        // September 2026: Sep 1 is a Tuesday (1st), so the 2nd Tuesday is
        // Sep 8 — a different day-of-month than August's, proving this is
        // computed independently per month rather than via any offset.
        expect(
          rule.isEligible(
            date: DateTime(2026, 9, 8),
            goalStartDate: unrelatedAnchor,
          ),
          isTrue,
        );
        expect(
          rule.isEligible(
            date: DateTime(2026, 9, 1),
            goalStartDate: unrelatedAnchor,
          ),
          isFalse,
        );
      },
    );
  });

  group('DayOfMonth', () {
    test('the 1st and 15th are eligible every month', () {
      final rule = DayOfMonth({1, 15});
      final anchor = DateTime(2026, 1, 1);

      expect(
        rule.isEligible(date: DateTime(2026, 3, 1), goalStartDate: anchor),
        isTrue,
      );
      expect(
        rule.isEligible(date: DateTime(2026, 3, 15), goalStartDate: anchor),
        isTrue,
      );
      expect(
        rule.isEligible(date: DateTime(2026, 3, 2), goalStartDate: anchor),
        isFalse,
      );
    });

    test('day 31 is simply skipped in shorter months, no fallback shift', () {
      final rule = DayOfMonth({31});
      final anchor = DateTime(2026, 1, 1);

      expect(
        rule.isEligible(date: DateTime(2026, 1, 31), goalStartDate: anchor),
        isTrue,
      );
      // April has 30 days — no date in April ever satisfies day == 31.
      expect(
        rule.isEligible(date: DateTime(2026, 4, 30), goalStartDate: anchor),
        isFalse,
      );
      // February (28 days in 2026) likewise has no eligible date at all.
      expect(
        rule.isEligible(date: DateTime(2026, 2, 28), goalStartDate: anchor),
        isFalse,
      );
    });
  });

  group('CustomDates', () {
    test('only the explicitly selected dates are eligible', () {
      final rule = CustomDates({'2026-08-01', '2026-12-25'});
      final anchor = DateTime(2026, 1, 1);

      expect(
        rule.isEligible(date: DateTime(2026, 8, 1), goalStartDate: anchor),
        isTrue,
      );
      expect(
        rule.isEligible(date: DateTime(2026, 12, 25), goalStartDate: anchor),
        isTrue,
      );
      expect(
        rule.isEligible(date: DateTime(2026, 8, 2), goalStartDate: anchor),
        isFalse,
      );
    });
  });

  group('EligibleDaysPattern.decode backward compatibility', () {
    test(
      'an unprefixed CSV string still decodes as WeekdaySet (Story 1.4)',
      () {
        final decoded = EligibleDaysPattern.decode('1,2,3,4,5');
        expect(decoded, isA<WeekdaySet>());
        expect((decoded as WeekdaySet).weekdays, {1, 2, 3, 4, 5});
      },
    );
  });
}
