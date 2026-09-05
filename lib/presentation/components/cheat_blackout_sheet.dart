import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/day_status.dart';
import '../../domain/entities/goal.dart';
import '../../domain/evaluator/date_format.dart';
import '../../domain/evaluator/evaluate.dart';
import '../../domain/services/goal_service_result.dart';
import '../providers/goal_data_providers.dart';
import '../providers/goal_service_provider.dart';
import 'design_tokens.dart';
import 'primary_button.dart';

/// The Cheat Day / Blackout Date / DNF bottom sheet (UX-DR13), reached via
/// long-press on a Day View goal row. Story 1.6 built the sheet with the
/// Blackout Date action only; Story 2.4 (AC 5) extended it with the Cheat
/// Day action; Story 2.5 (Task 4.1) extends this same three-action sheet
/// with "Mark DNF" rather than building a fourth surface.
Future<void> showCheatBlackoutSheet({
  required BuildContext context,
  required Goal goal,
  required DateTime date,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => _CheatBlackoutSheet(goal: goal, date: date),
  );
}

class _CheatBlackoutSheet extends ConsumerStatefulWidget {
  const _CheatBlackoutSheet({required this.goal, required this.date});

  final Goal goal;
  final DateTime date;

  @override
  ConsumerState<_CheatBlackoutSheet> createState() =>
      _CheatBlackoutSheetState();
}

class _CheatBlackoutSheetState extends ConsumerState<_CheatBlackoutSheet> {
  final _reasonController = TextEditingController();
  final _cheatNoteController = TextEditingController();
  bool _saving = false;

  /// Story 2.4 AC 4/Task 5.2: the exact `cheatDayQuotaExhausted` copy shown
  /// inline in the sheet itself, not a separate dialog (UX-DR19).
  String? _cheatDayError;

  /// Story 2.5 Task 2.5/UX-DR19: the exact `notEligibleOrAlreadyResolved`
  /// copy, shown inline the same way `_cheatDayError` is — this should be
  /// unreachable in practice since Task 4.1 already hides the "Mark DNF"
  /// action once the day isn't Pending, but the service re-validates
  /// regardless (Task 2.2), so the sheet surfaces whatever it says.
  String? _dnfError;

  @override
  void dispose() {
    _reasonController.dispose();
    _cheatNoteController.dispose();
    super.dispose();
  }

  Future<void> _markBlackout() async {
    setState(() => _saving = true);
    await ref
        .read(goalServiceProvider)
        .markBlackoutDate(
          goalId: widget.goal.id,
          date: formatDateOnly(widget.date),
          reason: _reasonController.text.isEmpty
              ? null
              : _reasonController.text,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _markCheatDay() async {
    setState(() {
      _saving = true;
      _cheatDayError = null;
    });
    final result = await ref
        .read(goalServiceProvider)
        .markCheatDay(
          goalId: widget.goal.id,
          date: formatDateOnly(widget.date),
          note: _cheatNoteController.text.isEmpty
              ? null
              : _cheatNoteController.text,
        );
    if (!mounted) return;
    switch (result) {
      case GoalServiceSuccess<dynamic>():
        Navigator.of(context).pop();
      case GoalServiceFailureResult<dynamic>(:final reason):
        setState(() {
          _saving = false;
          _cheatDayError = reason.message;
        });
    }
  }

  Future<void> _markDnf() async {
    setState(() {
      _saving = true;
      _dnfError = null;
    });
    final result = await ref
        .read(goalServiceProvider)
        .markDnf(goalId: widget.goal.id, date: formatDateOnly(widget.date));
    if (!mounted) return;
    switch (result) {
      case GoalServiceSuccess<dynamic>():
        Navigator.of(context).pop();
      case GoalServiceFailureResult<dynamic>(:final reason):
        setState(() {
          _saving = false;
          _dnfError = reason.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Story 2.5 Task 4.1: "Mark DNF" is only offered while this day
    // currently resolves to Pending — the same `evaluate()` entry point
    // (AD-4) `GoalService.markDnf` re-validates server-side (Task 2.2), so
    // Panda never sees an action the service would just reject.
    final versions = ref.watch(goalVersionsProvider(widget.goal.id)).value;
    final logs = ref.watch(goalLogsProvider(widget.goal.id)).value;
    final blackoutDates = ref
        .watch(blackoutDatesProvider(widget.goal.id))
        .value;
    final cheatDays = ref.watch(cheatDaysProvider(widget.goal.id)).value;
    final now = DateTime.now();
    final isPending =
        versions != null &&
        logs != null &&
        blackoutDates != null &&
        cheatDays != null &&
        evaluate(
              goal: widget.goal,
              versions: versions,
              logs: logs,
              blackoutDates: blackoutDates,
              cheatDays: cheatDays,
              date: widget.date,
              today: DateTime(now.year, now.month, now.day),
            ).status ==
            DayStatusValue.pending;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.s4,
          right: AppSpacing.s4,
          top: AppSpacing.s4,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mark as Blackout Date',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Excluded from failure for this goal — the required count and '
              'eligible-day pool are unchanged.',
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s4),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
            const SizedBox(height: AppSpacing.s4),
            PrimaryButton(
              label: _saving ? 'Saving…' : 'Mark as Blackout Date',
              onPressed: _saving ? null : _markBlackout,
            ),
            const SizedBox(height: AppSpacing.s5),
            Divider(color: colors.borderHairline),
            const SizedBox(height: AppSpacing.s3),
            Text(
              'Mark Cheat Day',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Exempted from failure for this goal, up to its per-period '
              'quota — the required count is not reduced.',
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s4),
            TextField(
              controller: _cheatNoteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            if (_cheatDayError != null) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(_cheatDayError!, style: TextStyle(color: colors.statusFail)),
            ],
            const SizedBox(height: AppSpacing.s4),
            PrimaryButton(
              label: _saving ? 'Saving…' : 'Mark Cheat Day',
              onPressed: _saving ? null : _markCheatDay,
            ),
            // Story 2.5 Task 4.1: offered only while this day is currently
            // Pending — a resolved or non-eligible day never shows this
            // action at all, rather than showing it and letting the
            // service reject it.
            if (isPending) ...[
              const SizedBox(height: AppSpacing.s5),
              Divider(color: colors.borderHairline),
              const SizedBox(height: AppSpacing.s3),
              Text(
                'Mark DNF',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                "A placeholder for \"did not finish\" — shown until this "
                "day's period actually closes, then replaced by whatever "
                'the real computed outcome turns out to be.',
                style: TextStyle(color: colors.textSecondary),
              ),
              if (_dnfError != null) ...[
                const SizedBox(height: AppSpacing.s2),
                Text(_dnfError!, style: TextStyle(color: colors.statusFail)),
              ],
              const SizedBox(height: AppSpacing.s4),
              PrimaryButton(
                label: _saving ? 'Saving…' : 'Mark DNF',
                onPressed: _saving ? null : _markDnf,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
