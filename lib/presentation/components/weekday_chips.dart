import 'package:flutter/material.dart';

/// A row of 7 toggleable weekday chips (ISO weekdays, Mon=1..Sun=7).
/// Extracted so both [EligibleDaysSelector] (Story 1.4) and the custom
/// recurrence pickers (Story 1.5, e.g. "every N weeks on Mon/Wed/Fri")
/// share the one weekday-picking control rather than duplicating it.
class WeekdayChips extends StatelessWidget {
  const WeekdayChips({
    required this.selectedWeekdays,
    required this.onChanged,
    super.key,
  });

  final Set<int> selectedWeekdays;
  final ValueChanged<Set<int>> onChanged;

  static const _dayLabels = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final entry in _dayLabels.entries)
          FilterChip(
            label: Text(entry.value),
            selected: selectedWeekdays.contains(entry.key),
            onSelected: (isSelected) {
              final next = Set<int>.from(selectedWeekdays);
              if (isSelected) {
                next.add(entry.key);
              } else {
                next.remove(entry.key);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}
