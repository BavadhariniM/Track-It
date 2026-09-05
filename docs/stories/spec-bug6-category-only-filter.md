---
title: 'Bug 6: Calendar filter bar is category-only'
type: 'bugfix'
created: '2026-08-31'
status: 'done'
route: 'one-shot'
---

## Intent

**Problem:** The Calendar filter bar (Day/Week/Month) rendered a chip per individual goal alongside "All" and category chips, but Panda only wants to filter by category — per-goal chips were noise.

**Approach:** Removed the per-goal `_FilterChip` loop from `GoalFilterBar`, leaving only "All" and category chips. The underlying domain `GoalFilterSingle` type was left in place (now unreachable from the UI — tracked in deferred work) rather than deleted, since removing a tested domain type is a separate decision from hiding its UI entry point.

## Suggested Review Order

- Removed the per-goal chip loop; only "All" and category chips remain.
  [`goal_filter_bar.dart:36`](../../lib/presentation/components/goal_filter_bar.dart#L36)

- Regression guard: asserts no per-goal chip renders for either fixture goal.
  [`goal_filter_bar_test.dart:119`](../../test/presentation/goal_filter_bar_test.dart#L119)
