import 'package:flutter/material.dart';

import '../../domain/entities/eligible_days_rule.dart';
import 'design_tokens.dart';
import 'eligible_days_selector.dart';
import 'weekday_chips.dart';

/// Which [EligibleDaysPattern] variant the user is currently configuring.
enum RecurrenceKind {
  daysOfWeek,
  everyNDays,
  everyNWeeks,
  everyNMonths,
  dayOfMonth,
  nthWeekday,
  customDates,
}

/// Picks a [RecurrenceKind] and renders that variant's input controls,
/// producing an [EligibleDaysPattern] via [onChanged]. Extends Story 1.4's
/// [EligibleDaysSelector] with Story 1.5's custom recurrence variants —
/// the underlying input controls Story 1.9's guided wizard will eventually
/// sequence into steps, not a parallel evaluation concept.
class RecurrenceSelector extends StatefulWidget {
  const RecurrenceSelector({
    required this.onChanged,
    this.initialPattern,
    super.key,
  });

  final ValueChanged<EligibleDaysPattern> onChanged;

  /// Story 2.1 Task 4.3: pre-fills the selector from an existing goal's
  /// current Version when the wizard opens in edit mode. `null` (every
  /// create-mode call site) preserves the original "Days of the week, all
  /// seven checked" default exactly as before.
  final EligibleDaysPattern? initialPattern;

  @override
  State<RecurrenceSelector> createState() => _RecurrenceSelectorState();
}

class _RecurrenceSelectorState extends State<RecurrenceSelector> {
  late RecurrenceKind _kind;

  late Set<int> _weekdays;
  late final TextEditingController _everyNController;
  late Set<int> _everyNWeeksWeekdays;
  late final TextEditingController _dayOfMonthController;
  late int _nth;
  late int _nthWeekday;
  late final TextEditingController _customDatesController;

  @override
  void initState() {
    super.initState();
    final pattern = widget.initialPattern;
    _kind = _kindFor(pattern);
    _weekdays = pattern is WeekdaySet
        ? pattern.weekdays
        : {1, 2, 3, 4, 5, 6, 7};
    _everyNController = TextEditingController(text: '${_initialN(pattern)}');
    _everyNWeeksWeekdays = pattern is EveryNWeeks ? pattern.weekdays : {1};
    _dayOfMonthController = TextEditingController(
      text: pattern is DayOfMonth
          ? (pattern.daysOfMonth.toList()..sort()).join(',')
          : '1,15',
    );
    _nth = pattern is NthWeekdayOfMonth ? pattern.nth : 1;
    _nthWeekday = pattern is NthWeekdayOfMonth ? pattern.weekday : 1;
    _customDatesController = TextEditingController(
      text: pattern is CustomDates ? pattern.dates.join(',') : '',
    );
    // Deferred: IndexedStack mounts every wizard step on the first frame,
    // so this runs during the build phase. Emitting synchronously here
    // would mutate the wizard's provider mid-build, which Riverpod
    // forbids — so the initial default is reported one frame later.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emit();
    });
  }

  static RecurrenceKind _kindFor(EligibleDaysPattern? pattern) =>
      switch (pattern) {
        null || WeekdaySet() => RecurrenceKind.daysOfWeek,
        EveryNDays() => RecurrenceKind.everyNDays,
        EveryNWeeks() => RecurrenceKind.everyNWeeks,
        EveryNMonths() => RecurrenceKind.everyNMonths,
        DayOfMonth() => RecurrenceKind.dayOfMonth,
        NthWeekdayOfMonth() => RecurrenceKind.nthWeekday,
        CustomDates() => RecurrenceKind.customDates,
      };

  static int _initialN(EligibleDaysPattern? pattern) => switch (pattern) {
    EveryNDays(n: final n) => n,
    EveryNWeeks(n: final n) => n,
    EveryNMonths(n: final n) => n,
    _ => 2,
  };

  @override
  void dispose() {
    _everyNController.dispose();
    _dayOfMonthController.dispose();
    _customDatesController.dispose();
    super.dispose();
  }

  void _emit() {
    final EligibleDaysPattern pattern = switch (_kind) {
      RecurrenceKind.daysOfWeek => WeekdaySet(_weekdays),
      RecurrenceKind.everyNDays => EveryNDays(
        int.tryParse(_everyNController.text) ?? 1,
      ),
      RecurrenceKind.everyNWeeks => EveryNWeeks(
        int.tryParse(_everyNController.text) ?? 1,
        _everyNWeeksWeekdays,
      ),
      RecurrenceKind.everyNMonths => EveryNMonths(
        int.tryParse(_everyNController.text) ?? 1,
      ),
      RecurrenceKind.dayOfMonth => DayOfMonth(
        _dayOfMonthController.text
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .toSet(),
      ),
      RecurrenceKind.nthWeekday => NthWeekdayOfMonth(_nth, _nthWeekday),
      RecurrenceKind.customDates => CustomDates(
        _customDatesController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet(),
      ),
    };
    widget.onChanged(pattern);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<RecurrenceKind>(
          value: _kind,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: RecurrenceKind.daysOfWeek,
              child: Text('Days of the week'),
            ),
            DropdownMenuItem(
              value: RecurrenceKind.everyNDays,
              child: Text('Every N days'),
            ),
            DropdownMenuItem(
              value: RecurrenceKind.everyNWeeks,
              child: Text('Every N weeks, on specific weekdays'),
            ),
            DropdownMenuItem(
              value: RecurrenceKind.everyNMonths,
              child: Text('Every N months'),
            ),
            DropdownMenuItem(
              value: RecurrenceKind.dayOfMonth,
              child: Text('Specific day(s) of month'),
            ),
            DropdownMenuItem(
              value: RecurrenceKind.nthWeekday,
              child: Text('Nth weekday of month'),
            ),
            DropdownMenuItem(
              value: RecurrenceKind.customDates,
              child: Text('Specific dates'),
            ),
          ],
          onChanged: (kind) {
            if (kind == null) return;
            setState(() => _kind = kind);
            _emit();
          },
        ),
        const SizedBox(height: AppSpacing.s3),
        _bodyFor(_kind),
      ],
    );
  }

  Widget _bodyFor(RecurrenceKind kind) {
    switch (kind) {
      case RecurrenceKind.daysOfWeek:
        return EligibleDaysSelector(
          selectedWeekdays: _weekdays,
          onChanged: (weekdays) {
            setState(() => _weekdays = weekdays);
            _emit();
          },
        );
      case RecurrenceKind.everyNDays:
      case RecurrenceKind.everyNMonths:
        return _nField(
          label: kind == RecurrenceKind.everyNDays ? 'N (days)' : 'N (months)',
        );
      case RecurrenceKind.everyNWeeks:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _nField(label: 'N (weeks)'),
            const SizedBox(height: AppSpacing.s3),
            WeekdayChips(
              selectedWeekdays: _everyNWeeksWeekdays,
              onChanged: (weekdays) {
                setState(() => _everyNWeeksWeekdays = weekdays);
                _emit();
              },
            ),
          ],
        );
      case RecurrenceKind.dayOfMonth:
        return TextField(
          controller: _dayOfMonthController,
          decoration: const InputDecoration(
            labelText: 'Day(s) of month',
            hintText: 'e.g. 1,15',
          ),
          onChanged: (_) => _emit(),
        );
      case RecurrenceKind.nthWeekday:
        return Row(
          children: [
            Expanded(
              child: DropdownButton<int>(
                value: _nth,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1st')),
                  DropdownMenuItem(value: 2, child: Text('2nd')),
                  DropdownMenuItem(value: 3, child: Text('3rd')),
                  DropdownMenuItem(value: 4, child: Text('4th')),
                  DropdownMenuItem(value: 5, child: Text('5th')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _nth = value);
                  _emit();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: DropdownButton<int>(
                value: _nthWeekday,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Monday')),
                  DropdownMenuItem(value: 2, child: Text('Tuesday')),
                  DropdownMenuItem(value: 3, child: Text('Wednesday')),
                  DropdownMenuItem(value: 4, child: Text('Thursday')),
                  DropdownMenuItem(value: 5, child: Text('Friday')),
                  DropdownMenuItem(value: 6, child: Text('Saturday')),
                  DropdownMenuItem(value: 7, child: Text('Sunday')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _nthWeekday = value);
                  _emit();
                },
              ),
            ),
          ],
        );
      case RecurrenceKind.customDates:
        return TextField(
          controller: _customDatesController,
          decoration: const InputDecoration(
            labelText: 'Dates',
            hintText: 'e.g. 2026-08-01,2026-12-25',
          ),
          onChanged: (_) => _emit(),
        );
    }
  }

  Widget _nField({required String label}) {
    return TextField(
      controller: _everyNController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => _emit(),
    );
  }
}
