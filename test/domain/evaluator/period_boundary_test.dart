import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/period_boundary.dart';

void main() {
  group('periodBoundaryFor — Daily', () {
    test('is the day itself', () {
      final boundary = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.daily,
        date: DateTime(2026, 8, 15),
        goalStartDate: DateTime(2026, 8, 1),
      );
      expect(boundary.start, DateTime(2026, 8, 15));
      expect(boundary.end, DateTime(2026, 8, 15));
    });
  });

  group('periodBoundaryFor — Weekly', () {
    test('Monday week-start: a Wednesday resolves to Mon–Sun', () {
      final boundary = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.weekly,
        date: DateTime(2026, 8, 19), // a Wednesday
        goalStartDate: DateTime(2026, 8, 1),
        weekStart: WeekStart.monday,
      );
      expect(boundary.start, DateTime(2026, 8, 17)); // Monday
      expect(boundary.end, DateTime(2026, 8, 23)); // Sunday
    });

    test('Sunday week-start: a Monday resolves to the preceding Sun–Sat', () {
      final boundary = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.weekly,
        date: DateTime(2026, 8, 17), // a Monday
        goalStartDate: DateTime(2026, 8, 1),
        weekStart: WeekStart.sunday,
      );
      expect(boundary.start, DateTime(2026, 8, 16)); // Sunday
      expect(boundary.end, DateTime(2026, 8, 22)); // Saturday
    });
  });

  group('periodBoundaryFor — Biweekly', () {
    test('anchors two-week blocks to the goal start date', () {
      final anchor = DateTime(2026, 8, 1); // a Saturday
      final boundary = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.biweekly,
        date: DateTime(2026, 8, 10),
        goalStartDate: anchor,
      );
      expect(boundary.start, DateTime(2026, 8, 1));
      expect(boundary.end, DateTime(2026, 8, 14));
    });

    test('the following block starts exactly 14 days after the anchor', () {
      final anchor = DateTime(2026, 8, 1);
      final boundary = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.biweekly,
        date: DateTime(2026, 8, 20),
        goalStartDate: anchor,
      );
      expect(boundary.start, DateTime(2026, 8, 15));
      expect(boundary.end, DateTime(2026, 8, 28));
    });
  });

  group('periodBoundaryFor — Monthly', () {
    test('a mid-month date resolves to the full calendar month', () {
      final boundary = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.monthly,
        date: DateTime(2026, 2, 15),
        goalStartDate: DateTime(2026, 1, 1),
      );
      expect(boundary.start, DateTime(2026, 2, 1));
      // 2026 is not a leap year -> February has 28 days.
      expect(boundary.end, DateTime(2026, 2, 28));
    });

    test('December stays within the same year', () {
      final boundary = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.monthly,
        date: DateTime(2026, 12, 31),
        goalStartDate: DateTime(2026, 1, 1),
      );
      expect(boundary.start, DateTime(2026, 12, 1));
      expect(boundary.end, DateTime(2026, 12, 31));
    });
  });

  group('periodBoundaryFor — Quarterly', () {
    test('a date in Q1 resolves to Jan 1 – Mar 31', () {
      final boundary = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.quarterly,
        date: DateTime(2026, 2, 10),
        goalStartDate: DateTime(2026, 1, 1),
      );
      expect(boundary.start, DateTime(2026, 1, 1));
      expect(boundary.end, DateTime(2026, 3, 31));
    });

    test('a date in Q4 resolves to Oct 1 – Dec 31', () {
      final boundary = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.quarterly,
        date: DateTime(2026, 11, 5),
        goalStartDate: DateTime(2026, 1, 1),
      );
      expect(boundary.start, DateTime(2026, 10, 1));
      expect(boundary.end, DateTime(2026, 12, 31));
    });
  });

  group('periodBoundaryFor — Yearly', () {
    test('resolves to Jan 1 – Dec 31 of the same year', () {
      final boundary = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.yearly,
        date: DateTime(2026, 6, 15),
        goalStartDate: DateTime(2020, 1, 1),
      );
      expect(boundary.start, DateTime(2026, 1, 1));
      expect(boundary.end, DateTime(2026, 12, 31));
    });
  });

  group('periodBoundaryFor — Rolling Window', () {
    test('is always the trailing N days ending on the evaluation date', () {
      final boundary = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.rollingWindow(14),
        date: DateTime(2026, 8, 20),
        goalStartDate: DateTime(2026, 1, 1),
      );
      expect(boundary.start, DateTime(2026, 8, 7));
      expect(boundary.end, DateTime(2026, 8, 20));
    });

    test('the window shifts with the evaluation date, not a fixed range', () {
      final goalStart = DateTime(2026, 1, 1);
      final first = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.rollingWindow(14),
        date: DateTime(2026, 8, 20),
        goalStartDate: goalStart,
      );
      final oneDayLater = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.rollingWindow(14),
        date: DateTime(2026, 8, 21),
        goalStartDate: goalStart,
      );

      expect(oneDayLater.start, first.start.add(const Duration(days: 1)));
      expect(oneDayLater.end, first.end.add(const Duration(days: 1)));
    });

    test(
      'evaluated on the goal\'s first day, the window extends before it',
      () {
        // No special-casing needed: evaluate() naturally finds no governing
        // Version / no logs before the goal existed, contributing 0.
        final boundary = periodBoundaryFor(
          evaluationPeriod: EvaluationPeriod.rollingWindow(14),
          date: DateTime(2026, 1, 1),
          goalStartDate: DateTime(2026, 1, 1),
        );
        expect(boundary.start, DateTime(2025, 12, 19));
        expect(boundary.end, DateTime(2026, 1, 1));
      },
    );
  });

  group('periodBoundaryFor — Custom', () {
    test('is a single-day pass-through placeholder until Story 1.5', () {
      final boundary = periodBoundaryFor(
        evaluationPeriod: EvaluationPeriod.custom,
        date: DateTime(2026, 8, 15),
        goalStartDate: DateTime(2026, 8, 1),
      );
      expect(boundary.start, DateTime(2026, 8, 15));
      expect(boundary.end, DateTime(2026, 8, 15));
    });
  });
}
