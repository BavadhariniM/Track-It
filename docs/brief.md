---
title: "Goal Tracker — Product Brief"
status: ready
created: 2026-08-16
updated: 2026-08-16
---

# Product Brief: Goal Tracker

## Executive Summary

Goal Tracker is a personal, offline-first goal planner and habit tracker for Android and iOS, built in Flutter from a single codebase. Unlike typical habit trackers built around daily checkboxes or raw streaks, Goal Tracker is built around a genuine rule engine: goals are defined by frequency, eligible days, and a target (minimum, maximum, exact, or range — boolean or quantitative), and the calendar is a visualization layer that reflects the true evaluated state of those rules rather than asking the user to self-judge compliance. It runs entirely on-device — no account, no login, no server, no cloud dependency — treating the user's data as fully theirs, with manual JSON export/import as the only portability path.

This brief hands a clear, scoped foundation to the project's PM to build the PRD and implementation plan from. The underlying requirements have already been through a dedicated edge-case review — goal versioning, cheat-day semantics, calendar color-timing, widget architecture, import validation — so the rule engine's hardest ambiguities are resolved before implementation begins.

## The Problem

Most habit trackers flatten every kind of commitment into the same shape: a daily checkbox or a raw streak counter. Real commitments rarely fit that shape — "three times a week, but only on workdays," "at least 8 times this month," "exactly 2 doses a day," "cap coffee at 2 cups a day" — and get left for the user to interpret and self-track manually, which quietly erodes trust in whatever status the app reports back. Layered on top, most trackers also require an account and cloud sync for what is a fundamentally private, personal record — trading data ownership for basic functionality that shouldn't require it.

## The Solution

Goal Tracker separates three concerns that most trackers conflate: how often a goal must happen (frequency/evaluation period), which days it's even eligible to happen on (eligible-day rules), and how progress is measured (boolean or quantitative, with min/max/exact/range comparisons). The rule engine evaluates these automatically; the calendar is a pure visualization of the result — a day only turns red once failure becomes mathematically certain, never simply because it hasn't been logged yet.

## What Makes This Different

- **Frequency and eligible-days are separate axes.** Most trackers give you "daily" or "weekly"; this gives you "3×/week, but only Monday–Friday" as a first-class rule, not a workaround.
- **Calendar status is derived, never stored.** It's recomputed from rules + logs, so editing a goal never requires a data migration or leaves stale colors behind.
- **Goal versioning.** Mid-period edits, pauses, and resumes open a new dated segment instead of silently rewriting the past; the goal detail view can show its own edit history as a timeline.
- **Cheat days as a quota-based, per-goal concept**, not a hidden exception bolted onto the UI.
- **Fully offline, no account, no server.** Privacy and data ownership by construction, not an add-on setting.

Honestly stated: the moat here is the care and correctness of the rule engine's edge-case handling — not technical novelty. It's an execution advantage, not a defensible one, and should be treated as such.

## Who This Serves

Primary: the builder themself — someone who wants precise, flexible habit/goal tracking that actually matches how they structure commitments, and who values full data ownership over convenience features like cloud sync. Whether this later serves a wider audience beyond personal use is undecided; the design does not currently assume or require it.

## Success Criteria

- **The app works as intended on both Android and iOS** — this is the stated bar for success: functional cross-platform parity from the shared Flutter codebase, not just an Android-first build with iOS as an afterthought.
- The rule engine evaluates every scheduling pattern in the requirements doc correctly — including the resolved edge cases (goal versioning, cheat-day/exact-target interaction, color-timing, zero-eligible-day periods) — with no silent data loss.
- The requirements are complete and unambiguous enough that the PM/PRD process can scope epics and stories without re-opening rule-engine questions.

## Scope

**In for v1:**
- Goal CRUD and full lifecycle (active / paused / archived / expired), with goal versioning so edits and pause/resume never rewrite history.
- Boolean and Counter tracking, including multi-entry-per-day and negative correction deltas (floored at 0).
- Eligible-day scheduling (every day, weekdays/weekends, specific weekdays), decoupled from evaluation frequency (daily/weekly/monthly/yearly).
- At Least/At Most/Exactly target comparisons (no bounded/range comparison).
- Cheat-day marking with per-goal quotas (default 0).
- Day, week, and month calendar views with color-coded, mathematically-timed status.
- Daily entry screen; goal detail screen with version timeline, streaks, and stats.
- Period-aware streak calculation (not raw-consecutive-day for weekly/monthly goals).
- Local notifications tied to goal lifecycle.
- Three home-screen widgets (Today / Week / Month) rendering precomputed status.
- Manual JSON export/import with validation (schema version, structure, duplicate IDs, orphaned logs, invalid dates/rules) and user-driven conflict resolution.
- Configurable week-start day (default Monday).

**Explicitly out for v1:**
- Cloud sync/backup and any authentication (deferred; would be designed separately if pursued).
- Web version.
- Advanced custom recurrence beyond the MVP set (every-N-days, Nth-weekday-of-month, custom date selections).
- CSV or ZIP export formats.
- Percentage-based, conditional, or goal-dependency rule types.
- Any cross-device sync beyond manual export/import.
