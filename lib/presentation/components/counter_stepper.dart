import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/goal.dart';
import '../../domain/evaluator/date_format.dart';
import '../../domain/evaluator/evaluate.dart';
import '../providers/goal_data_providers.dart';
import '../providers/goal_service_provider.dart';
import '../providers/in_flight_edit_provider.dart';
import 'design_tokens.dart';

/// Hosts [CounterStepper] over a live `evaluate()` recomputation, so the
/// displayed total updates from the persisted value after every +/−/direct
/// entry tap rather than from local widget state (AD-4, Story 1.2
/// Subtask 3.1). Shared by Day View and Today (Bug 8) so both open the exact
/// same dialog.
class CounterStepperDialog extends ConsumerWidget {
  const CounterStepperDialog({required this.goal, required this.date, super.key});

  final Goal goal;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versions = ref.watch(goalVersionsProvider(goal.id)).value ?? const [];
    final logs = ref.watch(goalLogsProvider(goal.id)).value ?? const [];
    final dayStatus = evaluate(
      goal: goal,
      versions: versions,
      logs: logs,
      date: date,
    );

    return AlertDialog(
      title: Text(goal.name),
      content: CounterStepper(
        currentValue: dayStatus.currentValue ?? 0,
        goalId: goal.id,
        date: formatDateOnly(date),
        onDelta: (delta) {
          ref
              .read(goalServiceProvider)
              .logCounter(
                goalId: goal.id,
                date: formatDateOnly(date),
                delta: delta,
              );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// A −/+ stepper for quick Counter increments, plus a tappable direct-entry
/// field for decimals/negative corrections — both routing through the same
/// [onDelta] callback (`GoalService.logCounter`'s delta parameter). There is
/// no separate "correction mode": a negative correction is just a negative
/// delta through this same control (EXPERIENCE.md Component Patterns).
///
/// [goalId]/[date] are the exact target this stepper edits, captured
/// explicitly by the caller (Subtask 1.3) — the direct-entry dialog below
/// registers itself against this exact date while open, so a
/// midnight-rollover auto-commit (Story 1.11 Task 1) always lands on the
/// day the entry was actually made against, never "today" resolved fresh.
class CounterStepper extends ConsumerWidget {
  const CounterStepper({
    required this.currentValue,
    required this.onDelta,
    required this.goalId,
    required this.date,
    super.key,
  });

  final double currentValue;
  final ValueChanged<double> onDelta;
  final String goalId;
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => onDelta(-1),
          icon: const Icon(Icons.remove),
          tooltip: 'Decrease by 1',
        ),
        SizedBox(
          width: 48,
          child: Text(
            formatNumeric(currentValue),
            textAlign: TextAlign.center,
            style: AppTypography.numeric(colors.textPrimary),
          ),
        ),
        IconButton(
          onPressed: () => onDelta(1),
          icon: const Icon(Icons.add),
          tooltip: 'Increase by 1',
        ),
        IconButton(
          onPressed: () => _promptDirectEntry(context, ref),
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Enter an amount',
        ),
      ],
    );
  }

  Future<void> _promptDirectEntry(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final notifier = ref.read(inFlightEditProvider.notifier);
    notifier.start(goalId: goalId, date: date);
    controller.addListener(() => notifier.updateText(controller.text));

    double? delta;
    try {
      delta = await showDialog<double>(
        context: context,
        builder: (dialogContext) => _DirectEntryDialog(controller: controller),
      );
    } finally {
      // Only clear if this is still *our* registration — a midnight
      // rollover may have already auto-committed and cleared it out from
      // under us (Subtask 1.2), in which case there's nothing left to undo
      // here.
      final current = ref.read(inFlightEditProvider);
      if (current != null && current.goalId == goalId && current.date == date) {
        notifier.clear();
      }
      // Deliberately not disposed here: `showDialog`'s Future resolves as
      // soon as the route is popped, before its exit transition finishes
      // animating the still-mounted `TextField` off-screen over
      // subsequent frames — disposing this controller immediately would
      // race that animation ("A TextEditingController was used after
      // being disposed."). Matches this control's pre-Story-1.11
      // behavior, which never disposed it either.
    }

    if (delta != null) {
      onDelta(delta);
    }
  }
}

/// The direct-entry dialog's content, split out so it can watch
/// [inFlightEditProvider] itself: if the midnight-rollover watcher
/// auto-commits and clears this edit while the dialog is still open, the
/// dialog closes itself silently (UX-DR21 — no interstitial/toast) rather
/// than leaving a stale editor open for a day that's no longer "now".
class _DirectEntryDialog extends ConsumerWidget {
  const _DirectEntryDialog({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(inFlightEditProvider, (previous, next) {
      if (previous != null && next == null) {
        Navigator.of(context).pop();
      }
    });

    return AlertDialog(
      title: const Text('Log an amount'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: const InputDecoration(hintText: 'e.g. 7.5 or -2'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(double.tryParse(controller.text));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
