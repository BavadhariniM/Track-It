---
title: 'Bug 1: Day View AppBar always says "Today"'
type: 'bugfix'
created: '2026-08-31'
status: 'done'
route: 'one-shot'
---

## Intent

**Problem:** `DayViewScreen`'s AppBar title was hardcoded to the literal text `'Today'`, so tapping any day in Week View or Month View opened that day's goals under a title claiming it was today — even for dates days or weeks away.

**Approach:** Compute the title from the screen's actual `date` parameter: show `'Today'` only when it matches the real current calendar date (via the codebase's existing one-shot `todayDateOnly()` primitive), otherwise show a readable formatted date (e.g. "Aug 26, 2026") via a new shared `formatDisplayDate` helper.

## Suggested Review Order

**Title logic**

- Entry point — the AppBar now derives its title from the passed-in date instead of a hardcoded string.
  [`day_view.dart:42`](../../lib/presentation/screens/day_view.dart#L42)

- `_titleFor` compares the passed date against `todayDateOnly()` (the codebase's documented one-shot "what date is it right now" primitive) rather than a raw `DateTime.now()`, and delegates non-today formatting to the new shared helper.
  [`day_view.dart:100`](../../lib/presentation/screens/day_view.dart#L100)

**Shared date formatter**

- New `formatDisplayDate` helper extracted alongside the existing `formatDateOnly`, so this fix reuses rather than re-duplicates the month-abbreviation-array pattern already present elsewhere in the codebase.
  [`date_format.dart:29`](../../lib/domain/evaluator/date_format.dart#L29)

**Tests**

- Locks in the "actual today" branch.
  [`day_view_test.dart:57`](../../test/presentation/day_view_test.dart#L57)

- Locks in the "different day" branch — the exact scenario Bug 1 reported.
  [`day_view_test.dart:65`](../../test/presentation/day_view_test.dart#L65)
