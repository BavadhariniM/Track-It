/// A wall-clock time of day, independent of any date or timezone — the
/// domain-safe stand-in for Flutter's `TimeOfDay` (which `domain` cannot
/// import per AD-1's zero-Flutter-imports rule).
class TimeOfDayValue {
  const TimeOfDayValue({required this.hour, required this.minute})
    : assert(hour >= 0 && hour <= 23, 'hour must be 0-23'),
      assert(minute >= 0 && minute <= 59, 'minute must be 0-59');

  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is TimeOfDayValue && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
