# Offline Cross-Platform Goal Planner / Calendar — Requirements (v2)

## 1. Project Overview

Build a personal, privacy-focused **goal planner / habit tracker / calendar application** for **Android and iPhone**, implemented with **Flutter**.

The application is intended primarily for one person and therefore:

- Must not require user registration.
- Must not require login/authentication.
- Must not require a backend server for normal operation.
- Must work fully offline.
- Must store the user's data locally on the device.
- Should be extensible to support optional backup/export and potentially optional cloud synchronization in the future.
- Should support Android and iOS from a shared Flutter codebase.
- A web version may optionally be produced later, but mobile is the primary target.
- Home-screen/lock-screen widgets are highly desirable.

The product is not intended to be a conventional appointment calendar. It is primarily a **rule-based goal/habit planner whose results are visualized through calendar dates, weeks, and months**.

The app deliberately targets a single local device and a single local user. There is no time-zone travel scenario to support, no multi-user account model, and no server-mediated conflict resolution — see §6 (Local Calendar Day & Time Handling) for the precise consequence of this choice.

---

## 2. Core Product Concept

The application consists of four conceptual layers:

1. **Goal Definition**
2. **Daily/Periodic Tracking**
3. **Automatic Rule Evaluation**
4. **Calendar Visualization**

The user creates goals with rules such as:

- Do something once a day.
- Do something at least 3 times per week.
- Do something exactly 3 times per week.
- Do something no more than 2 times per day.
- Do something 3 times per week only on workdays.
- Do something on Monday, Wednesday, and Friday.
- Do something only on weekends.
- Do something 8 times per month.
- Do something n times a week / on these specific days.
- Track a quantitative value such as water intake, hours slept, pages read, etc.
- Track a simple Boolean completion state.
- Mark a day as a cheat day.

The application evaluates these rules automatically and represents the resulting status visually.

The calendar visualization must show whether a day completed all its goals and whether a week/month completed all its goals, using color. Current and future days/weeks must wait for goal status to be updated; if not yet updated, they are treated as not-yet-evaluated (not as failed).

---

## 3. Primary Goals

The application should allow the user to:

- Create goals.
- Define when a goal starts.
- Define when a goal ends, or make it continue indefinitely.
- Define how frequently a goal must be performed.
- Define which days are eligible.
- Define whether the goal is Boolean or quantitative.
- Define minimum, maximum, exact, or range-based targets.
- Record progress for individual dates.
- Open any calendar date and enter the relevant progress.
- Mark individual dates as cheat days.
- See daily status using colors.
- See weekly status using colors.
- See monthly progress.
- View statistics and streaks.
- Receive local reminders.
- Use phone widgets to see progress.
- Export/restore data without requiring an account or server.
- Choose a week-start day (Sunday or Monday) in settings.
- See a goal's edit/pause/resume history as a timeline of dated versions.

---

## 4. Platform Requirements

### 4.1 Primary Platforms

- Android
- iOS

### 4.2 Framework

Use:

- Flutter
- Dart

A single Flutter codebase should be used wherever possible, or another cross-platform approach that achieves the same Android+iOS coverage from one codebase.

---

## 5. Offline-First / Privacy Requirements

The application must be **local-first**.

### Required behavior

The app must work without:

- Internet
- Login
- User account
- Backend server
- Cloud database

All core functionality must operate using the local device database.

---

## 6. Local Calendar Day & Time Handling

The app deliberately does **not** implement time-zone or daylight-saving handling. This is a conscious departure from earlier drafts that called for time-zone/DST support: the app has exactly one user on one device, so there is no cross-timezone scenario worth the complexity.

### 6.1 Definition of "a day"

A "day" is always the device's **current local calendar day**, as reported by the OS clock at the moment of evaluation. There is no timezone conversion, no UTC normalization, and no DST-transition special-casing. If the device's clock or timezone setting changes, the app simply follows whatever the OS now reports as "today" — no reconciliation logic is required.

### 6.2 Week-start setting

The user can choose whether weeks start on **Sunday** or **Monday** via a setting. This choice affects:

- Week boundaries for weekly-evaluated goals.
- The week view's day ordering.
- Weekly widget layout.

Default: **Monday**.

### 6.3 Midnight rollover while the app is open

If the app is left open across midnight (i.e., the local calendar day changes while the app is in an active session):

1. Any unsaved, mid-edit entry (e.g., a counter value being typed, a Boolean toggle not yet committed) is **auto-committed to the old day first** — the entry belongs to the day that was "today" when the user started editing it, not the new day.
2. The app then performs a **full data reload**: what was "today" becomes "yesterday," goal statuses, the Today page, and any in-memory evaluation state are recomputed against the new local day.

No entry is silently discarded and no entry is silently reassigned to the new day.

### 6.4 Monthly goals use the calendar month

Monthly-evaluated goals always use the calendar month (the 1st through the last day of that month, per the device's local calendar) as the evaluation period. There is no "rolling 30-day window" option. This keeps monthly evaluation simple and matches how the month view is presented.

---

## 7. Database Requirements

### 7.1 Database

Use a local database. No cloud database should be required.

The app should support importing and exporting the entire database for use on another device.

### 7.2 Data Safety

The app should provide:

- Manual export
- Manual import
- Local backup capability

Preferred export format:

- JSON

Potential future formats:

- ZIP containing JSON and attachments
- CSV for logs/statistics

The exported data should be sufficient to reconstruct the user's goals (including full version history), logs, settings, and cheat days. See §29 (Backup and Restore) for full import/export requirements, including the validation and rejection rules.

---

## 8. No Authentication

Authentication is explicitly **not required**.

Do not implement:

- Login
- Registration
- Password management
- OAuth
- User profiles
- Email verification

The application should treat the device's local database as belonging to the user.

If optional cloud backup is introduced in a future version, authentication can be designed separately at that time.

---

## 9. Goal Model

A goal represents something the user wants to track. Conceptually, a **goal** is a stable logical entity (id, name, category, icon, color, tracking type) that owns an ordered sequence of **version segments** — see §16 (Goal Versioning). Each version segment carries the scheduling/target rule that was in effect for a given date range.

A goal (and its current version segment) should have at least:

```text
Goal (logical, stable across versions)
  id
  name
  description
  category
  icon
  color
  trackingType        -> Boolean | Counter/quantitative
  enabled
  archived
  createdAt
  updatedAt

GoalVersion (dated segment — see §16)
  id
  goalId
  effectiveFrom
  effectiveTo (nullable = "current")
  startDate
  endDate
  hasEndDate

  evaluationPeriod     -> Daily | Weekly | Monthly | Yearly | Custom
  eligibleDays / eligible dates
  comparisonRule       -> less than X | exactly X | at least X  (Range for Counter goals only)
  targetValue

  cheatDayConfiguration -> per-goal quota: X per week or X per month, default 0

  priority             -> come up with options (e.g. Low / Medium / High)
```

The exact database representation can be normalized into separate entities where appropriate (e.g., a `goals` table plus a `goal_versions` table plus a `goal_logs` table).

---

## 10. Goal Lifecycle

A goal can be:

- Active
- Paused/disabled
- Archived
- Expired because its end date has passed

The user must be able to:

- Create
- Edit
- Pause/disable
- Resume
- Archive
- Delete

Deleting should preferably require confirmation.

### 10.1 Pause and resume are version segments

Pausing and resuming a goal are implemented through the same goal-versioning mechanism used for mid-period edits (§16): pausing closes the current version segment and opens a "paused" segment (no eligible days, no evaluation); resuming closes the paused segment and opens a new active segment.

Resuming a paused goal resumes **mid-period, immediately** — not only at the start of the next evaluation period. The calendar and Today page reflect the goal as active again from the moment it is resumed, and the current week/month is evaluated using only the eligible days that fall within the active segment(s) of that period.

For the days the goal was paused, the calendar must show only the goal state that applied for that specific time frame (i.e., paused days are not retroactively counted or penalized once the goal resumes).

### 10.2 Delete and archive converge

Deleting a goal does **not** erase its version history. Deleting moves the goal — together with all of its dated version segments and logs — into an **Archived** view; the specific date ranges and evaluation results for each segment remain visible for reference. There is no separate "hard delete" path in normal use: for any goal with logged history, "delete" and "archive" are the same operation. Archived goals do not appear in normal active tracking views (dashboards, Today page, widgets) but remain browsable in the Archived view.

---

## 11. Start and End Dates

Every goal (version segment) must support:

### Start date

The date from which the goal (or that version of it) becomes active.

### End date

Optional. The user can choose:

- No end date / forever
- Specific end date

Example:

```text
Start: 2026-08-01
End: 2026-10-31
```

or:

```text
Start: 2026-08-01
End: None
```

The latter means the goal continues indefinitely until disabled/archived/stopped, or until a new version segment supersedes it.

---

## 12. Goal Frequency

The application should support at least:

- Daily
- Weekly
- Monthly
- Yearly
- Custom/advanced recurrence

Frequency (evaluation period) and eligible-day rules are separate concepts.

For example:

```text
Evaluation period = Weekly
Eligible days = Monday-Friday
Target = At least 3
```

This means the user needs to complete the goal at least 3 times during the eligible workdays of each week.

Note the important semantic distinction between two superficially similar rules:

- **"7x/week with 2 cheat days"** is a **daily-evaluated** goal: each day gets its own pass/fail/cheat outcome, a meaningful daily streak exists, and failure is known the same day.
- **"5x/week"** is a **weekly-evaluated** goal: only the week as a whole passes or fails, there is no meaningful daily streak, and no individual day can be marked failed until the remaining eligible days in the period can no longer reach the target (see §22).

These are not interchangeable representations of the same intent, and the goal-creation UX should make the distinction clear.

---

## 13. Eligible Days / Schedule Rules

This is a major requirement.

The user must be able to specify which days a goal is allowed or expected to occur on.

Support at least:

### Every day

```text
Monday-Sunday
```

### Weekdays / workdays

```text
Monday-Friday
```

The application should make "workdays" configurable if possible rather than assuming Monday-Friday forever.

### Weekends

```text
Saturday-Sunday
```

### Specific weekdays

Examples:

```text
Monday, Wednesday, Friday
```

```text
Tuesday, Thursday
```

### Custom recurrence

Where practical, support:

- Every N days
- Every N weeks
- Every N months
- Specific day of month
- First/second/third/etc. weekday of a month
- Custom date selections

Advanced recurrence can be implemented after the MVP.

### Zero eligible days in a period

If a goal's eligible-days rule produces **zero eligible days** within an entire evaluation period (week or month), that period is shown **RED** in that goal's view — not gray/neutral. This is a deliberate departure from the general "gray = no goal scheduled" convention (§20): a goal that exists but whose rule produced no eligible days for a period is a misconfiguration signal ("goal exists but produced nothing this period"), not an absence of a goal, and should be visibly flagged rather than silently ignored.

---

## 14. Critical Scheduling Example

The system MUST support:

> "Do something 3 times a week, only on workdays."

Representation:

```text
Frequency: Weekly
Eligible days: Monday-Friday
Target: At least 3
Tracking: Counter
```

Example:

```text
Monday    Done
Tuesday   Done
Wednesday Not done
Thursday  Done
Friday    Not done
```

Result:

```text
Weekly target achieved: YES
```

The goal should not require the user to perform it on Saturday/Sunday because those dates are outside the eligible schedule.

---

## 15. Other Scheduling Examples

### Example A — Once every day

```text
Evaluation: Daily
Eligible days: Every day
Target: Exactly 1
```

### Example B — Three times per week

```text
Evaluation: Weekly
Eligible days: Every day
Target: At least 3
```

### Example C — Three times per week on workdays

```text
Evaluation: Weekly
Eligible days: Monday-Friday
Target: At least 3
```

### Example D — Monday, Wednesday, Friday

```text
Evaluation: Weekly
Eligible days: Monday, Wednesday, Friday
Target: Exactly 3
```

### Example E — Weekends only

```text
Evaluation: Weekly
Eligible days: Saturday, Sunday
Target: At least 1
```

### Example F — Monthly target

```text
Evaluation: Monthly (calendar month)
Eligible days: Every day
Target: At least 8
```

---

## 16. Goal Versioning (Edit History as Dated Segments)

This is a foundational mechanism that unifies several parts of the app: mid-period rule edits, pause/resume (§10.1), and the goal detail timeline (§27).

### 16.1 Core rule

Editing a goal's schedule, target, eligible days, or comparison rule **mid-period does not mutate the existing rule retroactively**. Instead, the edit closes the current version segment (`effectiveTo` = the date of the edit) and opens a **new dated version segment** of the same logical goal (same `goalId`, same name). Past evaluation is never rewritten: any week/month that was evaluated under the old rule keeps that evaluation, even after the rule changes going forward.

### 16.2 Why

This guarantees:

- Historical calendar cells and statistics never change retroactively because of a later edit.
- Pause/resume (§10.1) is just a special case of a version segment with no eligible days.
- A period that straddles a version boundary (e.g., a goal changes from 3x/week to 5x/week mid-week) is evaluated using the eligible days and targets that applied on each specific date, not a single rule applied to the whole period. (Note: because monthly/weekly evaluation is period-based, a version change mid-period is an edge case the evaluator must handle explicitly — e.g. by pro-rating eligible days per segment within the period, or by using the rule in effect at period start, per app-specific evaluator design; the key invariant is that logs before the edit are never re-evaluated against the new rule.)

### 16.3 Goal detail timeline

The goal detail screen (§27) must show a timeline of these version segments, for example:

```text
3x/week   Jan 1 – Mar 14
5x/week   Mar 15 – present
```

Each segment in the timeline should show its date range and its rule summary (schedule, target, comparison).

### 16.4 Deletion and versioning

As stated in §10.2, deleting a goal preserves its full version history in the Archived view rather than discarding it.

---

## 17. Tracking Types

Goals can be Boolean or quantitative (Counter).

### 17.1 Boolean

Example:

```text
Meditation
Done: Yes/No
```

Useful for goals such as: workout, read, meditate, take an action, study.

### 17.2 Counter (quantitative)

Example:

```text
Water
Target: 8 glasses/day
Actual: 6
```

The user should be able to increment/decrement the value easily. See §19 (Negative Entries) for the rules on decrementing below zero.

---

## 18. Target Comparison Rules

Goal creation exposes exactly **three** target-comparison options to the user:

| Option | Meaning | Evaluation |
|---|---|---|
| Less than X (maximum) | The value must not exceed X | `actual <= target` |
| Exactly X | The value must equal X | `actual == target` |
| At least X (minimum) | The value must reach or exceed X | `actual >= target` |

A fourth option, **Range**, is available but **only for Counter/quantitative goals** — it is never offered for Boolean goals (a Boolean has no meaningful range).

```text
Sleep
Target range: 7-9 hours
Evaluation: 7 <= actual <= 9
```

### 18.1 Examples

**Minimum**

```text
Exercise
Minimum: 30 minutes/day
Evaluation: actual >= target
```

**Maximum**

```text
Coffee
Maximum: 2 cups/day
Evaluation: actual <= target
```

This is important because not every goal is something the user wants to maximize.

**Exact**

```text
Medication/Activity
Exactly: 2 times/day
Evaluation: actual == target
```

The exact-target option exists for goals where over-achievement is not simply "better" (e.g., a fixed medication dose or a fixed-repetition activity) — the user picks the comparison that matches their real intent. There is no separate "failure if over-achieved" rule layered on top of Exact; the three comparison options plus Range together cover the needed cases.

---

## 19. Negative Entries and the Floor-at-Zero Rule

Individual counter entries (deltas) **can be negative**. Decrementing is a legitimate correction mechanism — e.g., the user logged 3 glasses of water by mistake and corrects it with a −1 entry. This is consistent with the existing increment/decrement requirement for counters (§17.2).

The **aggregated daily total**, however, is **floored at 0**: it is never displayed or stored as a negative number, regardless of how the individual deltas sum. If the sum of deltas for a day would be negative, the displayed/stored total for that day is 0.

---

## 20. Daily Logs

Tracking data should be stored as dated records.

Conceptually:

```text
GoalLog
  id
  goalId
  date
  value
  completed
  note
  timestamp
```

A log can represent:

**Boolean**

```text
completed = true
```

**Quantitative**

```text
value = 6   (a single delta or an aggregated total, per §21)
```

The exact database design may separate numeric and Boolean values or use a type-safe value representation.

---

## 21. Multiple Entries Per Day

The design should support multiple entries for the same goal on a single date.

Example:

```text
Water
08:00 -> +2 glasses
12:00 -> +2 glasses
17:00 -> -1 glass (correction)
21:00 -> +2 glasses
```

Total: `5 glasses` (never negative — see §19).

This is useful for counter-based goals. The MVP can alternatively provide a single aggregated daily value, but the architecture should not prevent multiple entries later.

---

## 22. Daily Calendar Status

Every calendar date should have a status.

### Green
Goal(s) completed / target achieved.

### Red
Scheduled goal target failed, **or** the period had zero eligible days (§13, "Zero eligible days in a period").

### Yellow
Cheat day marking activated for the day, if it comes from the goal and is valid (§24).

### Gray
No goal scheduled for that date.

### Blue / neutral
Future date, or a current-period date whose weekly/monthly outcome is not yet mathematically determined (§22.1) — not yet evaluated.

The exact visual palette should remain configurable through the app theme.

### 22.1 Day-level status for weekly/monthly goals

For a **weekly or monthly** goal, an individual day's cell is **not** simply "pass" or "fail" the way a daily goal's is. A day within such a period only turns **red** once failure has become **mathematically certain** — i.e., even if every remaining eligible day in the period were completed, the target could no longer be reached. Until that point, the day stays **neutral** (blue), even if it was not completed, because the period can still be salvaged by later eligible days.

Example: a "3x/week" goal with Monday–Friday eligible, evaluated on Wednesday having completed 0/3 so far — Wednesday is not red yet, because Thursday and Friday could still deliver 3/3. If Thursday is also missed, then even completing Friday can only reach 1/3, so at that point the days that made the target unreachable become red.

### 22.2 Today page and explicit "did not finish"

The Today page lists goals still owed toward the current weekly/monthly quota (e.g., "Gym: 1 more this week"). The user may explicitly mark a goal as **"did not finish"** for that specific day, rather than simply leaving it unlogged.

This explicit per-day fail mark is, however, **superseded by the period's overall outcome**: if the week/month still passes overall (the quota is met via other days), that specific day is **not** shown as failed in the daily view or in statistics — the week only shows as failed if the weekly/monthly target itself was not met. The explicit mark is a personal note/intent signal for the user in the moment, not an override of the final period computation.

---

## 23. Calendar Evaluation Principle (Derived, Not Stored) and Caching Policy

Calendar colors should be **derived from goal rules and logs**, not treated as the source of truth.

Do not store:

```text
2026-08-05 = GREEN
```

as the primary data. Instead store:

```text
Goal version rules
+
Goal logs
+
Cheat days
```

and calculate:

```text
Date status = evaluation result
```

This ensures that editing a goal (i.e., creating a new version segment, §16) or changing a target correctly affects only the relevant future evaluation, never retroactively rewriting historical status.

### 23.1 Caching policy

- The **live calendar week/month view** is **not cached** — it is computed on the fly from rules + logs every time it is displayed, per the derived-not-stored principle above.
- A **lightweight per-day status cache** is maintained, but only for two consumers: **widgets** (§30) and **long-range statistics** (§28). This cache stores the precomputed status (completed/failed/pending) per goal per day.
- Cache invalidation is scoped using **goal-version date boundaries** (§16): when a goal's version segment changes, only the cached entries within that segment's affected date range are invalidated/recomputed, not the entire cache.

### 23.2 Period finality

A week/month's evaluation becomes **final the instant the calendar period ends** — no further logs can affect a period once its last day has passed, even though the actual computation of that finality stays lazy (it is only actually computed/materialized the next time the app is opened and the derived evaluation runs). In other words, finality is a logical property of the timestamp, not something that requires a background job to "seal" the period at midnight.

---

## 24. Daily View

The user must be able to tap a calendar date and enter that day's data.

Example:

```text
August 8

Today's Goals

[✓] Read
    30 pages

[ ] Workout
    0 / 1

[✓] Water
    8 / 8 glasses

[ ] Meditation
```

The user should be able to:

- Mark Boolean goals complete/incomplete
- Increment/decrement counters (including negative corrections, §19)
- Enter numeric values
- Edit values
- Add notes
- Mark the day as a cheat day
- Mark a weekly/monthly goal "did not finish" for that day (§22.2)
- See which targets are currently met
- See the day's overall status

---

## 25. Cheat Days

Cheat days are a first-class feature.

The user must be able to manually designate a date as a cheat day.

Calendar status: `Yellow`.

The user should be able to:

- Mark a day as cheat
- Remove cheat status
- Optionally add a reason/note

### 25.1 Cheat-day quota

Cheat-day quota is defined **per goal**, configured as **X per week or X per month**, and **defaults to 0** if unset. A goal with a 0 quota has no cheat-day allowance unless the user explicitly configures one.

### 25.2 Cheat days do not reduce Exact targets

A cheat day does **not** reduce an Exact (`==`) target. For example, a goal defined as "exactly 3x/week, 1 cheat day allowed" still requires **3 actual completions** to pass — the cheat day does not lower the number needed to 2. The cheat day's only effect is to **exempt that specific day from counting against the person** (e.g., it doesn't count as a missed/failed eligible day, and it doesn't consume an otherwise-required eligible slot in a way that would make the target impossible). The target value itself never changes because of a cheat day.

This same principle (exemption, not target reduction) applies uniformly across Minimum, Maximum, Exact, and Range comparison rules — a cheat day removes that day from consideration, it does not adjust the numbers.

---

## 26. Weekly Calendar

The app must provide a week view, honoring the user's configured week-start day (§6.2).

A week should show:

- Dates
- Goal completion
- Daily status (subject to §22.1's "red only when certain" rule)
- Weekly target progress
- Overall weekly status

Example:

```text
             Mon Tue Wed Thu Fri Sat Sun

Workout       ✓   ✓   -   ✓   -   -   -
Target: 3/week

Result: 3/3
Status: GREEN
```

---

## 27. Goal Details Screen

Each goal should have a dedicated detail page. It should display:

- Goal name
- Description
- Current schedule/target/tracking type (from the current version segment)
- Start/end dates
- **Version timeline** — the goal's dated version segments, e.g. "3x/week Jan–Mar, then 5x/week from Mar" (§16.3)
- Current streak
- Longest streak
- Completion percentage
- Historical calendar
- Weekly/monthly statistics
- Edit action (creates a new version segment, §16)
- Pause/resume action (also a version segment, §10.1)
- Archive/delete action (§10.2)

---

## 28. Statistics

The application should support statistics such as:

- Current streak
- Longest streak
- Completion percentage
- Daily completion percentage
- Weekly completion percentage
- Monthly completion percentage
- Number of successful periods
- Number of failed periods
- Number of cheat days
- Average value
- Total value
- Goal history (across version segments)

Potential visualizations:

- Calendar heatmap
- Line charts
- Bar charts
- Progress rings
- Weekly summaries
- Monthly summaries

Long-range statistics may read from the per-day status cache (§23.1) rather than recomputing the full evaluation for the entire history each time.

---

## 29. Streaks

The system should support streak calculation. Streak semantics must be rule-aware.

For example, a weekly goal of 3 times/week should not require three consecutive days. The streak should be based on successful evaluation **periods**, not raw consecutive days, for weekly/monthly goals:

```text
Week 1 = PASS
Week 2 = PASS
Week 3 = PASS
Week 4 = FAIL

Current streak: 3 weeks
```

A daily-evaluated goal (§12) can have a genuine daily streak, since each day independently passes or fails.

---

## 30. Notifications

Use local notifications. Notifications should not require a server.

Potential features:

- Reminder at a specific time
- Multiple reminders per day
- Reminder only if goal is incomplete
- Reminder before the evaluation period ends
- Weekly target reminder
- End-of-day reminder

Example:

```text
8:00 PM

You still need 1 more workout
to complete this week's goal.
```

The notification scheduler should account for:

- Goal start/end dates
- Eligible days
- Disabled goals
- Completed targets

### 30.1 Cancellation on lifecycle change

A pending (scheduled but not yet fired) notification is **cancelled** if its goal is **paused, archived, or deleted** before it fires. Notifications only fire for goals that are still active at fire time.

---

## 31. Phone Widgets

Widgets are a high-priority desirable feature. There are exactly **three separate widget types**:

1. **Today widget** — shows today's goal progress (e.g., "3 / 5 goals complete").
2. **Week widget** — shows the current week's per-day/per-goal progress.
3. **Month widget** — shows the current month's overall progress.

### 31.1 Widgets render precomputed status only

Widgets **never run evaluation themselves**. They only render the **precomputed per-goal status** (completed / failed / pending) that the app writes to the per-day status cache (§23.1) during normal app use. This keeps widget refresh cheap and avoids re-implementing the rule engine inside a widget's limited refresh budget.

### 31.2 Widget tap routing

Tapping a widget routes into the app at **its own corresponding view**: the Today widget opens the Today view, the Week widget opens the Week view, and the Month widget opens the Month view. Widgets do not need to route to a specific goal or a specific date beyond the view they represent.

### 31.3 Android

Potential widget sizes:

**Small**
```text
Today's Progress
3 / 5
```

**Medium**
```text
Today's Goals
✓ Read
✓ Water
○ Workout
3/5
```

**Large**
```text
Weekly Progress
Mon ✓  Tue ✓  Wed ✗  Thu ✓  Fri ✓  Sat -  Sun -
5 / 7
```

### 31.4 iOS

Potential support:

- Home Screen widgets
- Lock Screen widgets where technically appropriate
- Small/medium/large widget families where supported

Widgets should primarily display locally stored information. No server is required for widget functionality.

---

## 32. Widget Interaction

Where platform APIs allow:

- Open the app to the relevant view (§31.2).
- Potentially support quick actions such as marking a Boolean goal complete directly from the widget.

Do not assume full interactive widget capabilities are identical on Android and iOS. Platform-specific implementations are acceptable.

---

## 33. Backup and Restore

Because the app is local-only, data loss is a major consideration.

### 33.1 Export

Export the complete application state to a portable file.

Preferred: `JSON`. Potential future: `ZIP`.

Include:

- Goals (with full version-segment history)
- Logs
- Cheat days
- Settings
- Categories
- Notifications
- Metadata (schema version, export timestamp)

### 33.2 Import

Allow the user to restore from an exported file. The import process must validate the file and reject it with a clear reason when invalid.

**Full import rejection list:**

- Malformed JSON / wrong file type.
- Schema version too new (exported by a newer app version than this one understands).
- Missing required structure (no `goals` array, no `metadata`, etc.).
- Duplicate goal IDs within the file.
- Orphaned logs referencing a nonexistent `goalId`.
- Invalid dates: malformed date values, or an `endDate` earlier than `startDate`.
- Invalid/contradictory rules: `min > max`, negative target, unknown frequency enum value.
- Invalid cheat-day configuration: quota referencing a nonexistent goal, or a negative quota.

An **empty export** (zero goals) is **not** a hard rejection — it is flagged as a distinct **warning** to the user, who can then decide whether to proceed.

### 33.3 Import conflict resolution

If the imported backup file is **older** than the data already on the device (e.g., by export timestamp), the app does **not** silently apply a "newest wins" rule. It always **prompts the user to choose** how to proceed (e.g., keep existing data, overwrite with the import, or merge — exact merge UX is an implementation detail, but silent auto-resolution is explicitly disallowed).

---

## 34. Data Integrity and Failure Handling

If the OS force-kills the app mid-save, the **in-flight entry is simply lost** — there is no recovery/draft mechanism requirement. The only requirement is standard database write atomicity: a half-written record must never be left in a corrupt/partial state. A lost in-flight entry is an acceptable outcome; a corrupted database is not.

---

## 35. Calendar UX

The calendar should make status visible at a glance.

Recommended:

- Month view as default
- Week view (honoring the configured week-start day, §6.2)
- Tap date
- Swipe between months
- Jump to today
- Visual status indicators
- Goal filtering

Potential filters:

```text
All Goals
Goal A
Goal B
Category
```

---

## 36. Goal Creation UX

Goal creation should be guided rather than presenting dozens of fields at once.

Possible flow:

```text
1. Goal name
2. Tracking type (Boolean or Counter)
3. Schedule (evaluation period + eligible days)
4. Target (comparison rule: less than X / exactly X / at least X; Range for Counter only)
5. Start/end date
6. Cheat-day quota (optional, default 0)
7. Reminders
8. Review
9. Save
```

---

## 37. Important Edge Cases

The implementation must explicitly handle:

- Goal starts in the middle of a week.
- Goal ends in the middle of a week.
- Goal starts in the middle of a month.
- Goal ends in the middle of a month.
- Leap years.
- Different month lengths.
- Midnight/date-boundary rollover while the app is open (§6.3), including auto-commit of unsaved mid-edit entries.
- Future dates (shown as neutral/blue until evaluated, §22).
- Archived goals (retain full version history, §10.2).
- Disabled/paused goals (a version segment with no eligible days, §10.1).
- Goals with no eligible days in a period (shown RED, §13).
- Cheat days, including per-goal quota defaults and the no-reduction-of-Exact-targets rule (§25).
- Editing a goal after historical logs exist (creates a new version segment; past evaluation is never rewritten, §16).
- Deleting a goal (converges with archive, preserving version history, §10.2).
- Changing target values (new version segment).
- Changing schedules (new version segment).
- Mid-period version boundaries (a period whose eligible days/target changed partway through, §16.2).
- Duplicate logs.
- Multiple entries per day (§21).
- Empty values.
- Negative values: invalid for most single-value Boolean fields, but explicitly valid for counter deltas as corrections, floored at 0 in the aggregate (§19).
- Decimal quantities where appropriate.
- A day explicitly marked "did not finish" that is later superseded by the period passing overall (§22.2).
- A weekly/monthly goal's day-level color only turning red once failure is mathematically certain (§22.1).
- Import of a file with any of the rejection conditions in §33.2, and the distinct "empty export" warning.
- Import of a backup older than on-device data (always prompts the user, never silent newest-wins, §33.3).
- Pending notifications for goals paused/archived/deleted before the notification fires (cancelled, §30.1).
- App force-killed mid-save (entry lost, DB stays atomic/uncorrupted, §34).
- Widget rendering relying only on precomputed cached status, never running evaluation itself (§31.1).

**Explicitly out of scope (by design decision):**

- Time zones and daylight-saving transitions are **not** handled; see §6.1.

---

## 38. Open Items

All questions raised during the edge-case brainstorming session that produced this document were resolved with an explicit decision before the session concluded (per the session's own process rule: resolve immediately if possible, otherwise capture as an open item). As of this writing, there are **no outstanding open items** carried forward from that session.

Should new open questions arise during implementation, they should be captured in this section following the same pattern: a short problem statement, and either its resolution or its status as still-open.

---
