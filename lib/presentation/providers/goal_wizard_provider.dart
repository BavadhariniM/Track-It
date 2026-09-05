import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/eligible_days_rule.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_version.dart';
import '../../domain/entities/rule_values.dart';

part 'goal_wizard_provider.g.dart';

/// Which sub-kind of Evaluation Period the Schedule step's dropdown offers.
/// Kept as a plain string constant matching [EvaluationPeriod]'s own values,
/// plus one extra local-only key (`_rollingWindowKind`) for the "Rolling
/// window (N days)" option, which [GoalWizardState.encodedEvaluationPeriod]
/// expands into `EvaluationPeriod.rollingWindow(n)` at Save time — the raw
/// N is wizard-local state ([GoalWizardState.rollingWindowDays]), never a
/// second copy of the encoded string.
abstract final class WizardEvaluationPeriodKind {
  static const daily = EvaluationPeriod.daily;
  static const weekly = EvaluationPeriod.weekly;
  static const biweekly = EvaluationPeriod.biweekly;
  static const monthly = EvaluationPeriod.monthly;
  static const quarterly = EvaluationPeriod.quarterly;
  static const yearly = EvaluationPeriod.yearly;
  static const rollingWindow = 'rolling_window';
}

/// The wizard's in-progress answers plus its current step index. Nothing
/// here is written to `GoalService` until Review's Save button (Subtask
/// 1.4) — every field just accumulates local state as Panda moves through
/// the 7 steps.
///
/// This story's Schedule step exposes Evaluation Period (Daily/Weekly/
/// Biweekly/Monthly/Quarterly/Yearly/Rolling-Window) as one axis, and
/// Eligible-Days (via Story 1.4/1.5's `RecurrenceSelector`, reused as-is —
/// including its custom-recurrence variants) as a fully independent second
/// axis, matching how the domain layer actually encodes every one of the
/// 13 worked-example patterns (`EvaluationPeriod.custom` is an unused
/// placeholder per `period_boundary_test.dart` — none of Story 1.5's own
/// tests ever set it). Subtask 4.1's "Custom period selection routes into
/// recurrence sub-selection" is satisfied by the Eligible-Days step always
/// offering the full `RecurrenceSelector`, not by a separate "Custom"
/// Evaluation Period entry.
class GoalWizardState {
  GoalWizardState({
    this.step = 0,
    this.name = '',
    this.description,
    this.category,
    this.trackingType,
    this.evaluationPeriodKind = WizardEvaluationPeriodKind.daily,
    this.rollingWindowDays = 7,
    this.eligibleDaysPattern = const WeekdaySet({1, 2, 3, 4, 5, 6, 7}),
    this.cheatDayQuota = 0,
    this.targetComparison,
    this.targetValueText = '',
    required this.startDate,
    this.endDate,
    this.reminderOptIn = false,
    this.isEditMode = false,
    this.editingGoalId,
    this.versionLockedMessage,
    this.versionLockedDate,
  });

  final int step;

  final String name;
  final String? description;

  /// Story 3.5 Subtask 1.1/1.2: goal-identity metadata, placed on the Name
  /// step alongside `name` — not a scheduling/target axis, so it stays
  /// editable in edit mode even though `name`/`description` don't (see
  /// `NameStep`'s doc comment).
  final String? category;

  /// `null` until Step 2 (Tracking Type) makes a selection.
  final String? trackingType;

  final String evaluationPeriodKind;
  final int rollingWindowDays;
  final EligibleDaysPattern eligibleDaysPattern;

  /// `GoalVersion.cheatDayQuota` — configurable only while
  /// [evaluationPeriodKind] is Daily (Schedule step), since UX-DR16's
  /// "daily-evaluated goal with Cheat Days" pattern is specifically a Daily
  /// concept. Left as-is (not reset) if the user switches away from Daily
  /// and back — no destructive surprise for a value they already set.
  final int cheatDayQuota;

  /// `null` until Step 4 (Target) makes a selection.
  final String? targetComparison;
  final String targetValueText;

  final DateTime startDate;
  final DateTime? endDate;

  final bool reminderOptIn;

  /// Story 2.1 Task 4.3: `true` when this wizard session was opened from
  /// Goal Detail's Edit action (`GoalWizard.loadForEdit`) rather than from
  /// "create a goal." Gates the Name step's read-only rendering (name/
  /// description live on `Goal`, which `editGoalVersion` never touches) and
  /// the Dates step swapping its Start/End date fields for a single
  /// effective-date field.
  final bool isEditMode;

  /// The `Goal.id` being edited; only meaningful when [isEditMode].
  final String? editingGoalId;

  /// Task 4.4: set after a `GoalServiceFailure.versionLocked` rejection —
  /// the exact UX-DR19 copy to show on the Dates step, alongside the
  /// [versionLockedDate] that was rejected. Cleared once Panda picks an
  /// effective date after it (see `GoalWizard.setStartDate`).
  final String? versionLockedMessage;
  final DateTime? versionLockedDate;

  static const totalSteps = 7;

  /// Boolean tracking on a Daily period is evaluated purely by
  /// `GoalLog.completed` (`evaluate.dart`'s `_evaluateDay` boolean branch
  /// never reads `targetComparison`/`targetValue` at all) — so the Target
  /// step collapses to a fixed "done/not done" statement instead of asking
  /// Panda to pick a comparison and number that wouldn't change anything.
  /// Every other combination (Counter at any period, or Boolean at a
  /// period-type other than Daily, which day-counts across the period) does
  /// need a real comparison + value.
  bool get isFixedBooleanDaily =>
      trackingType == TrackingType.boolean &&
      evaluationPeriodKind == WizardEvaluationPeriodKind.daily;

  String get effectiveTargetComparison =>
      isFixedBooleanDaily ? TargetComparison.exactly : (targetComparison ?? '');

  String get effectiveTargetValueText =>
      isFixedBooleanDaily ? '1' : targetValueText;

  /// The encoded `GoalVersion.evaluationPeriod` string Save actually writes.
  String get encodedEvaluationPeriod =>
      evaluationPeriodKind == WizardEvaluationPeriodKind.rollingWindow
      ? EvaluationPeriod.rollingWindow(rollingWindowDays)
      : evaluationPeriodKind;

  /// UX-DR16's first contrasted pattern: a Daily-evaluated goal with a
  /// configured Cheat Day quota — this produces a real day-by-day Streak.
  bool get isDailyCheatDayPattern =>
      evaluationPeriodKind == WizardEvaluationPeriodKind.daily &&
      cheatDayQuota > 0;

  /// UX-DR16's second contrasted pattern: a Weekly-evaluated count goal
  /// (At Least/Exactly N times a week) — this produces a single week-level
  /// pass/fail, never a daily Streak.
  bool get isWeeklyCountPattern =>
      evaluationPeriodKind == WizardEvaluationPeriodKind.weekly &&
      (targetComparison == TargetComparison.atLeast ||
          targetComparison == TargetComparison.exactly);

  /// The Schedule step's trigger: broader than the Target step's, since
  /// Target Comparison isn't chosen yet at this point in the flow (Schedule
  /// precedes Target, per the fixed step order) — surfaced proactively for
  /// either of the two period types the distinction concerns, "right after
  /// Evaluation Period is chosen" per the story's Subtask 4.3.
  bool get scheduleStepShowsStreakBanner =>
      evaluationPeriodKind == WizardEvaluationPeriodKind.daily ||
      evaluationPeriodKind == WizardEvaluationPeriodKind.weekly;

  /// The Target step's trigger: the precise contrasted-pattern condition,
  /// now that Target Comparison is known too — reinforces the Schedule
  /// step's broader warning with the fully-resolved configuration.
  bool get targetStepShowsStreakBanner =>
      isDailyCheatDayPattern || isWeeklyCountPattern;

  bool get nameStepValid => name.trim().isNotEmpty;

  bool get trackingTypeStepValid => trackingType != null;

  bool get scheduleStepValid {
    if (evaluationPeriodKind == WizardEvaluationPeriodKind.rollingWindow &&
        rollingWindowDays < 1) {
      return false;
    }
    return _isEligibleDaysPatternValid(eligibleDaysPattern);
  }

  bool get targetStepValid {
    if (isFixedBooleanDaily) return true;
    if (targetComparison == null) return false;
    final parsed = double.tryParse(targetValueText);
    return parsed != null && parsed >= 0;
  }

  /// In edit mode there is no end date to validate (Task 4.3 — the Dates
  /// step shows only an effective-date field); the only constraint is
  /// Task 4.4's "require a later date before Save re-enables" after a
  /// `versionLocked` rejection.
  bool get datesStepValid {
    if (isEditMode) return effectiveDateClearsLock;
    final end = endDate;
    if (end == null) return true;
    return !end.isBefore(startDate);
  }

  /// `true` once Panda has picked an effective date after the one a
  /// `versionLocked` rejection was reported against (or no rejection is
  /// pending). Folded into [datesStepValid] so both the Dates step's own
  /// Next button and [reviewStepValid] (and therefore Review's Save button)
  /// disable together, the same pattern every other step already uses.
  bool get effectiveDateClearsLock =>
      versionLockedDate == null || startDate.isAfter(versionLockedDate!);

  bool get remindersStepValid => true;

  bool get reviewStepValid =>
      nameStepValid &&
      trackingTypeStepValid &&
      scheduleStepValid &&
      targetStepValid &&
      datesStepValid &&
      remindersStepValid;

  bool isStepValid(int step) {
    return switch (step) {
      0 => nameStepValid,
      1 => trackingTypeStepValid,
      2 => scheduleStepValid,
      3 => targetStepValid,
      4 => datesStepValid,
      5 => remindersStepValid,
      6 => reviewStepValid,
      _ => false,
    };
  }

  GoalWizardState copyWith({
    int? step,
    String? name,
    String? description,
    String? category,
    bool clearCategory = false,
    String? trackingType,
    bool clearTrackingType = false,
    String? evaluationPeriodKind,
    int? rollingWindowDays,
    EligibleDaysPattern? eligibleDaysPattern,
    int? cheatDayQuota,
    String? targetComparison,
    bool clearTargetComparison = false,
    String? targetValueText,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? reminderOptIn,
    bool? isEditMode,
    String? editingGoalId,
    String? versionLockedMessage,
    DateTime? versionLockedDate,
    bool clearVersionLock = false,
  }) {
    return GoalWizardState(
      step: step ?? this.step,
      name: name ?? this.name,
      description: description ?? this.description,
      category: clearCategory ? null : (category ?? this.category),
      trackingType: clearTrackingType
          ? null
          : (trackingType ?? this.trackingType),
      evaluationPeriodKind: evaluationPeriodKind ?? this.evaluationPeriodKind,
      rollingWindowDays: rollingWindowDays ?? this.rollingWindowDays,
      eligibleDaysPattern: eligibleDaysPattern ?? this.eligibleDaysPattern,
      cheatDayQuota: cheatDayQuota ?? this.cheatDayQuota,
      targetComparison: clearTargetComparison
          ? null
          : (targetComparison ?? this.targetComparison),
      targetValueText: targetValueText ?? this.targetValueText,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      reminderOptIn: reminderOptIn ?? this.reminderOptIn,
      isEditMode: isEditMode ?? this.isEditMode,
      editingGoalId: editingGoalId ?? this.editingGoalId,
      versionLockedMessage: clearVersionLock
          ? null
          : (versionLockedMessage ?? this.versionLockedMessage),
      versionLockedDate: clearVersionLock
          ? null
          : (versionLockedDate ?? this.versionLockedDate),
    );
  }
}

bool _isEligibleDaysPatternValid(EligibleDaysPattern pattern) {
  return switch (pattern) {
    WeekdaySet(weekdays: final weekdays) => weekdays.isNotEmpty,
    EveryNDays(n: final n) => n >= 1,
    EveryNWeeks(n: final n, weekdays: final weekdays) =>
      n >= 1 && weekdays.isNotEmpty,
    EveryNMonths(n: final n) => n >= 1,
    DayOfMonth(daysOfMonth: final days) => days.isNotEmpty,
    NthWeekdayOfMonth() => true,
    CustomDates(dates: final dates) => dates.isNotEmpty,
  };
}

/// Drives every step's UI (Subtask 1.3): validity of the current step is
/// exposed reactively so Next can enable/disable itself, and editing an
/// earlier answer (e.g. Tracking Type) resets dependent later state
/// (Subtask 1.5, AC #5) rather than leaving stale cached values in place.
/// `keepAlive: true` (Story 2.1 Task 4.3): edit-mode pre-fill is applied by
/// `loadForEdit` synchronously *before* the wizard route is pushed (from
/// `GoalDetailScreen`'s Edit button) — an autoDispose provider can be torn
/// down in the gap between that call and the new screen's first `watch`,
/// since nothing holds a listener across the navigation. Both entry points
/// (`DayViewScreen`'s "Create Goal" and `GoalDetailScreen`'s "Edit") fully
/// initialize the state they need before pushing, so nothing relies on the
/// *previous* session having cleaned up after itself on exit.
@Riverpod(keepAlive: true)
class GoalWizard extends _$GoalWizard {
  @override
  GoalWizardState build() => GoalWizardState(startDate: _today());

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setName(String value) => state = state.copyWith(name: value);

  void setDescription(String value) =>
      state = state.copyWith(description: value);

  /// Story 3.5 Subtask 1.1/1.2: an empty/whitespace-only [value] clears the
  /// category back to "no category" rather than storing an empty string.
  void setCategory(String value) {
    final trimmed = value.trim();
    state = state.copyWith(
      category: trimmed.isEmpty ? null : trimmed,
      clearCategory: trimmed.isEmpty,
    );
  }

  /// Changing Tracking Type resets the Target step's comparison/value
  /// (AC #5): a value entered for the previous Tracking Type may no longer
  /// make sense (e.g. a Boolean-Daily goal has no real comparison/value at
  /// all — see [GoalWizardState.isFixedBooleanDaily] — so a stale Counter
  /// value must not silently survive the switch), forcing Panda to
  /// re-confirm the Target step rather than trusting cached state.
  void setTrackingType(String value) => state = state.copyWith(
    trackingType: value,
    clearTargetComparison: true,
    targetValueText: '',
  );

  void setEvaluationPeriodKind(String value) =>
      state = state.copyWith(evaluationPeriodKind: value);

  void setRollingWindowDays(int value) =>
      state = state.copyWith(rollingWindowDays: value);

  void setEligibleDaysPattern(EligibleDaysPattern value) =>
      state = state.copyWith(eligibleDaysPattern: value);

  void setCheatDayQuota(int value) =>
      state = state.copyWith(cheatDayQuota: value < 0 ? 0 : value);

  void setTargetComparison(String value) =>
      state = state.copyWith(targetComparison: value);

  void setTargetValueText(String value) =>
      state = state.copyWith(targetValueText: value);

  /// Task 4.4: picking a new effective date after a `versionLocked`
  /// rejection's date clears that rejection (so the inline message
  /// disappears and Save re-enables) — anything else leaves it in place.
  void setStartDate(DateTime value) {
    final clears =
        state.versionLockedDate != null &&
        value.isAfter(state.versionLockedDate!);
    state = state.copyWith(startDate: value, clearVersionLock: clears);
  }

  void setEndDate(DateTime? value) =>
      state = state.copyWith(endDate: value, clearEndDate: value == null);

  void setReminderOptIn(bool value) =>
      state = state.copyWith(reminderOptIn: value);

  /// Back is always enabled (Subtask 1.3) — the wizard screen itself
  /// decides whether step 0's Back exits the wizard; this only ever moves
  /// within the 7 steps.
  void goBack() {
    if (state.step > 0) state = state.copyWith(step: state.step - 1);
  }

  /// Next only ever advances when the current step actually validates —
  /// mirrored by the UI disabling the Next button, but re-checked here too
  /// so nothing but a valid step can ever move the wizard forward.
  void goNext() {
    if (state.step < GoalWizardState.totalSteps - 1 &&
        state.isStepValid(state.step)) {
      state = state.copyWith(step: state.step + 1);
    }
  }

  void reset() => state = GoalWizardState(startDate: _today());

  /// Story 2.1 Task 4.3: opens the wizard in edit mode, pre-filled from
  /// [goal]'s current (latest) [version] — the counterpart to [reset]'s
  /// fresh-create state. The effective-date field (Dates step, in edit
  /// mode) defaults to today per the story's AC, not [version]'s own
  /// `versionStartDate`; [editGoalVersion]'s collision algorithm decides
  /// what "today" actually does to the data (insert/amend/reject).
  void loadForEdit({required Goal goal, required GoalVersion version}) {
    final isRolling = EvaluationPeriod.isRollingWindow(
      version.evaluationPeriod,
    );
    state = GoalWizardState(
      startDate: _today(),
      isEditMode: true,
      editingGoalId: goal.id,
      name: goal.name,
      description: goal.description,
      category: goal.category,
      trackingType: version.trackingType,
      evaluationPeriodKind: isRolling
          ? WizardEvaluationPeriodKind.rollingWindow
          : version.evaluationPeriod,
      rollingWindowDays: isRolling
          ? EvaluationPeriod.rollingWindowDays(version.evaluationPeriod)
          : 7,
      eligibleDaysPattern: EligibleDaysPattern.decode(version.eligibleDaysRule),
      cheatDayQuota: version.cheatDayQuota,
      targetComparison: version.targetComparison,
      targetValueText: version.targetValue,
    );
  }

  /// Task 4.4: routes a `GoalServiceFailure.versionLocked` rejection back to
  /// the Dates step with its specific UX-DR19 message, and records the
  /// rejected date so [GoalWizardState.effectiveDateClearsLock] can gate
  /// Save until Panda picks a later one.
  void reportVersionLocked(String message, DateTime attemptedDate) {
    state = state.copyWith(
      step: 4,
      versionLockedMessage: message,
      versionLockedDate: attemptedDate,
    );
  }
}
