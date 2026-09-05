import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/time_of_day_value.dart';

void main() {
  test('two values with the same hour/minute are equal', () {
    expect(
      const TimeOfDayValue(hour: 7, minute: 30),
      const TimeOfDayValue(hour: 7, minute: 30),
    );
  });

  test('toString zero-pads to HH:mm', () {
    expect(const TimeOfDayValue(hour: 7, minute: 5).toString(), '07:05');
    expect(const TimeOfDayValue(hour: 20, minute: 15).toString(), '20:15');
  });
}
