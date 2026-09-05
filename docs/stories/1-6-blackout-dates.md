# Story 1.6: Blackout Dates

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want to mark specific dates as excluded from a goal (e.g. a holiday),
so that I'm not penalized for a day I genuinely can't follow the rule, without it looking like I dodged the requirement.

## Acceptance Criteria

1. **Given** today's date and an active goal **When** Panda marks today as a Blackout Date with an optional reason **Then** that date is exempted from failure for that goal (FR-10)
2. **Given** a goal "at least 3 of 5 eligible days" with one Blackout Date in the period **When** `evaluate()` runs **Then** the required count stays 3 and the eligible-day pool is unchanged — the Blackout Date reduces neither (FR-10 consequence)
3. **Given** a Blackout Date is set **When** the Cheat Day quota is checked for that goal/period **Then** the Blackout Date does not consume any of the Cheat Day quota — a separate mechanism (FR-10 consequence)
4. **Given** the Cheat Day / Blackout Date sheet component (UX-DR13) **When** Panda long-presses a Day View goal row **Then** the sheet opens with the Blackout Date action available for that goal and date (FR-10) — the Cheat Day action is added to this same sheet in Epic 2 Story 2.4, once Cheat Days exist; until then the sheet shows Blackout Date only
5. **And** this story creates only the `BLACKOUT_DATE` Drift table (Story 2.4 later adds `CHEAT_DAY`) — no table is created before the story that needs it

## Tasks / Subtasks

- [x] Task 1: `BlackoutDate` domain entity and Drift table (AC: #1, #5)
  - [x] Subtask 1.1: Create `lib/domain/entities/blackout_date.dart` — `BlackoutDate` entity per the ER diagram: `id` (UUIDv4), `goalId` (FK), `date` (ISO-8601 date-only string), `reason` (nullable string)
  - [x] Subtask 1.2: Create the `BLACKOUT_DATE` Drift table in `lib/data/drift/` matching this shape exactly — this is the **only** new table this story adds; do not create `CHEAT_DAY` here (that is explicitly Epic 2 Story 2.4's responsibility per epics.md AC #5 and the architecture's "no table is created before the story that needs it" framing)
  - [x] Subtask 1.3: Define `BlackoutDateRepository` domain interface (in `lib/domain/services/`, alongside the other repository interfaces from Story 1.1) and implement `DriftBlackoutDateRepository` in `lib/data/repositories/`
- [x] Task 2: GoalService — Blackout Date write path (AC: #1)
  - [x] Subtask 2.1: Add `GoalService.markBlackoutDate(goalId, date, {reason})` use-case — this is a new kind of domain write, but per AD-6's scope ("every edit... every log entry... routes through it"), `BlackoutDate` is arguably not a `GoalVersion` or `GoalLog` in the strict AD-6 sense; nonetheless, keep this write routed through `GoalService` for consistency with the rest of the app's single-writer discipline and so JSON import (Epic 6) has one place to route Blackout Date writes through later — do not let presentation call `BlackoutDateRepository` directly
  - [x] Subtask 2.2: The write is a single Drift transaction (Transaction atomicity) — for this story a single-row insert, but keep the transactional wrapper consistent with every other `GoalService` write path established in Stories 1.1/1.2
  - [x] Subtask 2.3: FR-10 specifies Blackout Dates can be marked "from the current day" — confirm the use-case does not restrict marking future or past dates beyond what the PRD specifies (PRD/epics text says "from the current day," read here as "today onward is the primary supported case per the AC's 'today's date' framing"; retroactively blackout-marking a past date is not explicitly required or forbidden — default to allowing it, since no validation rule in epics.md/architecture restricts it, and flag as an open question below only if a reviewer wants it explicitly restricted)
- [x] Task 3: Evaluator — Blackout Date exemption without pool/target reduction (AC: #2, #3)
  - [x] Subtask 3.1: Widen `evaluate()`'s `blackoutDates` parameter (already present in the AD-4 signature finalized in Story 1.3, previously always passed as an empty list) to be populated and consumed: for a date matching a `BlackoutDate` entry for that goal, the date is exempted from counting as a failure/miss **without** being removed from the eligible-days pool and **without** reducing the period's required target count (FR-10 consequence — "the required count stays 3 and the eligible-day pool is unchanged")
  - [x] Subtask 3.2: Concretely: a Blackout Date behaves like "this eligible day doesn't count against you if not logged," similar in effect to a forced Cheat Day, but implemented as a wholly separate code path from the (not-yet-existing) Cheat Day mechanism — do not share a single "exemption" boolean/list between Blackout Dates and the future Epic 2 Cheat Days; keep `blackoutDates` and (later) `cheatDays` as clearly distinct evaluator inputs per the AD-4 signature, since FR-10 explicitly requires them to be a "separate mechanism" from Cheat Day quota (AC #3)
  - [x] Subtask 3.3: Ensure the certain-failure math that Story 1.8 will build (not yet present) has a clean seam to consume this exemption: a Blackout-Dated eligible day should be treated as "neither success nor failure, effectively a non-event for pass/fail accounting" rather than as a missed day — document this contract clearly in code comments since Story 1.8 depends on it
- [x] Task 4: Presentation — Cheat Day / Blackout Date sheet (Blackout-only for now) (AC: #4)
  - [x] Subtask 4.1: Build `lib/presentation/components/cheat_blackout_sheet.dart` (name chosen now since Epic 2 Story 2.4 extends this exact component with a Cheat Day action rather than building a new sheet) implementing UX-DR13: a bottom-sheet/contextual surface reached via long-press or an overflow icon on a Day View goal row (per EXPERIENCE.md's Day-view goal row component pattern)
  - [x] Subtask 4.2: For this story, the sheet shows only the "Mark as Blackout Date" action (with an optional reason text field) for the tapped goal+date — no Cheat Day action yet, since `CheatDay` doesn't exist until Epic 2 Story 2.4
  - [x] Subtask 4.3: Wire the long-press gesture on the Day View goal row (component from Story 1.1) to open this sheet — confirm this doesn't conflict with the row's existing tap-to-log gesture (tap = primary log action; long-press = contextual sheet, per EXPERIENCE.md Interaction Primitives)
- [x] Task 5: Testing (AC: all)
  - [x] Subtask 5.1: Unit-test `evaluate()` with a Blackout Date present: confirm the period's required target count is unchanged and the eligible-day pool count is unchanged, compared to the same scenario without the Blackout Date, other than the one date's own exemption from failure
  - [x] Subtask 5.2: Unit-test that a Blackout Date does not affect any Cheat-Day-quota-related state (trivial for this story since `CheatDay` doesn't exist yet, but assert the evaluator's `blackoutDates` handling touches no shared state that Epic 2 will later use for Cheat Day quota — a structural/architectural assertion as much as a behavioral one)
  - [x] Subtask 5.3: Unit-test `GoalService.markBlackoutDate`'s transactional write
  - [x] Subtask 5.4: Widget-test the long-press-opens-sheet interaction and the Blackout Date marking flow (with and without a reason)

## Dev Notes

- **Builds on Stories 1.1–1.5.** `BlackoutDate` is the first genuinely new entity/table since Story 1.1 — everything else in Epic 1 so far has extended existing entities. This story also finally populates the `blackoutDates` parameter of the AD-4 `evaluate()` signature that Story 1.3 declared (as an always-empty list) — confirm that widening the actual consumption logic, not just passing real data through unused, is the deliverable here.
- **AD-4 (pure evaluator):** `blackoutDates: List<BlackoutDate>` is a direct, first-class input to `evaluate()`, per the architecture's own note: "FR-10 requires Blackout Dates to exempt a date without changing the eligible-day count — both must reach the evaluator, not just the target/version data." This confirms Blackout Dates are evaluator inputs, not a pre-processing step applied before calling `evaluate()`.
- **AD-6 (GoalService as sole writer):** although AD-6's text technically enumerates `GoalVersion`/`GoalLog`/corrections/import writes, this story routes `BlackoutDate` writes through `GoalService` as well, for consistency with the app-wide single-writer discipline and to keep Epic 6's JSON import (which must write Blackout Dates too, per FR-33/FR-34's data scope) able to reuse one write path. Do not let any screen call `BlackoutDateRepository` directly.
- **FR-10 consequence — the "separate mechanism" requirement is precise and testable:** a Blackout Date must (a) exempt the date from failure, (b) NOT reduce the eligible-day count, (c) NOT reduce the target, and (d) NOT consume Cheat Day quota. All four must be independently verified — do not assume (a) implies the other three.
- **UX-DR13 (Cheat Day / Blackout Date sheet):** this is explicitly a long-press/overflow contextual action from a Day-view goal row, not a standalone top-level surface. Build the sheet component to be extended by Epic 2 Story 2.4 with a second action, rather than treating this as a "Blackout Date only" component that gets replaced later — name and structure it generically (e.g. `cheat_blackout_sheet.dart`) from the start.
- **Anti-duplication guidance:** reuse the Day View goal row from Story 1.1 (add the long-press gesture to the existing component, don't create a second row variant), reuse `evaluate()` (widen its existing `blackoutDates` parameter handling), and reuse the `GoalService`/transaction/repository patterns established in Stories 1.1/1.2.
- **Testing standards:** the "does not reduce pool/target" guarantee (FR-10 consequence) is a boundary-correctness case NFR-6 calls out — test it by comparing evaluator output with and without the Blackout Date present on an otherwise-identical scenario, not just by checking the blacked-out date itself renders correctly.

### Project Structure Notes

- New files: `lib/domain/entities/blackout_date.dart`, `lib/data/drift/` table addition, `lib/data/repositories/drift_blackout_date_repository.dart`, `lib/presentation/components/cheat_blackout_sheet.dart` — all within the existing seed folders from Story 1.1, no new top-level directories.
- Confirms the architecture's explicit sequencing note: "this story creates only the `BLACKOUT_DATE` Drift table (Story 2.4 later adds `CHEAT_DAY`)" — verified consistent with epics.md Epic 2 Story 2.4's own text.
- One open question flagged below regarding whether Blackout Dates may be retroactively marked on past dates (not explicitly restricted by any source document).

### References

- [Source: docs/epics.md#Story 1.6: Blackout Dates]
- [Source: docs/epics.md#Requirements Inventory] (FR-10)
- [Source: docs/epics.md#Story 2.4: Cheat Days] (cross-reference confirming CHEAT_DAY table sequencing and shared sheet component)
- [Source: docs/prd/4-features.md#FR-10: Blackout Dates]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-4 — Pure Evaluator Contract]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-6 — GoalService Owns All Version and Log Writes]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Core-entity relationships] (BLACKOUT_DATE table shape, direct evaluate() input)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Information Architecture] (UX-DR13 — Cheat Day / Blackout Date sheet reached from Day-view goal row)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Component Patterns] (Day-view goal row long-press pattern)
- [Source: docs/stories/1-1-scaffold-the-app-and-track-a-simple-daily-goal.md] (previous story intelligence — goal-row component, GoalService/transaction pattern)
- [Source: docs/stories/1-3-evaluate-all-evaluation-period-types.md] (previous story intelligence — finalized evaluate() signature including blackoutDates parameter)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `dart analyze lib test`: clean (only the 5 pre-existing info suggestions).
- `flutter test`: 72/72 passing.

### Completion Notes List

- `BlackoutDate` (minimal entity from Story 1.3) now has real persistence: `BLACKOUT_DATE` Drift table (the only new table this story adds — no `CHEAT_DAY`), `BlackoutDateRepository`/`DriftBlackoutDateRepository`, and `GoalService.markBlackoutDate` (routed through `GoalService` for single-writer consistency, per Dev Notes, even though AD-6's original text doesn't literally enumerate this entity).
- `evaluate()`'s `blackoutDates` parameter (declared empty-only since Story 1.3) is now consumed: in `_evaluateDay` (the Daily fast path, which is where Fail/Pending currently exist), a blacked-out date with no completed log renders `empty` instead of `pending`/`fail` — a non-event, never a miss — while a blacked-out date that was still logged done stays `success` (blackout exempts from failure, not from success). Verified as a genuinely separate mechanism from the (not-yet-existing) Cheat Day path: a distinct `_isBlackedOut` check, no shared exemption list.
- Period aggregation (`_evaluatePeriod`) needed no code changes — it already never shrinks the eligible-day pool or target for an unlogged day, which is exactly what FR-10 requires a Blackout Date to preserve. Verified directly: an otherwise-identical Weekly scenario evaluates to the same `currentValue`/`targetValue`/`status` with and without a Blackout Date present.
- `cheat_blackout_sheet.dart` (named generically per Dev Notes, since Epic 2 Story 2.4 extends this exact component) — a bottom sheet with the Blackout Date action (reason optional) reached via a new `onLongPress` on `GoalRow`, wired in `DayViewScreen` for both Boolean and Counter goals.

### File List

- `lib/domain/services/blackout_date_repository.dart` — new
- `lib/domain/services/goal_service.dart` — added `markBlackoutDate`, constructor gained `blackoutDateRepository`
- `lib/domain/evaluator/evaluate.dart` — `_isBlackedOut` + `_evaluateDay` exemption logic
- `lib/data/drift/tables.dart` — `BlackoutDates` table
- `lib/data/drift/database.dart` (+ `.g.dart`) — registered `BlackoutDates`
- `lib/data/repositories/drift_blackout_date_repository.dart` — new
- `lib/presentation/providers/repository_providers.dart` (+ `.g.dart`) — `blackoutDateRepositoryProvider`
- `lib/presentation/providers/goal_service_provider.dart` (+ `.g.dart`) — wired new dependency
- `lib/presentation/providers/goal_data_providers.dart` (+ `.g.dart`) — `blackoutDatesProvider`
- `lib/presentation/components/goal_row.dart` — added `onLongPress`
- `lib/presentation/components/cheat_blackout_sheet.dart` — new
- `lib/presentation/screens/day_view.dart` — wired long-press + blackout data into `evaluate()`
- `test/domain/services/fakes.dart` — `InMemoryBlackoutDateRepository`
- `test/domain/services/goal_service_test.dart` — `markBlackoutDate` group
- `test/domain/evaluator/evaluate_test.dart` — Blackout Dates group
- `test/presentation/day_view_test.dart` — long-press/sheet widget test
