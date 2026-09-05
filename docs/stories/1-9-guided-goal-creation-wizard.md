# Story 1.9: Guided Goal-Creation Wizard

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to create a goal through a guided, one-decision-at-a-time flow instead of one long form,
so that the exotic scheduling surface doesn't overwhelm me and I don't accidentally pick the wrong pattern.

## Acceptance Criteria

1. **Given** goal creation **When** Panda proceeds through the flow **Then** steps appear in the exact order name → tracking type → schedule → target → dates → reminders → review, with a `wizard-progress` bar showing proportional fill and no step numerals shown elsewhere (FR-6, UX-DR9, UX-DR15)
2. **Given** any step's required fields are incomplete **When** Panda taps Next **Then** Next stays disabled until the step validates; Back is always enabled (UX-DR15)
3. **Given** Panda is configuring a "7×/week with 2 cheat days" pattern versus a "5×/week" pattern at the schedule/target steps **When** either is selected **Then** the flow visibly distinguishes that the first produces a real daily Streak and the second a week-level pass/fail with no daily Streak, so the two can't be picked interchangeably by accident (FR-6 consequence, UX-DR16)
4. **Given** all steps are complete **When** Panda reaches Review **Then** the full rule is restated as one plain-language sentence (e.g. "Done at least 3 times a week, workdays only, starting Aug 18") before Save (UX-DR15)
5. **Given** Panda taps Back at any step **When** they change an earlier answer **Then** later steps reflect the change and re-validate before Save becomes available (FR-6)

## Tasks / Subtasks

- [x] Task 1: Wizard shell, navigation, and progress bar (AC: #1, #2)
  - [x] Subtask 1.1: Build `lib/presentation/screens/goal_creation_wizard.dart` as a linear, stateful 7-step flow: name → tracking type → schedule → target → dates → reminders → review — exact order, no step-skipping via tap-ahead (EXPERIENCE.md Interaction Primitives — "Wizard navigation is linear (Back/Next) with no step-skipping via tap-ahead")
  - [x] Subtask 1.2: Build `lib/presentation/components/wizard_progress.dart` implementing the `wizard-progress` token spec exactly: thin top-of-screen bar, `height: 4px`, `radius: rounded.full` (the only other place `rounded.full` is used besides status badges, per UX-DR3), `track: border-hairline`, `fill: accent` — filled proportionally across the 7 steps; no step numerals ("Step 3 of 7") shown anywhere else in the UI (UX-DR9)
  - [x] Subtask 1.3: Wire Next/Back navigation: Back is always enabled at every step (including refusing to disable it even on step 1, where it exits the wizard instead); Next is disabled until the current step's required fields validate — model each step's validation as a pure predicate over that step's current form state, exposed via a Riverpod provider so the UI can reactively enable/disable Next (UX-DR15, AC #2)
  - [x] Subtask 1.4: Persist all step answers in wizard-local state (not yet written to `GoalService`) until the final Save action on the Review step — only Review's Save button actually calls `GoalService.createGoal` (Story 1.1's use-case, now receiving the fully generalized `GoalVersion` fields from Stories 1.2–1.7)
  - [x] Subtask 1.5: Wire Back-then-edit-then-forward behavior (AC #5): changing an earlier step's answer must invalidate/re-validate all later steps' derived state (e.g. changing Tracking Type from Boolean to Counter after already configuring a Boolean-only Target Comparison on the target step must reset or re-validate that step) — implement this by deriving each step's valid-options list from the current wizard state reactively (Riverpod), not by caching stale computed values from a previous pass through the flow
- [x] Task 2: Step 1 — Name (AC: #1, #2)
  - [x] Subtask 2.1: Simple text input for goal name (required) and optional description (`Goal.name`/`description`, Story 1.1 entity fields) — validates on non-empty name
- [x] Task 3: Step 2 — Tracking Type (AC: #1, #2, #3)
  - [x] Subtask 3.1: Boolean vs. Counter selection (`GoalVersion.trackingType`, Stories 1.1/1.2) — validates on a selection being made
- [x] Task 4: Step 3 — Schedule (Evaluation Period + Eligible-Days Rule) (AC: #1, #2, #3)
  - [x] Subtask 4.1: Evaluation Period selection: Daily, Weekly, Biweekly, Monthly, Quarterly, Yearly, Rolling Window (N days), Custom (Story 1.3's period types) — Custom period selection routes into Story 1.5's recurrence-variant sub-selection (every-N-days, every-N-weeks, every-N-months, Nth-weekday-of-month, specific-day-of-month, explicit-custom-dates)
  - [x] Subtask 4.2: Eligible-Days Rule selection: presets (Every day / Workdays / Weekends) and arbitrary weekday toggle (Story 1.4's selector component, reused directly — do not rebuild it)
  - [x] Subtask 4.3: Implement the daily-vs-weekly Streak clarification (AC #3, FR-6 consequence, UX-DR16): when the combination of Evaluation Period + Tracking Type + (upcoming) Target Comparison would produce a "daily-evaluated goal with Cheat Days" pattern (Daily period, e.g. 7×/week eligible with a Cheat Day quota configured — Cheat Day quota configuration is `GoalVersion.cheatDayQuota`, present on the entity since Story 1.1 even though Cheat Day *usage* isn't implemented until Epic 2 Story 2.4) versus a "weekly-evaluated count goal" pattern (Weekly period, e.g. "5×/week"), the schedule/target steps must show explicit, visible copy distinguishing the two — e.g. an inline note: "Daily goals with cheat days track a real day-by-day Streak. Weekly-count goals track a single pass/fail per week, with no daily Streak." This must not be a passive footnote easy to miss; it is a load-bearing UX requirement per UX-DR16's "must not be selectable interchangeably by accident" — surface it prominently whenever the user's current schedule selection could be confused with the other pattern (e.g. right after Evaluation Period is chosen, and again reinforced at the Target step)
  - [x] Subtask 4.4: Blackout Dates (Story 1.6) are not configured during creation in this story's scope — Blackout Dates are marked per-date via the Cheat Day/Blackout sheet from an existing goal's Day View (UX-DR13), not during the creation wizard; do not add a Blackout Date step here, since neither epics.md's Story 1.9 ACs nor UX-DR15's fixed 7-step order include one
- [x] Task 5: Step 4 — Target (Target Comparison + value) (AC: #1, #2, #3)
  - [x] Subtask 5.1: Target Comparison selection: At Least, At Most, Exactly (available for both Boolean and Counter goals per Story 1.7 — no comparison is restricted to one Tracking Type, and there is no Range/bounded option) — validates on a comparison and a single target value being set
  - [x] Subtask 5.2: Reinforce the daily-vs-weekly Streak distinction here too if the Evaluation Period + Target combination is one of the two contrasted patterns (see Task 4.3) — UX-DR16 calls this out at "the schedule/target steps" (plural), not just schedule
  - [x] Subtask 5.3: Apply the `numeric` typography token (Story 1.2's established pattern) to any live numeric target-value input
- [x] Task 6: Step 5 — Dates (AC: #1, #2)
  - [x] Subtask 6.1: Start date (required, defaults to today but user-editable to a past/future date per FR-1's "not necessarily 'today'"), optional end date (`Goal.startDate`, plus an end-date field — confirm whether `Goal` needs an `endDate` field added here; the Story 1.1 entity/ER-diagram did not include one explicitly, so add `Goal.endDate` (nullable ISO-8601 date-only) now, since FR-1 requires "an optional end date (or 'no end date')" and no later Epic 1 story is positioned to add it — flagged as a gap in the ER diagram resolved here, noted below)
  - [x] Subtask 6.2: Validates on start date being present; end date, if set, must be on or after start date
- [x] Task 7: Step 6 — Reminders (AC: #1, #2)
  - [x] Subtask 7.1: This step's actual reminder-scheduling mechanics (Epic 4) are out of scope for Epic 1 — for this story, the step only needs to let Panda opt in/out of the single global reminder time (a simple toggle referencing whatever global reminder-time setting exists or will exist in Settings/Epic 4) without implementing `flutter_local_notifications` scheduling itself; if no global reminder-time setting exists yet, present this step as a simple "remind me" toggle that stores a per-goal opt-in flag (not a new global time — that's Epic 4 Story 4.1's job) and validates trivially (always valid, no required input) so the wizard's 7-step structure is complete now without blocking on Epic 4's delivery
- [x] Task 8: Step 7 — Review (AC: #1, #4, #5)
  - [x] Subtask 8.1: Build the plain-language rule summary sentence generator: composes the wizard's collected answers (name, tracking type, schedule, target, dates) into one sentence, e.g. "Done at least 3 times a week, workdays only, starting Aug 18" (UX-DR15's own example) — this is a presentation-layer string-composition function, not a domain concern; keep it isolated so it's easy to extend as new schedule/target combinations are added
  - [x] Subtask 8.2: Review step's Save button calls `GoalService.createGoal` (extended across Stories 1.1–1.8 to accept the full schedule/target/eligible-days configuration) inside its single Drift transaction — this is the only write in the entire wizard flow
  - [x] Subtask 8.3: After successful save, navigate to the newly created goal's context (e.g. Day View or Dashboard) so Panda sees it appear immediately, consistent with the "Panda sets up an exotic goal" key flow in EXPERIENCE.md ("Panda saves, and the goal immediately appears correctly on today's Dashboard... or as `status-empty`... proving the rule was understood correctly before any log entry exists")
- [x] Task 9: Testing (AC: all)
  - [x] Subtask 9.1: Widget-test the full linear flow end-to-end for at least 2–3 of the 13 worked-example patterns (Story 1.7) — confirming the wizard can actually construct each pattern's exact configuration and that Save produces a correctly-evaluable goal
  - [x] Subtask 9.2: Widget-test Next-disabled-until-valid for each of the 7 steps individually
  - [x] Subtask 9.3: Widget-test Back-always-enabled and the re-validation-after-editing-an-earlier-step behavior (AC #5) — specifically the Tracking-Type-change-invalidates-Target-step scenario
  - [x] Subtask 9.4: Widget-test the daily-vs-weekly Streak clarification copy actually appears and is visually prominent for both contrasted patterns (AC #3) — this is a UX-correctness requirement, not just a functional one, so assert the copy is present and legible, not just that some string exists in the widget tree
  - [x] Subtask 9.5: Widget-test the Review step's plain-language sentence renders correctly for several different configurations

## Dev Notes

- **This story is the UI capstone of Epic 1's domain work (Stories 1.1–1.8) — it does not introduce new evaluation logic.** Every field the wizard collects maps directly onto entities/fields already defined: `Goal.name/description/startDate/(new)endDate`, `GoalVersion.trackingType/evaluationPeriod/eligibleDaysRule/targetComparison/targetValue/cheatDayQuota`. If implementing this story reveals a need for new domain logic (beyond the `Goal.endDate` gap noted below), that is a signal the domain work from an earlier story was incomplete — flag it rather than quietly adding ad hoc logic inside the wizard screen.
- **`Goal.endDate`** is a nullable ISO-8601 date-only column: a specific date means the goal ends on that date; absent/null means indefinite (no end date), per FR-1. The architecture's ER diagram in ARCHITECTURE-SPINE.md's Core-entity relationships section now lists this field explicitly on `GOAL` (confirmed by the user 2026-08-29) — the earlier gap between the ER diagram and FR-1's requirement is resolved. This story is the first and only Epic-1 point that collects it (via the Dates step).
- **UX-DR9 (`wizard-progress`):** exact token values from DESIGN.md: `height: 4px`, `radius: rounded.full`, `track: border-hairline`, `fill: accent`. This is one of only two places `rounded.full` is used in the entire app (the other being status badges, per UX-DR3) — do not use `rounded.full` anywhere else, including buttons (UX-DR10 explicitly reserves `rounded.md` for buttons).
- **UX-DR15 (wizard mechanics):** exact step order is fixed (name → tracking type → schedule → target → dates → reminders → review); Back always enabled; Next disabled until validation; Review restates the full rule as one plain-language sentence before Save. All of these are directly testable and directly quoted from the AC — treat step order as a hard constraint, not a suggestion.
- **UX-DR16 (daily-vs-weekly Streak clarification) is the hardest UX requirement in this story and the one most likely to be under-implemented.** It is not enough to make both patterns *possible* to configure — the flow must *visibly* prevent confusing them. Re-read FR-6's consequence text carefully: "the flow must make the distinction clear between a daily-evaluated goal with Cheat Days... and a weekly-evaluated count goal... these read as similar but are not interchangeable, and the creation UX must not let a user pick the wrong one by accident." This requires deliberate, prominent inline copy at both the schedule and target steps, not a single generic tooltip.
- **Anti-duplication guidance:** reuse Story 1.4's eligible-days selector, Story 1.5's custom-recurrence input controls, Story 1.2's `numeric` typography pattern, and `GoalService.createGoal` (Story 1.1, extended by every subsequent story) as-is. This story's only genuinely new pieces are: the wizard shell/navigation, the `wizard-progress` component, the Streak-clarification copy/logic, the Dates/Reminders steps, and the Review sentence-generator.
- **Epic 4 boundary:** the Reminders step in this story is intentionally minimal (an opt-in toggle) since the actual global-reminder-time setting and `flutter_local_notifications` scheduling belong to Epic 4 Story 4.1. Do not implement notification scheduling here — that would duplicate work Epic 4 is scoped to do, and Epic 1 has no FR requiring it (FR-30 is explicitly an Epic 4 FR per the FR Coverage Map).
- **Testing standards:** widget-test the full wizard flow for a representative sample of the 13 worked-example patterns from Story 1.7 to prove the wizard can actually reach every corner of the schedule/target combination space it's supposed to expose, not just its simplest configuration.

### Project Structure Notes

- New files: `lib/presentation/screens/goal_creation_wizard.dart`, `lib/presentation/components/wizard_progress.dart`, plus one sub-widget per step (recommend `lib/presentation/screens/wizard_steps/` or `lib/presentation/components/wizard/` for the 7 step widgets — either is consistent with the seed's `screens`/`components` split; choose `presentation/components/wizard/` since steps are reusable pieces of the one wizard screen, not standalone screens themselves).
- `Goal.endDate` field addition to `lib/domain/entities/goal.dart` and its Drift column — flagged as a documented gap against the architecture's ER diagram (see Dev Notes); this is a additive, backward-compatible field addition, not a breaking change to anything Stories 1.1–1.8 already built.
- No other conflicts detected.

### References

- [Source: docs/epics.md#Story 1.9: Guided Goal-Creation Wizard]
- [Source: docs/epics.md#Requirements Inventory] (FR-6)
- [Source: docs/prd/4-features.md#FR-6: Guided Goal Creation]
- [Source: docs/prd/4-features.md#FR-1: Goal Definition] (optional end date requirement)
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Core-entity relationships] (GOAL entity fields — endDate gap noted)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components] (wizard-progress token spec, UX-DR9)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Shapes] (rounded.full reserved for status badges + wizard progress, UX-DR3)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Component Patterns] (guided creation wizard, Streak clarification, Review sentence)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Interaction Primitives] (linear navigation, no step-skipping)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Key Flows] ("Panda sets up an exotic goal" flow)
- [Source: docs/stories/1-1-scaffold-the-app-and-track-a-simple-daily-goal.md] (previous story intelligence — Goal/GoalVersion entities, GoalService.createGoal)
- [Source: docs/stories/1-2-track-counter-goals-with-corrections.md] (previous story intelligence — numeric typography token pattern)
- [Source: docs/stories/1-4-eligible-days-rules-presets-and-arbitrary-selection.md] (previous story intelligence — eligible-days selector component reused here)
- [Source: docs/stories/1-5-custom-recurrence-patterns.md] (previous story intelligence — custom recurrence input controls reused here)
- [Source: docs/stories/1-7-target-comparisons-and-free-combination.md] (previous story intelligence — Target Comparison model and 13 worked-example patterns the wizard must be able to construct)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `flutter test test/presentation/day_view_test.dart` and a temporary `wizard_diag_test.dart` (deleted after use) were used to isolate a Riverpod "tried to modify a provider while the widget tree was building" assertion, thrown from `RecurrenceSelector.initState()` synchronously calling `onChanged` (which writes to `goalWizardProvider`). `IndexedStack` mounts all 7 wizard steps on the first frame, so `ScheduleStep`'s `RecurrenceSelector` mounts (and ran its old synchronous `initState` emit) immediately on wizard open, not only once Panda reaches the Schedule step — this only surfaced once the wizard's state moved onto a real `@riverpod` notifier, since the codegen provider enforces Riverpod's build-phase-mutation guard where a plain `ValueNotifier`/local-state stand-in would not have.
- A second, unrelated widget-test bug surfaced in the same debug pass: `day_view_test.dart`'s `_createGoalViaWizard` helper tapped the wizard's Next button immediately after `enterText` with no intervening `pumpAndSettle`, so the Next button's enabled state (derived from the just-typed name) hadn't been rebuilt yet at tap time and the tap landed on a still-disabled button.

### Completion Notes List

- Added `Goal.endDate` (nullable ISO-8601 date-only) across `lib/domain/entities/goal.dart`, `lib/domain/services/goal_service.dart` (`createGoal`'s optional `endDate` param), `lib/data/drift/tables.dart` (nullable `endDate` column), and `lib/data/repositories/drift_goal_repository.dart` — the ER-diagram gap this story's Dev Notes flagged, resolved per the user's 2026-08-29 confirmation that the architecture doc now lists the field.
- Built the wizard shell (`goal_creation_wizard.dart`) as a `ConsumerWidget` holding all 7 step widgets in an `IndexedStack` (not a `PageView`) specifically so a step's own local widget state (e.g. `RecurrenceSelector`'s recurrence-kind selection) survives Back-then-forward navigation within one session — see the class doc comment. This choice is what surfaced the Riverpod build-phase-mutation bug above, since it means every step mounts on the very first frame rather than lazily.
- Modeled all wizard-local state in `lib/presentation/providers/goal_wizard_provider.dart` as a single `@riverpod class GoalWizard` (codegen, matching this codebase's established Riverpod 3.x pattern everywhere else) rather than a manual `Notifier` subclass — this codebase never hand-subclasses `Notifier`/`AutoDisposeNotifier`. `GoalWizardState` centralizes every step's validity as a pure getter (`nameStepValid` … `reviewStepValid`, `isStepValid(int)`) and the two UX-DR16 trigger conditions (`isDailyCheatDayPattern`, `isWeeklyCountPattern`) as derived booleans, so the Streak-clarification banner and Next-button enablement are both reactive to wizard state rather than recomputed ad hoc in the widgets.
- AC #5's re-validation-after-edit is implemented by `GoalWizard.setTrackingType` clearing the Target step's `targetComparison`/`targetValueText` on every Tracking-Type change (never leaving a stale Counter value behind a later switch to Boolean), combined with `GoalWizardState`'s validity getters being pure functions of current state rather than cached — Subtask 9.3's test exercises this scenario directly (Counter target configured → Back to Tracking Type → switch to Boolean → Target step correctly shows the fixed Boolean/Daily case, not the stale Counter comparison).
- `RecurrenceSelector.initState()` was changed to emit its default pattern via `WidgetsBinding.instance.addPostFrameCallback` instead of synchronously, per Riverpod's own recommended fix for this exact assertion — this is a real, previously-latent bug independent of this story's own new code, only exposed once the wizard routed a real provider write through it.
- Testing (Task 9) is split across two files: `test/presentation/day_view_test.dart`'s existing goal-creation-flow tests were rewritten to drive the new wizard (via a `_createGoalViaWizard` helper keyed on every step's `wizard-*` keys) rather than the old single-form `CreateGoalScreen`; a new `test/presentation/goal_creation_wizard_test.dart` covers Subtasks 9.1-9.5 directly, including three of Story 1.7's 13 worked-example patterns (Meditate-daily, Gym-3x-workdays, Workout-rolling-14-days) driven end-to-end through Save and checked against both the persisted `GoalVersion` fields and a direct `evaluate()` call.
- `evaluate()`'s cursor arithmetic works in pure calendar dates (midnight); an early version of a rolling-window test in `goal_creation_wizard_test.dart` used `DateTime.now()` (which carries a time-of-day) as the `evaluate()` date, which made "today" compare as already-past against the midnight cursor for the same date and flipped a Pending case to Fail — fixed by truncating to date-only before calling `evaluate()`, matching how `GoalWizard._today()` itself truncates the wizard's default start date. Not an app bug; a test-authoring one.

### File List

- `lib/domain/entities/goal.dart` (modified — added `endDate`)
- `lib/domain/services/goal_service.dart` (modified — `createGoal` accepts optional `endDate`)
- `lib/data/drift/tables.dart` (modified — nullable `endDate` column)
- `lib/data/repositories/drift_goal_repository.dart` (modified — reads/writes `endDate`)
- `lib/presentation/screens/goal_creation_wizard.dart` (new)
- `lib/presentation/components/wizard_progress.dart` (new)
- `lib/presentation/providers/goal_wizard_provider.dart` (new)
- `lib/presentation/components/wizard/name_step.dart` (new)
- `lib/presentation/components/wizard/tracking_type_step.dart` (new)
- `lib/presentation/components/wizard/schedule_step.dart` (new)
- `lib/presentation/components/wizard/target_step.dart` (new)
- `lib/presentation/components/wizard/dates_step.dart` (new)
- `lib/presentation/components/wizard/reminders_step.dart` (new)
- `lib/presentation/components/wizard/review_step.dart` (new)
- `lib/presentation/components/wizard/review_sentence.dart` (new)
- `lib/presentation/components/wizard/streak_clarification_banner.dart` (new)
- `lib/presentation/components/recurrence_selector.dart` (modified — deferred `initState`'s provider-mutating emit to a post-frame callback)
- `lib/presentation/screens/day_view.dart` (modified — navigates to `GoalCreationWizard` instead of the removed `CreateGoalScreen`)
- `test/presentation/day_view_test.dart` (modified — creation-flow tests rewritten to drive the wizard)
- `test/presentation/goal_creation_wizard_test.dart` (new — Subtasks 9.1-9.5)
