# 4. Features

## 4.1 Core Goal Engine

**Description:** The Goal model and its lifecycle. Every other feature reads from or writes to Goals defined here. Realizes UJ-1.

**Functional Requirements:**

### FR-1: Goal Definition
A user can define a Goal with a name, description, Tracking Type, Evaluation Period, Eligible-Days Rule, Target Comparison and value, a start date, and an optional end date (or "no end date").

**Consequences (testable):**
- A Goal cannot be saved without a Tracking Type, Evaluation Period, Eligible-Days Rule, and Target Comparison.
- The start date is a user-picked calendar date (not necessarily "today") — past, present, or future.
- A Goal with no end date continues indefinitely until paused or archived.

### FR-2: Goal Lifecycle
A Goal can be Active, Paused, Archived, or Expired (end date passed). A user can create, edit, pause, resume, and archive a Goal.

**Consequences (testable):**
- "Delete" and "Archive" are the same operation — there is no hard delete of an individual Goal.
- Archived Goals do not appear in active tracking views but remain fully visible in historical views and stats.
- Paused Goals produce no Eligible Days for the paused date range; the calendar reflects only the periods the Goal was actually active for.

### FR-3: Goal Versioning
Editing a Goal's rules, or pausing/resuming it, creates a new dated Goal Version rather than mutating history.

**Consequences (testable):**
- A day logged before a rule change is evaluated against the Goal Version active on that date, not the current rules.
- Editing a Goal never silently changes the computed status of past days.

### FR-4: Derived Status
A Goal's or day's status is always computed from its rules, logs, and Cheat Days at read time — never stored as the primary source of truth.

**Consequences (testable):**
- Editing a Goal's target or schedule correctly recalculates historical and future status without a data migration step.
- The only stored "status" values are read-optimization caches (see FR-31), which are provably derivable from the same source data.
- A future date, or a date within an in-progress period not yet certain to fail (per FR-18), displays the distinct **Pending** status — never Gray (which means "nothing scheduled") and never Red until failure is actually certain.

### FR-5: Zero-Eligible-Days Signal
If a Goal's Eligible-Days Rule produces zero Eligible Days within an entire Evaluation Period, that period shows **red**, not gray.

**Consequences (testable):**
- This is a deliberate exception to "gray = nothing scheduled" — it flags a likely misconfiguration rather than hiding it.

### FR-6: Guided Goal Creation
A user creates a Goal through a guided, step-by-step flow (name → tracking type → schedule → target → dates → reminders → review) rather than a single form presenting every field at once.

**Consequences (testable):**
- Given the exotic scheduling surface (§4.2), the flow must make the distinction clear between a **daily-evaluated** goal with Cheat Days (e.g. "7x/week with 2 cheat days," which produces a per-day pass/fail/cheat outcome and a real daily Streak) and a **weekly-evaluated** count goal (e.g. "5x/week," which produces only a whole-week pass/fail with no daily Streak) — these read as similar but are not interchangeable, and the creation UX must not let a user pick the wrong one by accident.
- Each step validates before the user can proceed to the next; the user can navigate back to edit an earlier step before saving.

---

## 4.2 Scheduling & Target Patterns

**Description:** The combinatorial rule space that makes Tracker's evaluation "exotic" by design rather than by accident. These requirements were explicitly expanded during PRD creation beyond what `requirements-v2.md` scoped for MVP — full exotic scheduling ships now, not deferred. That trade-off is deliberate: it enlarges the goal engine's test surface and delays how soon the simplest version of UJ-1 is usable end-to-end, in exchange for the product's core correctness claim (SM-2) holding from day one instead of being retrofitted onto a simpler engine later. Realizes UJ-1.

**Functional Requirements:**

### FR-7: Evaluation Period Types
A Goal's Evaluation Period can be Daily, Weekly, Biweekly, Monthly, Quarterly, Yearly, a Rolling Window (N days), or Custom.

**Consequences (testable):**
- Each period type has a well-defined boundary: Weekly follows the Week-Start Setting (FR-24); Monthly/Quarterly/Yearly follow calendar month/quarter/year boundaries; a Rolling Window has no fixed calendar boundary at all — it is always "the trailing N days ending today."

### FR-8: Eligible-Days Rule — Arbitrary Selection
Eligible Days are not limited to preset patterns. A user can select any arbitrary subset of weekdays (e.g. Monday, Tuesday, Thursday, Saturday) as a Goal's Eligible-Days Rule, in addition to the convenience presets: every day, workdays [ "workdays" is a user-configurable preset, not hardcoded Monday–Friday, per v1 §12's soft requirement], and weekends.

**Consequences (testable):**
- Any combination of 1–7 weekdays is selectable. "Workdays" and "weekends" are themselves just two convenience presets over the same underlying arbitrary-selection mechanism, not special-cased rule types.

### FR-9: Custom Recurrence
The Eligible-Days Rule additionally supports: every N days, every N weeks (on specific weekdays), every N months, a specific day (or days) of the month, the Nth weekday of a month (e.g. 2nd Tuesday), and an explicit custom date selection.

**Consequences (testable):**
- The every-N-days/every-N-weeks/every-N-months cycle is anchored to the Goal's start date, producing a fixed calendar grid (e.g. "every 3 days" from a Jan 1 start date is always Jan 1, 4, 7, 10…). Editing the Goal's other rules does not re-anchor this cycle.
- The Nth-weekday-of-month pattern is computed independently per calendar month, not relative to the Goal's start date.

### FR-10: Blackout Dates
A user can layer Blackout Dates on top of any Eligible-Days Rule to exclude specific dates (e.g. holidays) regardless of the underlying rule. the user can go to the current day and mark the day as blackout day (holiday , can't follow this rule due to some other reasons and add reason if needed)

**Consequences (testable):**
- A Blackout Date exempts that date from failure — like a forced Cheat Day — but does **not** reduce the Goal's eligible-day count or target for the period. E.g. "at least 3 of 5 eligible days" with one Blackout Date still requires 3 successes; the pool of eligible days is unchanged.
- Blackout Dates do not consume the Goal's Cheat Day quota — they are a separate mechanism.

### FR-11: Target Comparison
A Goal's Target Comparison is At Least, At Most, or Exactly. At Least has no maximum; At Most has no minimum — there is no bounded/range comparison combining both a floor and a ceiling in one Goal.

**Consequences (testable):**
- At Least, At Most, and Exactly are valid for both Boolean Goals (counting eligible days marked done) and Counter Goals (comparing the summed period value).

### FR-12: Free Combination
Evaluation Period, Eligible-Days Rule, Tracking Type, and Target Comparison are independent axes and must combine freely — any valid value of one axis works with any valid value of every other axis. See the worked-example table below.

**Consequences (testable):**
- All rows in the table below are individually creatable and correctly evaluable.

| # | Pattern | Period | Eligible days | Type | Target |
|---|---|---|---|---|---|
| 1 | Meditate daily | Daily | Every day | Boolean | Exactly 1 |
| 2 | Gym 3x/week, workdays only | Weekly | Workdays | Counter (done-count) | At least 3 |
| 3 | Coffee limit | Daily | Every day | Counter | At most 2 |
| 4 | Sleep hours | Daily | Every day | Counter | At least 7 |
| 5 | Read every 3 days | Custom | Every N days (N=3) | Boolean | Exactly 1 |
| 6 | Deep clean, 2nd Saturday of month | Monthly | Nth weekday of month | Boolean | Exactly 1 |
| 7 | Water 8 glasses, skip vacation days | Daily | Every day + Blackout Dates | Counter | At least 8 |
| 8 | Quarterly review | Quarterly | Specific day of month | Boolean | Exactly 1 |
| 9 | Workout 10x in any rolling 14 days | Custom | Rolling Window (14d) | Counter | At least 10 |
| 10 | At least 3 days a week, any day | Weekly | Every day (7 eligible) | Boolean | At least 3 |
| 11 | At least 3 days in the work week | Weekly | Workdays (5 eligible) | Boolean | At least 3 |
| 12 | Done on at least 3 of Mon/Tue/Thu/Sat | Weekly | Mon, Tue, Thu, Sat (arbitrary subset) | Boolean | At least 3 |
| 13 | Done on exactly 2 of Mon/Tue/Thu/Sat | Weekly | Mon, Tue, Thu, Sat | Boolean | Exactly 2 |

**Out of Scope:** Cross-Goal dependencies, conditional/if-then rules between Goals, percentage targets, streak-dependent targets, time-of-day requirements, duration tracking, and multiple measurements per day are explicitly **not** part of this combination space in MVP — see §6.

---

## 4.3 Daily Logging & Evaluation

**Description:** How a day's data is entered and turned into status. Realizes UJ-1.

**Functional Requirements:**

### FR-13: Boolean Entry
A user can mark a Boolean Goal done/not-done for any Eligible Day.

### FR-14: Counter Entry
A user can increment/decrement or directly enter a numeric value for a Counter Goal on any Eligible Day, with an optional note.

**Consequences (testable):**
- A Counter can be incremented multiple times throughout the day (e.g. logging water intake several times), all folding into a single running daily total. No per-increment timestamp is captured — this is a deliberate simplification versus an earlier, timestamped multi-entry concept; see `addendum.md`.
- Counter values support decimals/fractional quantities (e.g. 7.5 hours slept), not integers only.

### FR-15: Corrections
A user can log a negative Counter value to correct an over-log. The day's total floors at 0 — it cannot go negative.

### FR-16: Cheat Days
A user can mark a date as a Cheat Day for a specific Goal, up to that Goal's per-Goal quota (default 0). The quota resets each Evaluation Period (e.g. a Goal configured for 2 Cheat Days/week gets a fresh allowance every week, not a lifetime cap). A Cheat Day displays yellow and does not reduce any Target Comparison's required count — this exemption applies uniformly across At Least, At Most, Exactly, and Range goals alike, not just Exactly.

### FR-17: DNF Marking
A user can explicitly mark a day DNF. The mark is superseded by the enclosing period's actual computed outcome once that period closes.

### FR-18: Certain-Failure Red
A day (for Daily Goals) or the calendar cell for an in-progress period (Weekly/Monthly/Custom/Rolling Window) turns red only once failure is mathematically certain given the days remaining in the period or trailing window — not merely because the target hasn't been hit yet.

**Consequences (testable):**
- A Weekly "at least 3 of 5 workdays" Goal does not turn red until 3 of the 5 eligible days have already been missed.
- A Rolling-Window "10x in any 14 days" Goal turns red the day the remaining days in the trailing 14-day window can no longer mathematically reach 10, and has no other red-triggering condition.
- Before failure is certain, the cell shows Pending (see FR-4), not Red and not Gray.

### FR-19: Data-Loss Bound
If the app is killed mid-save, only that single in-flight entry is lost. All previously committed data survives.

### FR-20: Midnight Rollover
If the app is left open across a midnight boundary, any unsaved, mid-edit entry (a Counter being typed, a Boolean toggle not yet committed) is auto-committed to the day it was entered on, not the new day. The app then performs a full data reload so all in-memory evaluation state (dashboard, today's view, in-progress statuses) recomputes against the new local day.

---

## 4.4 Calendar & Views

**Description:** How status is browsed. Realizes UJ-1.

**Functional Requirements:**

### FR-21: Day View
A user can tap any calendar date to view and log that day's eligible Goals and their status.

### FR-22: Week View
A week grid shows each Goal's per-day status and the week's overall progress.

### FR-23: Month View
Month view is the default calendar surface. A user can swipe between months and jump to today. Each day shows its Derived Status.

### FR-24: Week-Start Setting
The first day of the week is configurable (Sunday or Monday), defaulting to Monday.

### FR-25: Goal Filtering
The calendar can be filtered to show all Goals, a single Goal, or a category. Goals can be organized into categories, per v1 §41/§8 — confirm category is in MVP, not just a schema placeholder.

---

## 4.5 Dashboard & Statistics

**Description:** Progress at a glance and over time. Realizes UJ-1.

**Functional Requirements:**

### FR-26: Dashboard
The home screen shows today's eligible Goals with progress (e.g. "3/5 complete"), current Streaks, this week's and this month's progress rollups, and the next scheduled reminder time (a single global time, not per-Goal — see FR-30).

### FR-27: Goal Detail Screen
Each Goal has a detail screen showing its schedule, target, current and longest Streak, completion percentage, historical calendar, **Version Timeline**, and edit/archive actions.

**Consequences (testable):**
- The Version Timeline is a distinct element from the historical calendar — it shows the Goal's dated rule-change segments (e.g. "3x/week Jan 1–Mar 14, then 5x/week Mar 15–present"), sourced directly from FR-3's Goal Versions.

### FR-28: Statistics
The app supports current Streak, longest Streak, completion percentage (daily/weekly/monthly), counts of successful and failed periods, Cheat Day count, average and total value (Counter Goals), and full Goal history.

**Consequences (testable):**
- Completion percentage excludes periods where the Goal was Paused, consistent with FR-2's guarantee that a paused date range produces no Eligible Days.

### FR-29: Rule-Aware Streaks
A Streak counts consecutive successful Evaluation Periods, not consecutive days, for any non-Daily Goal (e.g. a 3x/week Goal's Streak is in weeks, not days). Rolling Window Goals have no Streak stat — they show current pace/status only.

---

## 4.6 Notifications

**Description:** Local reminders, no server involved.

**Functional Requirements:**

### FR-30: Local Reminders
The app schedules local notifications at a single global reminder time applied across all Goals (no per-Goal custom times in MVP).

**Consequences (testable):**
- The scheduler does not fire a reminder for a Goal on a day it's not Eligible, or for a Paused/Archived Goal, or once that Goal's target for the current period is already met. suppress-on-completion behavior, per v1 §35 — confirm (except for greater than or equal goals, we keep reminding even after finishing it for x times)

---

## 4.7 Widgets

**Description:** Home-screen-only glanceable status.

**Functional Requirements:**

### FR-31: Home-Screen Widgets
The app provides exactly three widget types: **Today**, **Week**, and **Month**. No lock-screen widgets in MVP.

**Consequences (testable):**
- Widgets render only precomputed, cached status — never a live rule evaluation at render time.

### FR-32: Widget Tap-Through
Tapping a widget opens the app to the relevant date. [ASSUMPTION: per v1 §37, where platform APIs allow — confirm exact behavior per platform in UX/architecture phase.]

---

## 4.8 Data Management

**Description:** Backup, restore, and the two forms deletion takes in this product.

**Functional Requirements:**

### FR-33: JSON Export
A user can export the full app state (Goals, logs, Cheat Days, settings, categories, notification config, metadata) to a single portable JSON file.

### FR-34: JSON Import (Merge)
A user can import a previously exported JSON file. Import merges into existing local data — it is not a full replace/restore-only operation.

**Consequences (testable):**
- Import rejects: malformed JSON, missing required structure (no `goals` array, no `metadata`, etc.), schema-version mismatch, duplicate IDs, orphaned logs (referencing a nonexistent Goal), invalid dates, invalid/contradictory rules (e.g. min > max, negative target, unknown enum value), and invalid Cheat Day configuration (quota referencing a nonexistent Goal, or a negative quota).
- An export containing zero Goals is accepted with a warning, not rejected outright — an empty export is a valid (if unusual) state, not a malformed one.
- Any conflict between imported and existing data always prompts the user for a decision — the app never silently resolves a conflict (e.g. "newest wins").

### FR-35: Delete = Archive
Deleting a Goal archives it. There is no hard delete of an individual Goal; full history is always preserved.

### FR-36: Reset / Erase All
A separate, explicit "reset app" action wipes all local data and returns the app to a clean first-run state. This is the only form of true, irreversible deletion in the product.

**Consequences (testable):**
- Reset requires an explicit secondary confirmation step before it executes — it is the one action in the app with no undo, and is the only FR that needs one.
