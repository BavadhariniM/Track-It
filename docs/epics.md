---
stepsCompleted: [1, 2, 3]
inputDocuments:
  - docs/prd/index.md
  - docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md
  - docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md
  - docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md
---

# Tracker - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Tracker, decomposing the requirements from the PRD, UX Design (DESIGN.md + EXPERIENCE.md), and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

FR-1: Goal Definition — a user can define a Goal with name, description, Tracking Type, Evaluation Period, Eligible-Days Rule, Target Comparison and value, start date, optional end date. Cannot save without Tracking Type, Evaluation Period, Eligible-Days Rule, Target Comparison.
FR-2: Goal Lifecycle — Active/Paused/Archived/Expired states; create/edit/pause/resume/archive. "Delete" = "Archive," no hard delete. Archived goals hidden from active views, visible in history. Paused goals produce no Eligible Days for the paused range.
FR-3: Goal Versioning — editing rules or pause/resume creates a new dated Goal Version rather than mutating history. A day logged before a rule change evaluates against the Version active on that date.
FR-4: Derived Status — status always computed from rules+logs+Cheat Days at read time, never stored as source of truth. A future/uncertain date shows Pending, never Gray, never Red until certain.
FR-5: Zero-Eligible-Days Signal — a period with zero Eligible Days shows red, not gray (deliberate misconfiguration flag).
FR-6: Guided Goal Creation — 7-step guided flow (name → tracking type → schedule → target → dates → reminders → review), each step validates before proceeding, back-navigation to edit. Must clearly distinguish a daily-evaluated goal with Cheat Days (real daily Streak) from a weekly-evaluated count goal (week-level pass/fail, no daily Streak).
FR-7: Evaluation Period Types — Daily, Weekly, Biweekly, Monthly, Quarterly, Yearly, Rolling Window (N days), Custom. Each has a defined boundary (Weekly follows Week-Start Setting; Rolling Window has no fixed calendar boundary).
FR-8: Eligible-Days Rule — Arbitrary Selection — any subset of weekdays, plus "every day"/"workdays"/"weekends" presets over the same mechanism.
FR-9: Custom Recurrence — every N days/weeks/months, specific day(s) of month, Nth weekday of month, explicit custom date selection. N-day/week/month cycles anchor to Goal start date; Nth-weekday computed per calendar month.
FR-10: Blackout Dates — user can mark specific dates as excluded (e.g. holidays) on any Eligible-Days Rule, from the current day, with optional reason. Exempts the date from failure like a forced Cheat Day but does NOT reduce eligible-day count or target, and does not consume Cheat Day quota.
FR-11: Target Comparison — At Least, At Most, Exactly. At Least has no maximum, At Most has no minimum — no bounded/range comparison exists. All three valid for both Boolean and Counter goals.
FR-12: Free Combination — Evaluation Period, Eligible-Days Rule, Tracking Type, Target Comparison are independent axes and must combine freely (13 worked-example patterns in PRD §4.2 must all be creatable/evaluable).
FR-13: Boolean Entry — mark a Boolean Goal done/not-done for any Eligible Day.
FR-14: Counter Entry — increment/decrement or direct numeric entry with optional note; multiple increments fold into one running daily total (no per-increment timestamp); decimals supported.
FR-15: Corrections — negative Counter value corrects an over-log; day's total floors at 0.
FR-16: Cheat Days — mark a date as Cheat Day for a specific goal, up to per-goal quota (default 0), resets each Evaluation Period. Displays yellow, does not reduce any Target Comparison's required count (applies uniformly across At Least/At Most/Exactly).
FR-17: DNF Marking — explicit DNF mark, superseded by the enclosing period's actual computed outcome once that period closes.
FR-18: Certain-Failure Red — a day/period turns red only once failure is mathematically certain given remaining eligible days, never merely because target isn't hit yet. Before certain, shows Pending.
FR-19: Data-Loss Bound — app killed mid-save loses only that single in-flight entry; all previously committed data survives.
FR-20: Midnight Rollover — app open across midnight auto-commits any unsaved mid-edit entry to the day it was entered on, then performs a full data reload so all in-memory evaluation state recomputes.
FR-21: Day View — tap any calendar date to view/log that day's eligible Goals and status.
FR-22: Week View — week grid shows each Goal's per-day status and the week's overall progress.
FR-23: Month View — default calendar surface; swipe between months; jump to today; each day shows Derived Status.
FR-24: Week-Start Setting — configurable first day of week (Sunday/Monday), default Monday.
FR-25: Goal Filtering — calendar filterable to all Goals, a single Goal, or a category. Goals can be organized into categories — confirmed in MVP scope (not a schema placeholder), per PRD source edit.
FR-26: Dashboard — home screen shows today's eligible Goals with progress, current Streaks, this week's/month's progress rollups, next scheduled reminder time (single global time).
FR-27: Goal Detail Screen — schedule, target, current/longest Streak, completion %, historical calendar, Version Timeline (distinct element from historical calendar, sourced from FR-3 Goal Versions), edit/archive actions.
FR-28: Statistics — current Streak, longest Streak, completion % (daily/weekly/monthly), successful/failed period counts, Cheat Day count, average/total value (Counter), full Goal history. Completion % excludes Paused periods.
FR-29: Rule-Aware Streaks — Streak counts consecutive successful Evaluation Periods (not consecutive days) for any non-Daily Goal. Rolling Window Goals have no Streak stat, only current pace/status.
FR-30: Local Reminders — single global reminder time across all Goals (no per-Goal custom times). Scheduler does not fire for a Goal on a non-eligible day, or for Paused/Archived Goals, or once the current period's target is already met — confirmed, with one exception per PRD source edit: for At Least (≥) goals, reminders continue even after the target is met for that period, since additional logging beyond the minimum may still be wanted.
FR-31: Home-Screen Widgets — exactly three types: Today, Week, Month. No lock-screen widgets. Widgets render only precomputed, cached status, never live evaluation at render time.
FR-32: Widget Tap-Through — tapping a widget opens the app to the relevant date. [ASSUMPTION carried from PRD: exact per-platform tap-through behavior — confirm per platform capability.]
FR-33: JSON Export — export full app state (Goals, logs, Cheat Days, settings, categories, notification config, metadata) to a single portable JSON file.
FR-34: JSON Import (Merge) — import merges into existing local data (not full replace). Rejects: malformed JSON, missing required structure, schema-version mismatch, duplicate IDs, orphaned logs, invalid dates, invalid/contradictory rules, invalid Cheat Day config. Zero-Goal export accepted with a warning, not rejected. Any conflict always prompts the user — never silently resolved.
FR-35: Delete = Archive — deleting a Goal archives it; no hard delete; full history always preserved.
FR-36: Reset / Erase All — separate explicit action wipes all local data, returns to clean first-run state; the only true irreversible deletion. Requires explicit secondary confirmation before executing.

### NonFunctional Requirements

NFR-1: Offline-First, Absolute — 100% of core functionality works with no internet, ever; no login/account/backend/cloud DB, architecturally impossible to require.
NFR-2: Zero Telemetry / Privacy — no telemetry, analytics, or crash reporting of any kind, not even opt-in/anonymous; no third-party network calls at all.
NFR-3: No Timezone/DST Handling — single-device assumption; all evaluation in local device time; no cross-timezone travel or DST adjustment logic.
NFR-4: Single-Device Data — no automatic sync between devices; moving data between devices is manual export/import (merge) only.
NFR-5: Platform Parity — Android and iOS both fully functional at initial release, not sequential/one-primary.
NFR-6: Correctness as Core Quality Bar — edge-case evaluation logic (exotic recurrence, rolling-window, day-boundary cases) is a first-class acceptance bar, must carry into test/acceptance criteria downstream.
NFR-7: Data Durability — only an in-flight unsaved entry is ever at risk (FR-19); everything committed survives app kills, crashes, midnight rollovers (FR-20).

### Additional Requirements

- **Architecture paradigm (AD-1):** layered/hexagonal, domain-centric. `domain` has zero Flutter/Drift imports; `data` and `presentation` depend on `domain`; `domain` depends on neither. Every story's code must respect this layer boundary.
- **State & DI (AD-2):** all cross-layer dependencies exposed as Riverpod providers (`@riverpod` code-gen, 3.x line). No `BuildContext`-coupled domain access, no singleton/service-locator pattern anywhere.
- **Persistence (AD-3):** Drift is the sole local persistence for domain data (goals/versions/logs/cheat days/blackout dates). `shared_preferences` only for simple settings (week-start day, reminder time) outside the Drift schema.
- **Pure evaluator contract (AD-4):** one pure function `DayStatus evaluate({Goal, versions, logs, cheatDays, blackoutDates, date})`, no I/O, no Flutter, no Drift, fully deterministic, sorts its own inputs internally. Every caller (live calendar, CacheWriter, StatsService, widget precompute) shares this one function — no re-implementation anywhere.
- **Version-boundary period splitting (AD-5):** a Version's evaluation window is `[startDate, nextVersion.startDate or goal end]`; boundary = calendar boundary ∩ Version window; truncated segments evaluate in full against their own un-prorated target — no cross-Version blending, no pro-rating formula.
- **GoalService as sole writer (AD-6):** `GoalService` is the only component permitted to write a `GoalVersion` or `GoalLog` — every edit, log entry, correction, and JSON-import write routes through it; enforces correction floor at 0; enforces at most one Version per `(goalId, versionStartDate)`; Reset/Erase-All is a `GoalService` use-case inside one transaction.
- **Status cache (AD-7):** read-optimization only, never source of truth, fully recomputable from `evaluate()`. Domain defines `CacheWriter` interface, `data` implements it. Exactly one writer, invoked after a GoalLog/GoalVersion commit or the midnight-rollover job, inside the same transaction. The live calendar never reads the cache — always calls `evaluate()` fresh.
- **StatsService (AD-8):** sole component computing Streaks and rollups; reads cached `DayStatus`, falls back to `evaluate()` for uncached ranges; no screen/widget computes a streak or rollup independently.
- **Data conventions:** UUIDv4 string ids; naive ISO-8601 date-only strings (`YYYY-MM-DD`), never timezone-aware `DateTime`; domain/use-case failures as `Result`/`Either`-style returns, not thrown exceptions.
- **Transaction atomicity:** every multi-statement domain mutation (a GoalLog write + its cache invalidation, a GoalVersion creation, Reset/Erase-All) executes inside one Drift transaction.
- **Stack (seed, re-verify at build time):** Flutter/Dart current stable; flutter_riverpod ^3.4.2; riverpod_generator/riverpod_annotation ^4.0.8/^4.0.6; drift + drift_flutter 2.32.0+; flutter_local_notifications 21.0.0; home_widget 0.9.3 (data-bridging only, not widget UI).
- **Structural seed (governs Epic 1 Story 1 scaffolding — no external starter template is used):** `lib/domain/{entities,evaluator,services}`, `lib/data/{drift,repositories,cache,io,widget_bridge}`, `lib/presentation/{screens,components,providers}`, `lib/platform/{android,ios}`, `test/domain/`.
- **Native widget UI (Deferred in architecture, resolved by UX):** Today/Week/Month widget UI is native per platform — Kotlin/Jetpack Glance (Android), Swift/WidgetKit (iOS) — a separate implementation track outside the Flutter/Dart paradigm; `widget_bridge/` serializes cached `DayStatus` (date, goalId/scope, status) to the shared container `home_widget` reads.
- **Explicitly deferred by architecture, still open for stories:** `Priority` field on Goal (unresolved; UX spine did not add explicit goal-list ordering, so this stays open — flag if a story needs it); exact pinned package versions (owned by `pubspec.lock` at build time, not a story-level concern); app-store release/CI/signing process (explicitly out of scope for solo-builder v1).

### UX Design Requirements

UX-DR1: Implement the full color token set (light + dark `-dark`-suffixed pairs) for base/surface/text/border/accent plus the 5-state status vocabulary (success/fail/cheat/empty/pending), each with a defined "-on" contrast pair.
UX-DR2: Implement platform-native typography roles (display/title/body/label/meta) via system fonts, plus a `numeric` tabular-figure variant reserved for counter values and stat numbers so digits don't jitter width while updating.
UX-DR3: Implement the rounded-corner scale (sm/md/lg/full); `full` reserved only for status badges and the wizard progress bar, never for primary buttons.
UX-DR4: Implement the 4px-based spacing scale (levels 1-7) uniformly across all screens; no separate spacing track.
UX-DR5: Implement the flat elevation model — no drop shadows anywhere except one defined 1px shadow reserved for the wizard's bottom action bar and modal sheets.
UX-DR6: Build the `status-cell` component (calendar day cell and widget cell): fixed-size square, `rounded.sm`, single status-color fill plus a compact glyph (✓ / ✕ / "C" / ellipsis / dash) so status never depends on color alone, with a screen-reader label speaking the semantic state.
UX-DR7: Build the `goal-row` component: status dot + goal name + "Done" label (Boolean) or progress bar + fraction (Counter/period goals); no inline Cheat Day/Blackout iconography at row level (surfaced on tap-through only).
UX-DR8: Build the `stat-card` component for Goal Detail (Streak, longest Streak, completion %): numeric-heavy, tabular figures, no icons.
UX-DR9: Build the `wizard-progress` component: thin top-of-screen bar filled proportionally across the 7 creation steps; no step numerals shown elsewhere in the UI.
UX-DR10: Build exactly two button tiers — `button-primary` (single forward action per screen) and `button-secondary` (Back/Cancel/Edit); no tertiary/ghost/text-only tier.
UX-DR11: Enforce the Do's/Don'ts as implementation rules: no celebratory motion/sound/badges on goal completion; no second accent color, gradient, or imagery anywhere; `accent` color never used for status; Pending must render visually distinct from both pass and fail, never tinted toward green or red.
UX-DR12: Implement the bottom tab bar IA with exactly 4 tabs — Today, Calendar, Goals, Settings — no drawer navigation.
UX-DR13: Implement the Cheat Day / Blackout Date sheet as a long-press/overflow contextual action from a Day-view goal row (not a standalone top-level surface).
UX-DR14: Implement the Import Conflict Resolution surface: one decision per conflict (keep-mine / keep-imported / merge), no bulk "accept all," reached only from Settings → Import when FR-34 detects a conflict.
UX-DR15: Implement the 7-step guided creation wizard in FR-6's exact order (name → tracking type → schedule → target → dates → reminders → review); Back always enabled; Next disabled until the current step validates; the Review step restates the full rule as one plain-language sentence before Save.
UX-DR16: Implement the wizard's explicit daily-vs-weekly Streak clarification at the schedule/target steps, distinguishing a daily-evaluated goal with Cheat Days (real daily Streak) from a weekly-evaluated count goal (week-level pass/fail, no daily Streak) — must not be selectable interchangeably by accident.
UX-DR17: Implement the Version Timeline component on Goal Detail as a horizontal dated-segment strip distinct from the historical calendar below it; each segment tap reveals that Version's rules as plain text.
UX-DR18: Implement native widget UI (Today/Week/Month) rendering the same `status-cell` visual vocabulary as in-app; Today widget shows reduced density (name + status dot only, no progress bars), tap-through only, no other interaction.
UX-DR19: Implement voice/tone as literal copy constraints: no exclamation points in system-generated copy; no streak-cheerleading language/emoji; consequence-specific confirmation copy (Archive vs. Reset read differently); specific-reason import-validation error copy, never a generic "something went wrong."
UX-DR20: Implement the Pending / Empty / Fail-by-zero-eligible-days state distinctions in the calendar and dashboard so they never collapse into one generic gray or red treatment; implement the DNF "pending period close" treatment that silently resolves once the period actually closes.
UX-DR21: Implement the Midnight Rollover UX (FR-20): auto-commit the in-flight edit to the day it was entered on, then quietly refresh affected views — no interstitial or toast interrupting the user.
UX-DR22: Implement the accessibility floor: 44×44pt minimum tap targets including individual Month-view day cells; OS dynamic-type scaling with reflow, not truncation; WCAG AA contrast targets for text-on-surface and status-glyph-on-status-fill in both light and dark.
UX-DR23: Implement swipe navigation between months/weeks in the calendar plus a persistent "jump to today" affordance; long-press reserved for contextual actions (Cheat Day/Blackout); no swipe-to-reveal row actions.
UX-DR24: Implement Reset/Erase-All as the sole action requiring an explicit secondary confirmation step; all other lifecycle actions (archive/pause) remain single-tap since they're reversible/history-preserving by construction.
UX-DR25: Follow the OS light/dark theme setting by default; no separate in-app theme toggle in v1.
UX-DR26: Implement the first-run empty state (empty Dashboard prompting first-Goal creation, no login/account step) plus the other named empty states (a filtered Goals list with no matches; a Calendar date before a Goal's start date rendered as `status-empty`, not a special "before start" treatment).

### FR Coverage Map

FR-1: Epic 1 - Goal Definition (name, type, schedule, target, dates)
FR-2: Epic 2 - Goal Lifecycle (active/paused/archived/expired)
FR-3: Epic 2 - Goal Versioning (edits create dated segments)
FR-4: Epic 1 - Derived Status (computed, never stored as truth)
FR-5: Epic 1 - Zero-Eligible-Days red signal
FR-6: Epic 1 - Guided 7-step goal creation
FR-7: Epic 1 - Evaluation Period Types (Daily..Rolling Window..Custom)
FR-8: Epic 1 - Eligible-Days arbitrary weekday selection
FR-9: Epic 1 - Custom Recurrence (every-N, Nth-weekday, custom dates)
FR-10: Epic 1 - Blackout Dates
FR-11: Epic 1 - Target Comparison (At Least/At Most/Exactly)
FR-12: Epic 1 - Free Combination of all scheduling axes
FR-13: Epic 1 - Boolean Entry
FR-14: Epic 1 - Counter Entry
FR-15: Epic 1 - Corrections (floor at 0)
FR-16: Epic 2 - Cheat Days (per-goal quota)
FR-17: Epic 2 - DNF Marking
FR-18: Epic 1 - Certain-Failure Red
FR-19: Epic 1 - Data-Loss Bound (single in-flight entry)
FR-20: Epic 1 - Midnight Rollover
FR-21: Epic 1 - Day View
FR-22: Epic 1 - Week View
FR-23: Epic 1 - Month View (default)
FR-24: Epic 1 - Week-Start Setting
FR-25: Epic 3 - Goal Filtering (all/single/category)
FR-26: Epic 3 - Dashboard (today + week/month rollups)
FR-27: Epic 3 - Goal Detail Screen + Version Timeline
FR-28: Epic 3 - Statistics
FR-29: Epic 3 - Rule-Aware Streaks
FR-30: Epic 4 - Local Reminders (with At-Least exception)
FR-31: Epic 5 - Home-Screen Widgets (Today/Week/Month)
FR-32: Epic 5 - Widget Tap-Through
FR-33: Epic 6 - JSON Export
FR-34: Epic 6 - JSON Import (Merge) + conflict resolution
FR-35: Epic 2 - Delete = Archive
FR-36: Epic 6 - Reset / Erase All

NFR-1 (Offline-First), NFR-2 (Zero Telemetry), NFR-3 (No Timezone/DST), NFR-4 (Single-Device), NFR-5 (Platform Parity), NFR-6 (Correctness), NFR-7 (Data Durability): cross-cutting — apply to every epic, not owned by any single one.

## Epic List

### Epic 1: Goal Engine, Creation & Daily Logging
Panda can create a Goal matching any of the 13 worked-example scheduling patterns (PRD §4.2) through the guided 7-step wizard, log Boolean/Counter entries against it, and see accurate Day/Week/Month calendar status — success, certain-failure red, pending, empty, and the zero-eligible-days exception — computed by one pure, deterministic evaluator. This is the full UJ-1 loop for a single, never-yet-edited goal: the product's entire correctness claim (NFR-6) lives here.
**FRs covered:** FR-1, FR-4, FR-5, FR-6, FR-7, FR-8, FR-9, FR-10, FR-11, FR-12, FR-13, FR-14, FR-15, FR-18, FR-19, FR-20, FR-21, FR-22, FR-23, FR-24
**Implementation notes:** Builds `domain/entities`, the pure `evaluate()` function (AD-4) with version-boundary splitting (AD-5) already correct even though editing isn't exposed yet — the function's signature takes `versions` from day one — Drift schema (AD-3), `GoalService` for the single-version creation write path (AD-6), and the structural seed folder layout (Epic 1 Story 1). Delivers UX-DR6, UX-DR7, UX-DR9, UX-DR10, UX-DR15, UX-DR16, UX-DR20, UX-DR21, UX-DR23 and the core color/type/spacing/component tokens (UX-DR1-5). Large and intentionally not split further: the PRD explicitly ships full exotic scheduling now rather than deferring it, to keep the correctness claim intact from day one rather than retrofitting it later (PRD §4.2 rationale) — splitting "simple" and "exotic" scheduling into two epics would mean touching the same evaluator file twice for no user-facing benefit.

### Epic 2: Goal Lifecycle, Versioning & Cheat Days
Panda can edit a live goal's schedule or target, pause and resume it, mark cheat days against its quota, and mark a day DNF — all without corrupting the evaluated history of days already logged. "Delete" is archive; nothing is ever hard-deleted.
**FRs covered:** FR-2, FR-3, FR-16, FR-17, FR-35
**Implementation notes:** Extends `GoalService` (AD-6) with the edit-creates-a-new-Version write path, the one-Version-per-`(goalId, versionStartDate)` rule, and pause/resume/archive state transitions. The evaluator's *algorithm* isn't touched here — Epic 2 only starts *setting* the `GoalVersion.isPaused` field that Epic 1 already built `evaluate()` to read (so a mid-period pause correctly shrinks a period's eligible-day pool instead of forcing the remaining days to hit an unchanged target). Depends on Epic 1's evaluator and Goal CRUD.

### Epic 3: Goal Detail, Streaks & Stats
Panda gets the full "progress at a glance and over time" picture: a Dashboard with today's goals plus this week's/month's rollups, a Goal Detail screen with its Version Timeline, and Streak/completion-percentage statistics that correctly treat non-Daily goals as period-based, not day-based.
**FRs covered:** FR-25, FR-26, FR-27, FR-28, FR-29
**Implementation notes:** Introduces the read-optimization status cache (AD-7, `CacheWriter`) and `StatsService` (AD-8) — the live calendar still always calls `evaluate()` fresh; only Dashboard rollups/stats/widgets read the cache. Delivers UX-DR8, UX-DR17. Depends on Epic 1 (evaluator) and Epic 2 (Version Timeline needs real version history to show).

### Epic 4: Reminders
Panda gets nudged once a day at a consistent time for whatever's still outstanding, and stops getting reminded once a goal's target is met for the period — except for At Least (≥) goals, where reminders continue since logging more is still meaningful.
**FRs covered:** FR-30
**Implementation notes:** `flutter_local_notifications` (Stack), single global time via `shared_preferences` (AD-3's settings exception), suppression logic reads the same `evaluate()` output Epic 1 already produces.

### Epic 5: Home-Screen Widgets
Panda can glance at Today/Week/Month status from the home screen without opening the app, and tap through to the relevant date.
**FRs covered:** FR-31, FR-32
**Implementation notes:** Native per-platform UI (Kotlin/Jetpack Glance on Android, Swift/WidgetKit on iOS) plus the `widget_bridge/` serializer — outside the Flutter/Dart paradigm, its own implementation track. Renders only precomputed cache from Epic 3's `CacheWriter`, never live `evaluate()`. Delivers UX-DR18. Depends on Epic 3's cache.

### Epic 6: Data Portability & Reset
Panda can back up all data to a single JSON file, restore or merge it onto a new device, and, separately, wipe everything and start clean if they ever want to.
**FRs covered:** FR-33, FR-34, FR-36
**Implementation notes:** Export/import serialization lives in `data/io/`, but every write still routes through `GoalService` (AD-6) — import is not a special-cased write path. Delivers UX-DR14 (conflict-resolution surface) and UX-DR24 (Reset's secondary confirmation). Depends on Epic 1 and Epic 2's full write paths existing to import against.

---

## Epic 1: Goal Engine, Creation & Daily Logging

Panda can create a Goal matching any of the 13 worked-example scheduling patterns (PRD §4.2) through the guided 7-step wizard, log Boolean/Counter entries against it, and see accurate Day/Week/Month calendar status — success, certain-failure red, pending, empty, and the zero-eligible-days exception — computed by one pure, deterministic evaluator.

### Story 1.1: Scaffold the App and Track a Simple Daily Goal

As Panda,
I want to create a simple daily Boolean goal and log it done/not-done each day,
So that I can start using the app for my most basic commitments while the rest of the engine is built out.

**Acceptance Criteria:**

**Given** the app is freshly installed
**When** Panda opens it for the first time
**Then** no login/account step is shown and the Dashboard area shows an empty state prompting Goal creation (UX-DR26)

**Given** Panda fills in a goal name, Boolean tracking type, Daily evaluation period, "every day" eligible-days, and target "Exactly 1"
**When** they save
**Then** a Goal plus one GoalVersion is persisted via GoalService (AD-6) in a single Drift transaction (AD-3), with a UUIDv4 id and an ISO-8601 date-only start date

**Given** a goal exists and today is an eligible day
**When** Panda opens Day View
**Then** the goal appears as a `goal-row` (UX-DR7) with its current status rendered via the `status-cell`/badge vocabulary (UX-DR6), and this Day View is itself the surface FR-21 requires (FR-21)

**Given** Panda taps the goal row
**When** they mark it done
**Then** a GoalLog is written through GoalService inside one transaction and the row's status updates to Success (green) immediately, computed by the pure `evaluate()` function (AD-4) — no separately stored "done" flag drives the color (FR-13)

**Given** the app is killed immediately after a tap but before the write commits
**When** Panda reopens the app
**Then** at most that one in-flight entry is lost and all previously committed data is intact (FR-19)

**And** the base color/typography/spacing/button component tokens (UX-DR1–5, UX-DR10) are the only styling used on every screen in this story — no ad hoc colors or spacing

### Story 1.2: Track Counter Goals with Corrections

As Panda,
I want to log a numeric Counter goal (e.g. glasses of water) with increments and corrections,
So that I can track quantities, not just done/not-done.

**Acceptance Criteria:**

**Given** a Counter-type goal with target "At least 8" for today
**When** Panda taps + on the stepper
**Then** the running daily total increases by 1 and is written via GoalService (FR-14)

**Given** Panda enters a decimal value directly (e.g. 7.5)
**When** they save
**Then** the value is accepted and stored (FR-14 — decimals supported)

**Given** a Counter goal already has a logged value today
**When** Panda logs a negative correction
**Then** the day's total decreases but never goes below 0, enforced by GoalService before persisting (FR-15, AD-6)

**Given** multiple increments are logged in one day
**When** Panda views the day
**Then** they see a single running total, not per-increment timestamps (FR-14 consequence)

**And** the `numeric` tabular-figure typography token (UX-DR2) is used so digits do not visually shift width as the value updates live

### Story 1.3: Evaluate All Evaluation Period Types

As Panda,
I want a goal's target evaluated over the right kind of period (daily, weekly, monthly, rolling window, etc.),
So that goals like "3x a week" or "10x in any 14 days" are judged correctly, not just per day.

**Acceptance Criteria:**

**Given** a goal with Evaluation Period = Weekly and Week-Start = Monday
**When** `evaluate()` runs for any date in that week
**Then** the period boundary is Monday–Sunday (FR-7, FR-24)

**Given** a goal with Evaluation Period = Rolling Window (14 days)
**When** `evaluate()` runs for today
**Then** the window is always "the trailing 14 days ending today," with no fixed calendar boundary (FR-7)

**Given** Biweekly, Monthly, Quarterly, and Yearly period types
**When** a goal of each type is evaluated
**Then** each follows its respective calendar boundary (FR-7)

**Given** the pure `evaluate()` signature `evaluate({goal, versions, logs, cheatDays, blackoutDates, date})`
**When** called by two different callers with the same inputs supplied in different order
**Then** the result is identical — inputs are sorted internally, never depending on caller-supplied ordering (AD-4)

### Story 1.4: Eligible-Days Rules — Presets and Arbitrary Selection

As Panda,
I want to restrict a goal to specific days of the week — workdays, weekends, or any arbitrary subset,
So that goals like "gym on workdays only" are scheduled correctly.

**Acceptance Criteria:**

**Given** goal creation
**When** Panda selects the "Every day" preset
**Then** all 7 weekdays are eligible (FR-8)

**Given** Panda selects "Workdays"
**When** the rule is saved
**Then** Monday–Friday are eligible, implemented as the same underlying arbitrary-selection mechanism as any custom subset, not a special-cased type (FR-8 consequence)

**Given** Panda selects an arbitrary subset (e.g. Mon/Tue/Thu/Sat)
**When** saved
**Then** exactly those weekdays are eligible and all others are not (FR-8)

**Given** a non-eligible day
**When** Panda views it in Day View
**Then** it renders as `status-empty`, not Pending or Fail (State Patterns)

### Story 1.5: Custom Recurrence Patterns

As Panda,
I want to schedule a goal on patterns like "every 3 days" or "the 2nd Saturday of the month,"
So that irregular but real commitments are modeled precisely instead of forced into a weekly shape.

**Acceptance Criteria:**

**Given** a goal with "every N days" (N=3) anchored to a Jan 1 start date
**When** `evaluate()` computes eligible days
**Then** they fall on Jan 1, 4, 7, 10… and editing other rules does not re-anchor this cycle (FR-9)

**Given** "every N weeks on specific weekdays" and "every N months"
**When** evaluated
**Then** each produces the correct fixed calendar grid anchored to the goal's start date (FR-9)

**Given** "Nth weekday of month" (e.g. 2nd Tuesday)
**When** `evaluate()` computes eligibility for a given month
**Then** it is computed independently per calendar month, not relative to the goal's start date (FR-9 consequence)

**Given** an explicit custom date selection
**When** those specific dates are chosen
**Then** only those dates are eligible (FR-9)

### Story 1.6: Blackout Dates

As Panda,
I want to mark specific dates as excluded from a goal (e.g. a holiday),
So that I'm not penalized for a day I genuinely can't follow the rule, without it looking like I dodged the requirement.

**Acceptance Criteria:**

**Given** today's date and an active goal
**When** Panda marks today as a Blackout Date with an optional reason
**Then** that date is exempted from failure for that goal (FR-10)

**Given** a goal "at least 3 of 5 eligible days" with one Blackout Date in the period
**When** `evaluate()` runs
**Then** the required count stays 3 and the eligible-day pool is unchanged — the Blackout Date reduces neither (FR-10 consequence)

**Given** a Blackout Date is set
**When** the Cheat Day quota is checked for that goal/period
**Then** the Blackout Date does not consume any of the Cheat Day quota — a separate mechanism (FR-10 consequence)

**Given** the Cheat Day / Blackout Date sheet component (UX-DR13)
**When** Panda long-presses a Day View goal row
**Then** the sheet opens with the Blackout Date action available for that goal and date (FR-10) — the Cheat Day action is added to this same sheet in Epic 2 Story 2.4, once Cheat Days exist; until then the sheet shows Blackout Date only

**And** this story creates only the `BLACKOUT_DATE` Drift table (Story 2.4 later adds `CHEAT_DAY`) — no table is created before the story that needs it

### Story 1.7: Target Comparisons and Free Combination

As Panda,
I want any Evaluation Period, Eligible-Days Rule, Tracking Type, and Target Comparison to combine freely,
So that I can build the exact rule my commitment needs instead of settling for the closest preset.

**Acceptance Criteria:**

**Given** a Boolean or Counter goal
**When** Target Comparison is set to At Least, At Most, or Exactly
**Then** both types accept all three comparisons (FR-11)

**Given** each of the 13 worked-example patterns in PRD §4.2 (e.g. "Water 8 glasses, skip vacation days" = Daily + every day + Blackout Dates + Counter + At least 8)
**When** each is created and evaluated
**Then** all 13 are creatable and evaluate correctly (FR-12, NFR-6)

**Given** any one axis (period, eligible-days, type, comparison) is changed independently
**When** the goal is re-evaluated
**Then** no other axis's behavior is affected by that change (FR-12 consequence)

### Story 1.8: Pending, Certain-Failure Red, and the Zero-Eligible-Days Signal

As Panda,
I want a day or period to only turn red once failure is truly certain, and to see a clear warning if I've misconfigured a goal with no eligible days,
So that the calendar never guilt-trips me early or hides a mistake.

**Acceptance Criteria:**

**Given** a Weekly "at least 3 of 5 workdays" goal with 2 of 5 days missed and 3 remaining
**When** `evaluate()` runs mid-week
**Then** the period shows Pending, not Red (FR-18)

**Given** the same goal with 3 of 5 workdays already missed
**When** `evaluate()` runs
**Then** the period turns Red — failure is now mathematically certain (FR-18)

**Given** a Rolling-Window "10x in any 14 days" goal
**When** the remaining days in the window can no longer mathematically reach 10
**Then** it turns Red that day, with no other red-triggering condition (FR-18 consequence)

**Given** a goal whose Eligible-Days Rule produces zero eligible days in an entire period
**When** `evaluate()` runs
**Then** that period shows Red, not the Empty/gray treatment (FR-5 — a deliberate exception)

**And** the five-state status vocabulary (UX-DR6, UX-DR20) pairs each of Pending/Empty/Fail-by-zero-eligible-days/Success/Cheat with a distinct color, glyph, and screen-reader label — none collapse into a generic gray

### Story 1.9: Guided Goal-Creation Wizard

As Panda,
I want to create a goal through a guided, one-decision-at-a-time flow instead of one long form,
So that the exotic scheduling surface doesn't overwhelm me and I don't accidentally pick the wrong pattern.

**Acceptance Criteria:**

**Given** goal creation
**When** Panda proceeds through the flow
**Then** steps appear in the exact order name → tracking type → schedule → target → dates → reminders → review, with a `wizard-progress` bar showing proportional fill and no step numerals shown elsewhere (FR-6, UX-DR9, UX-DR15)

**Given** any step's required fields are incomplete
**When** Panda taps Next
**Then** Next stays disabled until the step validates; Back is always enabled (UX-DR15)

**Given** Panda is configuring a "7×/week with 2 cheat days" pattern versus a "5×/week" pattern at the schedule/target steps
**When** either is selected
**Then** the flow visibly distinguishes that the first produces a real daily Streak and the second a week-level pass/fail with no daily Streak, so the two can't be picked interchangeably by accident (FR-6 consequence, UX-DR16)

**Given** all steps are complete
**When** Panda reaches Review
**Then** the full rule is restated as one plain-language sentence (e.g. "Done at least 3 times a week, workdays only, starting Aug 18") before Save (UX-DR15)

**Given** Panda taps Back at any step
**When** they change an earlier answer
**Then** later steps reflect the change and re-validate before Save becomes available (FR-6)

### Story 1.10: Week and Month Calendar Views

As Panda,
I want to browse a week grid or a full month calendar and see every goal's status at a glance,
So that I can check my progress over time, not just today.

**Acceptance Criteria:**

**Given** any goal and date range
**When** Panda opens Week View
**Then** a 7-day grid shows each goal's per-day status and the week's overall progress (FR-22)

**Given** Panda opens the app with no other view last active
**When** the app loads
**Then** Month View is shown by default, with each day rendered via `status-cell` (FR-23)

**Given** Month View is open
**When** Panda swipes horizontally
**Then** the view moves to the adjacent month, and a persistent "jump to today" affordance is available regardless of how far they've navigated (FR-23, UX-DR23)

**Given** Week-Start is set to Monday (default) or Sunday
**When** either calendar view renders
**Then** the grid's first column matches that setting (FR-24)

**And** long-press is reserved for contextual actions (Cheat Day/Blackout) so no row-level swipe-to-reveal action competes with month/week swipe navigation (UX-DR23)

### Story 1.11: Midnight Rollover and Data-Loss Bound

As Panda,
I want an entry I'm mid-typing at midnight to land on the right day, and to never lose more than that one entry if the app is killed,
So that I can trust the app even at the edges of a day.

**Acceptance Criteria:**

**Given** Panda has an uncommitted Counter entry being typed as midnight passes with the app open
**When** the clock rolls over
**Then** that entry auto-commits to the day it was entered on, not the new day (FR-20)

**Given** the rollover just happened
**When** it completes
**Then** the app performs a full data reload so Dashboard/Day View/in-progress statuses recompute against the new local day, with no interstitial or toast interrupting Panda (FR-20, UX-DR21)

**Given** the app is killed mid-save at any other time
**When** Panda reopens it
**Then** only that single in-flight entry is lost and everything previously committed survives (FR-19, NFR-7)

**And** any multi-statement domain mutation (a log write plus its cache invalidation, a version creation) executes inside one Drift transaction, so a kill mid-write can never leave partial state

---

## Epic 2: Goal Lifecycle, Versioning & Cheat Days

Panda can edit a live goal's schedule or target, pause and resume it, mark cheat days against its quota, and mark a day DNF — all without corrupting the evaluated history of days already logged. "Delete" is archive; nothing is ever hard-deleted.

### Story 2.1: Edit a Goal's Rules Mid-Stream

As Panda,
I want to edit a live goal's schedule or target,
So that I can adjust a commitment as life changes without losing or corrupting the history of days already logged.

**Acceptance Criteria:**

**Given** a goal with logs before today
**When** Panda edits its target/eligible-days/evaluation period effective today
**Then** GoalService creates a new dated GoalVersion rather than mutating the existing one (FR-3)

**Given** a day was logged before the rule change
**When** that day is re-evaluated
**Then** it is evaluated against the GoalVersion that was active on that date, not the new one (FR-3 consequence)

**Given** Panda edits the same goal twice on the same calendar day before any log exists against the first edit
**When** the second edit saves
**Then** it amends the still-log-free Version in place rather than creating a second Version for the same date (AD-6 — at most one Version per `(goalId, versionStartDate)`)

**Given** a GoalLog already exists against a Version
**When** Panda attempts another same-day edit
**Then** the edit is rejected and Panda must choose a later effective date instead (AD-6)

**And** the edit-creates-a-Version write commits inside a single Drift transaction (Transaction atomicity)

### Story 2.2: Pause and Resume a Goal

As Panda,
I want to pause a goal and resume it later,
So that I can step away from a commitment temporarily without it counting against me or losing its history.

**Acceptance Criteria:**

**Given** an Active goal
**When** Panda pauses it
**Then** its state becomes Paused, recorded as a new dated GoalVersion segment (FR-2, FR-3)

**Given** a Paused goal's date range
**When** the calendar or evaluator considers that range
**Then** it produces no Eligible Days at all for those dates — not Empty, not Pending (FR-2 consequence)

**Given** a Paused goal
**When** Panda resumes it
**Then** it becomes Active again from the resume date forward, recorded as another new Version segment (FR-2)

**And** this pause/resume mechanism reuses Story 2.1's versioning write path rather than a separate one

### Story 2.3: Archive, Expire, and Delete = Archive

As Panda,
I want archiving a goal (including via "Delete") to hide it from active views while keeping full history, and an end-dated goal to expire on its own,
So that nothing I've tracked is ever silently lost.

**Acceptance Criteria:**

**Given** an Active or Paused goal
**When** Panda taps "Delete" or "Archive"
**Then** the same operation runs — the goal's state becomes Archived; there is no hard delete (FR-2, FR-35)

**Given** an Archived goal
**When** Panda views active tracking surfaces (Dashboard, Day/Week/Month)
**Then** it does not appear; **when** Panda views historical/stats surfaces, **then** it remains fully visible (FR-2 consequence)

**Given** a goal with an end date
**When** that end date passes
**Then** its state becomes Expired automatically, without Panda manually archiving it (FR-2)

**And** for any Archived or Expired goal, all GoalVersions and GoalLogs remain intact and unmodified (FR-35 consequence)

### Story 2.4: Cheat Days

As Panda,
I want to mark a date as a Cheat Day for a specific goal up to its quota,
So that an occasional planned skip doesn't count as failure, without letting me quietly ignore the goal.

**Acceptance Criteria:**

**Given** a goal with a per-goal Cheat Day quota (default 0)
**When** Panda marks a date as a Cheat Day within that quota
**Then** the date displays yellow and is exempted from failure for that goal (FR-16)

**Given** a goal configured for 2 Cheat Days/week
**When** a new Evaluation Period begins
**Then** the quota resets to a fresh 2 for that period — not a lifetime cap (FR-16 consequence)

**Given** a Cheat Day is used
**When** the Target Comparison (At Least, At Most, or Exactly) is evaluated for that period
**Then** the required count is not reduced — the exemption applies identically across all three comparison types (FR-16 consequence)

**And** if Panda attempts to mark a Cheat Day beyond the goal's remaining quota for the period, the action is rejected with an inline message stating the quota is exhausted for the period (FR-16 boundary)

**And** this story adds the `CHEAT_DAY` Drift table (the Cheat Day half of the sheet Story 1.6 introduced as Blackout-only) — the sheet now surfaces both actions

### Story 2.5: DNF Marking

As Panda,
I want to explicitly mark a day as "did not finish" as a placeholder,
So that I can note it in the moment even before the period's real outcome is known, without that guess overriding the actual computed result later.

**Acceptance Criteria:**

**Given** an eligible day
**When** Panda marks it DNF
**Then** the day shows a distinct "DNF (pending period close)" treatment (FR-17, UX-DR20)

**Given** a day marked DNF
**When** its enclosing Evaluation Period actually closes
**Then** the DNF mark is silently superseded by whatever `evaluate()` actually computed for that period — the DNF mark is never itself an `evaluate()` input (FR-17)

**And** if a day marked DNF turns out to have succeeded once logged, the real Success status is shown once the period closes, with no stale DNF treatment left visible (FR-17 consequence, UX-DR20)

---

## Epic 3: Goal Detail, Streaks & Stats

Panda gets the full "progress at a glance and over time" picture: a Dashboard with today's goals plus this week's/month's rollups, a Goal Detail screen with its Version Timeline, and Streak/completion-percentage statistics that correctly treat non-Daily goals as period-based, not day-based.

### Story 3.1: Dashboard — Today's Goals and Progress Rollups

As Panda,
I want to open the app to a Dashboard showing today's eligible goals with progress, current streaks, and this week's/month's rollups,
So that I can see everything at a glance without navigating anywhere.

**Acceptance Criteria:**

**Given** one or more goals eligible today
**When** Panda opens the Today tab
**Then** each appears as a `goal-row` with progress (e.g. "3/5 complete" for period goals, done/not-done for daily) (FR-26)

**Given** the same Dashboard
**When** it renders
**Then** it also shows a rollup of this week's and this month's in-progress goals for a glance (FR-26)

**Given** a reminder time is configured
**When** the Dashboard renders
**Then** the next scheduled reminder time (a single global time) is shown (FR-26)

**Given** a GoalLog or GoalVersion commits
**When** the write completes
**Then** `CacheWriter` (AD-7) writes the resulting `DayStatus` inside the same transaction, and the Dashboard's rollups read from this cache — never a live `evaluate()` call for the rollup surface (AD-7, AD-8)

**Given** the cache is deleted or corrupted
**When** `StatsService` needs a value not present in cache
**Then** it falls back to calling `evaluate()` directly for that range, with no error state and no data loss (AD-8 consequence)

**And** the bottom tab bar (UX-DR12) shows Today as the active tab among the 4 tabs (Today/Calendar/Goals/Settings)

### Story 3.2: Goal Detail Screen with Version Timeline

As Panda,
I want to open a goal and see its schedule, target, streak, completion percentage, historical calendar, and a timeline of how its rules changed over time,
So that I understand not just where a goal stands but how it got there.

**Acceptance Criteria:**

**Given** any goal
**When** Panda taps into its Goal Detail screen
**Then** it shows the goal's current schedule and target, current and longest Streak, completion percentage, a historical calendar, and edit/archive actions (FR-27)

**Given** a goal has been edited or paused/resumed (Epic 2)
**When** Panda views its Version Timeline
**Then** it shows the dated rule-change segments (e.g. "3x/week Jan 1–Mar 14, then 5x/week Mar 15–present") as a horizontal strip distinct from the historical calendar below it (FR-27 consequence, UX-DR17)

**Given** Panda taps a Version Timeline segment
**When** it opens
**Then** that Version's rules are shown as plain text, not a raw diff (UX-DR17)

**And** if a goal is Archived, its Goal Detail still renders correctly from history (FR-2 consequence)

### Story 3.3: Rule-Aware Streaks

As Panda,
I want a non-daily goal's streak to count consecutive successful weeks/months, not consecutive days, and a Rolling Window goal to show its current pace instead of a streak,
So that the number I see actually means what I think it means.

**Acceptance Criteria:**

**Given** a Weekly "3x/week" goal
**When** its Streak is computed
**Then** it counts consecutive successful Evaluation Periods (weeks), not consecutive days (FR-29)

**Given** a Daily goal
**When** its Streak is computed
**Then** it counts consecutive successful days, as before — Daily is the one case where period equals day (FR-29)

**Given** a Rolling Window goal
**When** Panda views its stats
**Then** no Streak stat is shown at all — only current pace/status (FR-29 consequence)

**And** since `StatsService` (AD-8) is the sole streak/rollup computer, the Dashboard and Goal Detail show the identical streak value for the same goal — neither computes it independently

### Story 3.4: Full Statistics Panel

As Panda,
I want a goal's detail screen to show its full statistical history — success/failure counts, cheat days used, average and total values, and completion percentage that fairly excludes paused time,
So that I can see the whole picture, not just the current streak.

**Acceptance Criteria:**

**Given** any goal
**When** Panda views its stats
**Then** they include current Streak, longest Streak, completion percentage (daily/weekly/monthly), counts of successful and failed periods, Cheat Day count, and, for Counter goals, average and total value (FR-28)

**Given** a goal was Paused for part of its history
**When** completion percentage is computed
**Then** the Paused date range is excluded from the calculation, consistent with Epic 2's "Paused produces no Eligible Days" (FR-28 consequence)

**Given** the `stat-card` component (UX-DR8)
**When** any of these numbers render
**Then** they use tabular figures with no icons — numeric-heavy, not decorative (UX-DR8)

**And** the complete Goal history is available when Panda scrolls Goal Detail, not truncated to a recent window (FR-28)

### Story 3.5: Goal Filtering by Category

As Panda,
I want to filter the calendar to all goals, a single goal, or a category of goals,
So that I can focus on one part of my life without the rest cluttering the view.

**Acceptance Criteria:**

**Given** multiple goals exist, some assigned to categories
**When** Panda applies a filter
**Then** the calendar can show all Goals, a single Goal, or an entire category (FR-25)

**Given** a goal is created or edited
**When** Panda assigns it a category
**Then** that assignment persists and is usable as a real filter, not a schema placeholder (FR-25, confirmed MVP scope)

**And** when no filter is applied, the calendar defaults to showing all Goals (FR-25 default behavior)

**And** the Goals list orders goals by Evaluation Period frequency — Daily, Weekly, Biweekly, Monthly, Quarterly, Yearly, then Rolling Window and Custom last — alphabetical by name within each group; this is a computed sort, not a stored `Priority` field, and resolves the goal-list ordering question Architecture and UX both left open

---

## Epic 4: Reminders

Panda gets nudged once a day at a consistent time for whatever's still outstanding, and stops getting reminded once a goal's target is met for the period — except for At Least (≥) goals, where reminders continue since logging more is still meaningful.

### Story 4.1: Global Daily Reminder

As Panda,
I want to set a single reminder time that applies across all goals,
So that I get nudged once a day without configuring each goal individually.

**Acceptance Criteria:**

**Given** Settings
**When** Panda sets a reminder time
**Then** it's stored via `shared_preferences` (AD-3 settings exception) and applies globally across all goals — no per-goal custom time exists (FR-30)

**Given** the reminder time is set
**When** the scheduled time arrives
**Then** `flutter_local_notifications` fires one local notification, entirely offline, with no third-party network call (NFR-1, NFR-2)

**Given** the Dashboard (Story 3.1)
**When** it renders
**Then** it shows this same next scheduled reminder time (FR-26 cross-reference)

**And** if the device reboots after a reminder time was previously set, the scheduled notification re-registers correctly rather than silently disappearing

### Story 4.2: Reminder Suppression Rules

As Panda,
I want the daily reminder to skip goals that aren't eligible today, are paused/archived, or are already done for the period — except goals I've set to "at least," which should keep nudging me since more is still good,
So that the reminder stays useful instead of becoming noise.

**Acceptance Criteria:**

**Given** a goal is not Eligible today
**When** the reminder fires
**Then** it does not include or trigger for that goal (FR-30)

**Given** a goal is Paused or Archived
**When** the reminder fires
**Then** it is excluded entirely (FR-30)

**Given** a goal's target for the current period is already met and its Target Comparison is At Most or Exactly
**When** the reminder fires
**Then** that goal is suppressed (FR-30, suppress-on-completion)

**Given** a goal's Target Comparison is At Least (≥) and its target is already met for the period
**When** the reminder fires
**Then** that goal is still included — reminders continue since additional logging beyond the minimum may still be wanted (FR-30, resolved exception)

**And** if every eligible goal for today is suppressed, no reminder fires at all rather than firing an empty one

---

## Epic 5: Home-Screen Widgets

Panda can glance at Today/Week/Month status from the home screen without opening the app, and tap through to the relevant date.

### Story 5.1: Widget Data Bridge

As Panda,
I want the app to keep a shared data container updated with each goal's precomputed status,
So that native home-screen widgets always have fresh data to render without the app needing to be open.

**Acceptance Criteria:**

**Given** a GoalLog or GoalVersion commits and `CacheWriter` (AD-7) writes the resulting `DayStatus`
**When** the write completes
**Then** `widget_bridge` (data layer) serializes the relevant `DayStatus` records (date, goalId/scope, status) to `home_widget`'s shared container as part of that same commit path (AD-7, FR-31)

**Given** the midnight-rollover job runs (FR-20) and recomputes cached status
**When** it completes
**Then** `widget_bridge` also updates the shared container, so widgets reflect the new day without the app needing to be reopened

**Given** `widget_bridge` lives in the `data` layer
**When** it serializes `DayStatus`
**Then** it depends only on domain-defined interfaces and contains no Flutter widget-tree code, respecting the layer boundary (AD-1)

**Given** zero goals are eligible today for a given widget scope
**When** `widget_bridge` writes for that scope
**Then** it writes an explicit empty/no-data state rather than leaving stale data from a previous day

**And** no widget-bridge write ever triggers a live `evaluate()` call — it only serializes what `CacheWriter` already computed (AD-7, Caching Policy — widgets are cache-only, never live evaluation)

### Story 5.2: Today/Week/Month Widget Rendering

As Panda,
I want Today, Week, and Month home-screen widgets that show my goals' status using the same visual language as the app,
So that I can check my progress at a glance without opening the app.

**Acceptance Criteria:**

**Given** the `widget_bridge` shared container has data for today
**When** Panda adds the Today widget to their home screen
**Then** it renders each eligible goal at reduced density — name and status dot only, no progress bars (UX-DR18)

**Given** the shared container has data for the current week
**When** Panda adds the Week widget
**Then** it renders the same `status-cell` grid vocabulary as in-app Week View, sized to whatever cell count the platform's widget size class allows (UX-DR18)

**Given** the shared container has data for the current month
**When** Panda adds the Month widget
**Then** it renders the same `status-cell` grid vocabulary as in-app Month View, at the platform's supported density

**Given** any of the three widgets on Android
**When** it renders
**Then** it is implemented natively in Kotlin/Jetpack Glance (Architecture Stack); **on iOS**, natively in Swift/WidgetKit

**Given** a `status-cell` renders in any widget
**When** Panda views it
**Then** it uses the identical color+glyph+screen-reader-label vocabulary as in-app (UX-DR6, UX-DR18) — no separate widget-only color treatment

**And** no widget ever calls `evaluate()` or performs its own computation — it only reads precomputed status from the shared container (FR-31, AD-7)

### Story 5.3: Widget Tap-Through

As Panda,
I want tapping any home-screen widget to open the app to the relevant date,
So that I can go straight from a glance to logging or reviewing without extra navigation.

**Acceptance Criteria:**

**Given** the Today widget
**When** Panda taps it
**Then** the app opens directly to today's Day View (FR-32)

**Given** the Week or Month widget
**When** Panda taps it (or a specific day cell within it, where the platform's widget-tap API supports per-cell deep links)
**Then** the app opens to that week/day or month/day accordingly (FR-32)

**Given** tap-through is the widget's only supported interaction
**When** Panda attempts any other gesture (long-press, swipe) on a widget
**Then** no action occurs — widgets are read-only except for tap-through (UX-DR18)

**And** the exact per-platform tap-through granularity (whole-widget vs. per-cell) is resolved here according to each platform's actual capability, closing the `[ASSUMPTION]` the PRD carried forward on this point (FR-32)

---

## Epic 6: Data Portability & Reset

Panda can back up all data to a single JSON file, restore or merge it onto a new device, and, separately, wipe everything and start clean if they ever want to.

### Story 6.1: JSON Export

As Panda,
I want to export my full app state to a single JSON file,
So that I have a portable backup of everything I've tracked.

**Acceptance Criteria:**

**Given** any amount of app data exists (Goals, Versions, Logs, Cheat Days, Blackout Dates, settings, categories, notification config)
**When** Panda triggers Export from Settings
**Then** a single JSON file is produced containing all of it plus metadata including a schema-version field (FR-33)

**Given** zero Goals exist yet
**When** Panda triggers Export
**Then** a valid, structurally complete JSON file is still produced with an empty goals array — this enables the zero-goal-import acceptance case in Story 6.2 (FR-33)

**Given** the export process only reads data
**When** it runs
**Then** it performs a read-only operation — no `GoalService` write path is ever invoked by export

**And** the export happens entirely offline, with no network call of any kind (NFR-1, NFR-2)

### Story 6.2: JSON Import with Validation and Conflict Resolution

As Panda,
I want to import a JSON backup file and have it merge safely into my existing data,
So that I can restore or move my data between devices without risking corruption or silent data loss.

**Acceptance Criteria:**

**Given** a well-formed JSON export file with no ID overlaps against existing data
**When** Panda imports it from Settings → Import
**Then** all Goals/Versions/Logs/Cheat Days/Blackout Dates/settings/categories are merged into existing local data — not a full replace — with every write routed through `GoalService` (FR-34, AD-6)

**Given** malformed JSON
**When** Panda attempts the import
**Then** it's rejected with a specific reason and existing data is left untouched (FR-34)

**Given** valid JSON missing required structure (e.g. no goals array, no schema-version field)
**When** Panda attempts the import
**Then** it's rejected, naming the specific missing structure (FR-34)

**Given** a schema-version the app doesn't support
**When** Panda attempts the import
**Then** it's rejected as a schema-version mismatch, named specifically (FR-34)

**Given** the file contains a duplicate ID or an orphaned log referencing a Goal/Version absent from both the file and existing data
**When** Panda attempts the import
**Then** it's rejected, naming the specific problem (e.g. "This file references a Goal that no longer exists") (FR-34)

**Given** the file contains an invalid date, an invalid/contradictory rule combination, or an invalid Cheat Day configuration
**When** Panda attempts the import
**Then** it's rejected, naming the specific validation failure (FR-34)

**Given** a JSON file whose goals array is empty (a zero-goal export)
**When** Panda imports it
**Then** the import is accepted with a warning shown to Panda — not rejected (FR-34 zero-goal exception)

**Given** the imported data conflicts with existing local data for the same entity
**When** a conflict is detected
**Then** Panda is routed to the Import Conflict Resolution surface (UX-DR14) with one decision per conflict — keep-mine / keep-imported / merge — and no bulk "accept all" option (FR-34, UX-DR14)

**Given** the import completes with no conflicts
**When** it finishes
**Then** Panda sees a brief, silent-success confirmation rather than the conflict-resolution surface

**And** every write the import performs — new Goal, new GoalVersion, new GoalLog, or a conflict-resolution choice — routes through `GoalService` inside proper transactions, never a separate import-only write path (AD-6)

### Story 6.3: Reset / Erase All

As Panda,
I want a separate action that wipes all my local data and returns the app to a clean first-run state,
So that I can start over completely if I ever want to, with no chance of it happening by accident.

**Acceptance Criteria:**

**Given** Settings
**When** Panda selects Reset / Erase All
**Then** an explicit secondary confirmation step is required before anything is deleted — the only action in the app with this two-step confirmation (FR-36, UX-DR24)

**Given** the confirmation step
**When** it's shown
**Then** its copy states the specific consequence and irreversibility ("This erases all Goals, logs, and settings. This cannot be undone.") rather than generic wording (FR-36)

**Given** Panda confirms
**When** the reset executes
**Then** all Goals, GoalVersions, GoalLogs, Cheat Days, Blackout Dates, settings, and categories are wiped inside a single Drift transaction, executed as a `GoalService` use-case (AD-6, Transaction atomicity)

**Given** the reset completes
**When** Panda returns to the app
**Then** it shows the same first-run empty state as a fresh install (FR-36, UX-DR26)

**Given** Panda cancels at the secondary confirmation step
**When** they back out
**Then** no data is deleted and the app returns to Settings unchanged

**And** Reset / Erase All is the only truly irreversible action in the product — every other lifecycle action (archive, pause) remains reversible/history-preserving and therefore stays single-tap (UX-DR24, FR-2, FR-35)
