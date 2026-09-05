---
title: 'Bug 3: Add Goal entry point missing from Goals view'
type: 'bugfix'
created: '2026-08-31'
status: 'done'
route: 'one-shot'
---

## Intent

**Problem:** Panda can only start creating a new Goal from Day View's floating action button — `GoalsListScreen` (the persistent "Goals" tab) has no create entry point at all, in any state (empty, loaded, loading, error), so reaching the wizard requires navigating away to Day View first.

**Approach:** Add a `FloatingActionButton` to `GoalsListScreen` that mirrors `DayViewScreen._openCreateGoal` — reset `goalWizardProvider` then push `GoalCreationWizard` — but keep it always visible (unlike Day View's FAB, which hides when the goal list is empty because Day View's empty state has its own inline create button; Goals view has none, so hiding it here would leave no create path at all).

## Suggested Review Order

**Entry point**

- New always-visible FAB opens `GoalCreationWizard` via the same reset-then-push pattern as Day View, with an explicit `Key`, a `tooltip`, and extra bottom `ListView` padding so it never occludes the last goal group.
  [`goals_list_screen.dart:53`](../../lib/presentation/screens/goals/goals_list_screen.dart#L53)

**Deferred (see `deferred-work.md`)**

- Stale class-level doc comment claiming no persistent tab bar exists yet — predates this change.
- No re-entrancy guard against rapid FAB double-taps, on both this screen and `DayViewScreen` — pre-existing pattern, not introduced here.
