import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'in_flight_edit_provider.g.dart';

/// An uncommitted Counter direct-entry edit: which goal/day it targets and
/// the raw text currently typed but not yet saved. The target [date] is
/// captured once, explicitly, at the moment the direct-entry dialog opens
/// (Subtask 1.3) — never re-resolved as "today" lazily at commit time — so
/// a midnight-rollover auto-commit (Subtask 1.2) always lands on the day
/// the entry was actually made against, even after the clock has since
/// rolled over.
class InFlightCounterEdit {
  const InFlightCounterEdit({
    required this.goalId,
    required this.date,
    this.text = '',
  });

  final String goalId;
  final String date;
  final String text;

  InFlightCounterEdit copyWith({String? text}) =>
      InFlightCounterEdit(goalId: goalId, date: date, text: text ?? this.text);
}

/// The single Counter direct-entry dialog that may be mid-edit at once —
/// the dialog is modal, so only one can be open at a time. `null` means no
/// uncommitted entry exists right now.
///
/// Presentation-layer-only state (AD-1): `domain` never learns this exists.
/// The midnight-rollover watcher is the only reader that turns this into a
/// `GoalService.logCounter` call, and only ever with the explicit `date`
/// already captured here — it never resolves a fresh "today".
@Riverpod(keepAlive: true)
class InFlightEdit extends _$InFlightEdit {
  @override
  InFlightCounterEdit? build() => null;

  void start({required String goalId, required String date}) {
    state = InFlightCounterEdit(goalId: goalId, date: date);
  }

  void updateText(String text) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(text: text);
  }

  void clear() {
    state = null;
  }
}
