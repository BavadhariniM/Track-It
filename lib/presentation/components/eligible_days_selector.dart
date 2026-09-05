import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'weekday_chips.dart';

/// Preset chips (Every day / Workdays / Weekends) plus [WeekdayChips]'s
/// arbitrary weekday picker — both write to the same `Set<int>` (ISO
/// weekdays, Mon=1..Sun=7). Selecting a preset visibly toggles the
/// corresponding day chips, making it transparent to the user that presets
/// are the same mechanism as picking days individually (FR-8 consequence),
/// not a separate rule type.
class EligibleDaysSelector extends StatelessWidget {
  const EligibleDaysSelector({
    required this.selectedWeekdays,
    required this.onChanged,
    super.key,
  });

  final Set<int> selectedWeekdays;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.s2,
          children: [
            _presetChip('Every day', {1, 2, 3, 4, 5, 6, 7}),
            _presetChip('Workdays', {1, 2, 3, 4, 5}),
            _presetChip('Weekends', {6, 7}),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        WeekdayChips(selectedWeekdays: selectedWeekdays, onChanged: onChanged),
      ],
    );
  }

  Widget _presetChip(String label, Set<int> weekdays) {
    return ChoiceChip(
      label: Text(label),
      selected: setEquals(selectedWeekdays, weekdays),
      onSelected: (_) => onChanged(weekdays),
    );
  }
}
