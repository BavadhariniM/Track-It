# Offline Cross-Platform Goal Planner / Calendar — Requirements

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

---

# 2. Core Product Concept

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
- Do something n times a week / on these specific days
- Track a quantitative value such as water intake, hours slept, pages read, etc.
- Track a simple Boolean completion state.
- Mark a day as a cheat day.

The application evaluates these rules automatically and represents the resulting status visually.

the calender visualization must have details about whether the day completed with all goals, / whether the week completed with all goals (by sowing colour). current days / weeks and future days / week must wait for the goal status to be updated, if not consider as not updated.

---

# 3. Primary Goals

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

---

# 4. Platform Requirements

## 4.1 Primary Platforms

- Android
- iOS

## 4.2 Framework

Use:

- Flutter
- Dart

A single Flutter codebase should be used wherever possible.

or come up with other possibilities to support the same


# 5. Offline-First / Privacy Requirements

The application must be **local-first**.

## Required behavior

The app must work without:

- Internet
- Login
- User account
- Backend server
- Cloud database

All core functionality must operate using the local device database.

# 6. Database Requirements

## 6.1 Database

Use a local database.


No cloud database should be required.

should have options for importing and exporting the entire database and use in any device

## 6.2 Data Safety

The app should provide:

- Manual export
- Manual import
- Local backup capability

Preferred export format:

- JSON

Potential future formats:

- ZIP containing JSON and attachments
- CSV for logs/statistics

The exported data should be sufficient to reconstruct the user's goals, logs, settings, and cheat days.

---

# 7. No Authentication

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

# 8. Goal Model

A goal represents something the user wants to track.

A goal should have at least:

```text
id
name
description
category
icon
color

enabled
archived

startDate
endDate
hasEndDate

frequency
evaluationRule
targetValue

eligibleDays / eligible dates

cheatDayConfiguration -> for a specific goal , how many cheat days in a week / month if accepted

priority-> options -> come up with options

createdAt
updatedAt
```

The exact database representation can be normalized into separate entities where appropriate.

---

# 9. Goal Lifecycle

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

Archived goals should not appear in normal active tracking views but should remain available for historical data unless explicitly deleted.

if we pause and replay a goal, it must be appropriately tracked for those days alone and the calender must show only the goals created for that specific time frame

---

# 10. Start and End Dates

Every goal must support:

### Start date

The date from which the goal becomes active.

### End date

Optional.

The user can choose:

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

The latter means the goal continues indefinitely until disabled/archived/stopped.

---

# 11. Goal Frequency

The application should support at least:

- Daily
- Weekly
- Monthly
- Yearly
- Custom/advanced recurrence

Frequency and eligible-day rules should be separate concepts.

For example:

```text
Evaluation period = Weekly
Eligible days = Monday-Friday
Target = At least 3
```

This means the user needs to complete the goal at least 3 times during the eligible workdays of each week.

---

# 12. Eligible Days / Schedule Rules

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

come up with other required options as well

Advanced recurrence can be implemented after the MVP.

---

# 13. Critical Scheduling Example

The system MUST support:

> "Do something 3 times a week, only on workdays."

Representation:

```text
Frequency:
Weekly

Eligible days:
Monday-Friday

Target:
At least 3

Tracking:
Counter
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

# 14. Other Scheduling Examples

## Example A — Once every day

```text
Evaluation: Daily
Eligible days: Every day
Target: Exactly 1
```

## Example B — Three times per week

```text
Evaluation: Weekly
Eligible days: Every day
Target: At least 3
```

## Example C — Three times per week on workdays

```text
Evaluation: Weekly
Eligible days: Monday-Friday
Target: At least 3
```

## Example D — Monday, Wednesday, Friday

```text
Evaluation: Weekly
Eligible days: Monday, Wednesday, Friday
Target: Exactly 3
```

## Example E — Weekends only

```text
Evaluation: Weekly
Eligible days: Saturday, Sunday
Target: At least 1
```

## Example F — Monthly target

```text
Evaluation: Monthly
Eligible days: Every day
Target: At least 8
```

---

# 15. Tracking Types

Goals can be Boolean or quantitative.

## 15.1 Boolean

Example:

```text
Meditation

Done: Yes/No
```

This is useful for goals such as:

- Workout
- Read
- Meditate
- Take an action
- Study

---

## 15.2 Counter

Example:

```text
Water

Target: 8 glasses/day
Actual: 6
```

The user should be able to increment/decrement the value easily.

---

## 15.3 Minimum

Example:

```text
Exercise

Minimum: 30 minutes/day
```

Evaluation:

```text
actual >= target
```

---

# 16. Maximum

Example:

```text
Coffee

Maximum: 2 cups/day
```

Evaluation:

```text
actual <= target
```

This is important because not every goal is something the user wants to maximize.

---

# 17. Exact Target

Example:

```text
Medication/Activity

Exactly: 2 times/day
```

Evaluation:

```text
actual == target
```

---

# 18. Range Target

Example:

```text
Sleep

Target range: 7-9 hours
```

Evaluation:

```text
7 <= actual <= 9
```

---

# 19. Future Extensibility

The rule engine should be designed so new rule types can be added without redesigning the entire database.

Potential future rules:

- Percentage targets
- Increasing/decreasing targets
- Streak-dependent targets
- Conditional goals
- Goal dependencies
- Time-of-day requirements
- Duration tracking
- Numeric accumulation
- Multiple measurements per day

---

# 20. Daily Logs

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

### Boolean

```text
completed = true
```

### Quantitative

```text
value = 6
```

The exact database design may separate numeric and Boolean values or use a type-safe value representation.

---

# 21. Multiple Entries Per Day

The design should support multiple entries for the same goal on a single date.

Example:

```text
Water

08:00 -> 2 glasses
12:00 -> 2 glasses
17:00 -> 2 glasses
21:00 -> 2 glasses
```

Total:

```text
8 glasses
```

This is useful for counter-based goals.

The MVP can alternatively provide a single aggregated daily value, but the architecture should not prevent multiple entries later.

---

# 22. Daily Calendar Status

Every calendar date should have a status.

Suggested statuses:

### Green

Goal(s) completed / target achieved.

### Red

Scheduled goal target failed.

### Yellow

Cheat day marking activated for the day if it comes from the goal and it is valid

### Gray

No goal scheduled for that date.

### Blue or neutral future status

Future date that has not yet been evaluated.

The exact visual palette should remain configurable through the app theme.

---

# 23. Important Calendar Evaluation Principle

Calendar colors should be **derived from goal rules and logs**, not treated as the source of truth.

Do not store:

```text
2026-08-05 = GREEN
```

as the primary data.

Instead store:

```text
Goal rules
+
Goal logs
+
Cheat days
```

and calculate:

```text
Date status = evaluation result
```

This ensures that editing a goal or changing a target can correctly recalculate historical/future status.

Cached evaluations may be added later for performance.

---

# 24. Daily View

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
- Increment/decrement counters
- Enter numeric values
- Edit values
- Add notes
- Mark the day as a cheat day
- See which targets are currently met
- See the day's overall status

---

# 25. Cheat Days

Cheat days are a first-class feature.

The user must be able to manually designate a date as a cheat day.

Calendar status:

```text
Yellow
```

The user should be able to:

- Mark a day as cheat
- Remove cheat status
- Optionally add a reason/note

Possible future feature:

```text
2 cheat days/month
```

The architecture should allow cheat-day quotas later.

---

# 26. Cheat Day Semantics

The exact treatment of cheat days should be configurable.

Possible default:

- Scheduled goals are not considered failed for that day.
- The calendar displays yellow.
- The cheat day is explicitly visible in the daily view.
- Weekly/monthly evaluation should define whether a cheat day counts as an exempt day or consumes an allowed quota.

This should be specified clearly in the rule engine rather than hardcoded into calendar UI.

---

# 27. Weekly Calendar

The app must provide a week view.

A week should show:

- Dates
- Goal completion
- Daily status
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

# 28. Weekly Evaluation

For weekly goals, the system should evaluate the complete weekly period.

Example:

```text
Goal:
Gym

Eligible days:
Monday-Friday

Target:
At least 3

Actual:
4
```

Result:

```text
PASS
```

If:

```text
Actual:
2
```

Result:

```text
FAIL
```

---

# 29. Monthly Calendar

The application must provide a monthly calendar.

The month view should allow the user to quickly identify:

- Successful days
- Failed days
- Cheat days
- Days with no scheduled goals
- Overall monthly progress

Tapping a date opens the daily view.

---

# 30. Monthly Evaluation

Monthly goals should evaluate against the monthly period.

Example:

```text
Read

Target:
At least 8 times/month
```

The user may perform it on any eligible day unless a day restriction is defined.

---

# 31. Goal Dashboard

The home/dashboard screen should show useful information such as:

- Today's progress
- Today's goals
- Goals completed
- Goals remaining
- Current streak
- Weekly progress
- Monthly progress
- Upcoming reminders

Example:

```text
Today

3 / 5 goals complete

✓ Read
✓ Water
✓ Workout
○ Study
○ Meditation
```

---

# 32. Goal Details Screen

Each goal should have a dedicated detail page.

It should display:

- Goal name
- Description
- Schedule
- Target
- Tracking type
- Start/end dates
- Current streak
- Longest streak
- Completion percentage
- Historical calendar
- Weekly/monthly statistics
- Edit action
- Archive/pause action

---

# 33. Statistics

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
- Goal history

Potential visualizations:

- Calendar heatmap
- Line charts
- Bar charts
- Progress rings
- Weekly summaries
- Monthly summaries

---

# 34. Streaks

The system should support streak calculation.

However, streak semantics must be rule-aware.

For example:

A weekly goal of 3 times/week should not require three consecutive days.

The streak should be based on successful evaluation periods.

Example:

```text
Week 1 = PASS
Week 2 = PASS
Week 3 = PASS
Week 4 = FAIL
```

Current streak:

```text
3 weeks
```

Similarly, a daily goal can have a daily streak.

---

# 35. Notifications

Use local notifications.

Notifications should not require a server.

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

---

# 36. Phone Widgets

Widgets are a high-priority desirable feature.

## Android

Potential widgets:

### Small

```text
Today's Progress

3 / 5
```

### Medium

```text
Today's Goals

✓ Read
✓ Water
○ Workout

3/5
```

### Large

```text
Weekly Progress

Mon ✓
Tue ✓
Wed ✗
Thu ✓
Fri ✓
Sat -
Sun -

5 / 7
```

## iOS

Potential support:

- Home Screen widgets
- Lock Screen widgets where technically appropriate
- Small/medium/large widget families where supported

Widgets should primarily display locally stored information.

No server is required for widget functionality.

---

# 37. Widget Interaction

Where platform APIs allow:

- Open the app to the relevant goal/date.
- Potentially support quick actions such as marking a Boolean goal complete.

Do not assume full interactive widget capabilities are identical on Android and iOS.

Platform-specific implementations are acceptable.

---

# 38. Backup and Restore

Because the app is local-only, data loss is a major consideration.

Provide:

### Export

Export the complete application state to a portable file.

Preferred:

```text
JSON
```

Potential future:

```text
ZIP
```

including:

- Goals
- Logs
- Cheat days
- Settings
- Categories
- Notifications
- Metadata

### Import

Allow the user to restore from an exported file.

The import process should validate:

- Schema version
- Data integrity
- Duplicate IDs
- Invalid dates
- Invalid goal rules

---


# 41. Calendar UX

The calendar should make status visible at a glance.

Recommended:

- Month view as default
- Week view
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

# 42. Goal Creation UX

Goal creation should be guided rather than presenting dozens of fields at once.

Possible flow:

```text
1. Goal name
2. Tracking type
3. Schedule
4. Target
5. Start/end date
6. Reminders
7. Review
8. Save
```

---

# 57. Important Edge Cases

The implementation must explicitly handle:

- Goal starts in the middle of a week.
- Goal ends in the middle of a week.
- Goal starts in the middle of a month.
- Goal ends in the middle of a month.
- Leap years.
- Different month lengths.
- Daylight-saving changes where relevant.
- Time zones.
- Midnight/date-boundary issues.
- Future dates.
- Archived goals.
- Disabled goals.
- Goals with no eligible days in a period.
- Cheat days.
- Editing a goal after historical logs exist.
- Deleting a goal.
- Changing target values.
- Changing schedules.
- Duplicate logs.
- Multiple entries per day.
- Empty values.
- Negative values where invalid.
- Decimal quantities where appropriate.

---
