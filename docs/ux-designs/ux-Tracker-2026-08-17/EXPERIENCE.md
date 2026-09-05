---
name: Goal Tracker
status: final
sources:
  - docs/brief.md
  - docs/prd/
  - docs/addendum/
  - docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md
updated: 2026-08-17
---

# EXPERIENCE.md — Goal Tracker

> Paired with `DESIGN.md` (same run). Single-user, offline-first, mobile-only. Spines win on conflict with any mock.

## Foundation

Single-surface mobile, Android + iOS, built from one Flutter codebase (`ARCHITECTURE-SPINE.md`, AD-1). No named UI system inherited wholesale — the visual language is unified across both platforms on a Material 3 widget base, overridden throughout by `DESIGN.md` tokens, rather than an adaptive Material/Cupertino split. That's a deliberate parity choice: the brief's stated bar for success is "the app works as intended on both Android and iOS," not a per-OS native feel, and the goal engine's correctness claim (SM-2, NFR-6) is easier to keep consistent across platforms when the interaction surface doesn't fork.

No login, no onboarding accounts — first run goes straight to an empty Dashboard with a prompt to create the first Goal. The app follows the OS light/dark setting by default (`DESIGN.md` Colors); there is no separate in-app theme toggle in v1.

Three additional native surfaces exist outside the Flutter widget tree: the Today, Week, and Month home-screen widgets (FR-31), bridged via `home_widget` but implemented natively per platform (`ARCHITECTURE-SPINE.md` Stack). They render the same `status-cell` visual vocabulary as the in-app calendar but are read-only except for tap-through (FR-32).

## Information Architecture

| Surface | Reached from | Purpose |
|---|---|---|
| Today (Dashboard) | App open (cold start), tab bar | Today's eligible goals, quick log, this week/month rollup — realizes UJ-1 |
| Calendar (Day / Week / Month) | Tab bar; Month is default (FR-23) | Browse and log any date; swipe between months; jump to today |
| Goal Detail | Row tap from Dashboard, Calendar, or Goals list | Schedule, target, current/longest Streak, completion %, historical calendar, Version Timeline (FR-27), edit/archive |
| Goal creation / edit wizard | "+" from Dashboard or Goals list; "Edit" from Goal Detail | Guided 7-step flow (FR-6) |
| Goals (all goals) | Tab bar | Active/Paused/Archived/Expired list, filterable, entry point to Goal Detail and creation |
| Cheat Day / Blackout Date sheet | Long-press or overflow action on a Day-view goal row | Mark a Cheat Day (FR-16) or Blackout Date (FR-10) against one goal/date |
| Settings | Tab bar | Week-start day, global reminder time, categories, export, import, reset |
| Import conflict resolution | Settings → Import, only when a conflict is detected | Per-conflict keep-mine / keep-imported / merge decision (FR-34) |
| Today / Week / Month widgets | Home screen (OS-level) | Glanceable precomputed status; tap opens the app to that date (FR-31, FR-32) |

Bottom tab bar: **Today · Calendar · Goals · Settings**. Four tabs, no drawer. The creation wizard and the Cheat Day/Blackout sheet are the only modal-stack surfaces; neither ever stacks a second modal on top of itself.

## Voice and Tone

Plain, declarative, never encouraging. The app reports what the rule engine computed — it doesn't cheer, nag, or apologize on the user's behalf.

- States facts, not feelings: "Failed — 2 of 5 workdays missed," not "Don't give up!"
- Never uses exclamation points in system-generated copy (status labels, empty states, confirmations).
- Confirmation copy is specific about consequence, especially for the two irreversible-adjacent actions: archiving a Goal ("Archived Goals leave active views but keep full history") and Reset ("This erases all Goals, logs, and settings. This cannot be undone.").
- Import-conflict and validation copy names the exact problem (per FR-34's rejection list) — "This file references a Goal that no longer exists" — never a generic "Something went wrong."
- No streak-language cheerleading ("🔥 5 day streak!"); a Streak is reported as a plain number with its unit ("Streak: 5 weeks").

## Component Patterns

- **Guided creation wizard** (FR-6): one decision per step (name → tracking type → schedule → target → dates → reminders → review), `Back` always available, `Next` disabled until the current step validates. The wizard's hardest job is keeping the daily-evaluated-with-Cheat-Days pattern (e.g. "7×/week with 2 cheat days") visually and copy-wise distinct from a weekly-evaluated count pattern (e.g. "5×/week") at the schedule/target steps — these produce different Streak semantics (FR-6, FR-29) and must not be selectable by accident. The final Review step restates the full rule in one plain-language sentence (e.g. "Done at least 3 times a week, workdays only, starting Aug 18") before Save.
- **Day-view goal row**: tap toggles a Boolean goal or opens the Counter stepper; long-press (or an overflow icon on the row) opens the Cheat Day / Blackout Date sheet for that goal+date.
- **Counter entry**: a stepper (−/+) for quick increments plus a tappable numeric field for direct entry; decimals are valid input (FR-14). A negative correction is entered the same way — as a negative delta — and the row visibly floors at 0 rather than silently rejecting the input (FR-15).
- **Version Timeline** (FR-27): a horizontal, dated segment strip on Goal Detail, distinct from the historical calendar below it — each segment tap reveals that Version's rules as plain text, not a raw diff.
- **Widgets**: Today shows today's goal rows at reduced density (name + status dot only, no progress bars — no interaction beyond tap-through); Week and Month render the same `status-cell` grid as in-app, at whatever cell count the platform's widget size class allows.

## State Patterns

- **Pending vs. Empty vs. Fail** (FR-4, FR-5, FR-18): the three "not green, not yellow" states are visually and semantically distinct, never collapsed into a generic gray. Pending = in-progress, outcome not yet certain. Empty = not eligible today. Fail-by-zero-eligible-days (FR-5) is the one deliberate exception — a period with zero eligible days renders as Fail, not Empty, because it flags a likely misconfiguration.
- **DNF superseded** (FR-17): a day marked DNF shows a distinct "DNF (pending period close)" treatment until the enclosing period closes, at which point it silently resolves to whatever the evaluator actually computed — the UI never leaves a stale DNF mark visible after the real outcome is known.
- **Midnight rollover** (FR-20): if the app is left open across midnight with an uncommitted edit, that edit auto-commits to the day it was entered on, then every visible status recomputes — surfaced to the user only as the affected views quietly refreshing, not an interstitial or toast.
- **Import result**: three terminal states after a JSON import — clean merge (silent success, brief confirmation), conflicts found (routes to the conflict-resolution surface, one decision per conflict, no bulk "accept all"), or rejected (FR-34's validation list, shown as a specific reason, file untouched).
- **Empty states**: first-run Dashboard ("No goals yet — create your first one"), a Goals list filtered to a status with nothing in it, and Calendar for a date before any Goal's start date (rendered as `status-empty`, not a special "before start" treatment).
- **Offline is the only state** — there is no online/offline/syncing indicator anywhere in the product; network state is not a concept the UI ever surfaces (NFR-1).

## Interaction Primitives

- Horizontal swipe moves between months in Month view and between weeks in Week view (FR-23); a persistent "today" affordance jumps back regardless of how far the user has navigated.
- Tap = primary action (toggle Boolean, open detail); long-press = secondary/contextual action (Cheat Day, Blackout Date) — no swipe-to-reveal actions on rows, since combined with month-swipe gestures that would create gesture ambiguity.
- Destructive/irreversible actions (Reset only — FR-36) require a typed or explicit secondary confirmation step, per NFR/FR-36; every other action (archive, pause) is a single tap because it's reversible or history-preserving by construction (FR-2, FR-35).
- Wizard navigation is linear (Back/Next) with no step-skipping via tap-ahead — each step must validate before the next unlocks (FR-6).

## Accessibility Floor

- Status is never color-only: every `status-cell` and `status-badge` pairs its color with a glyph (✓ / ✕ / C / ellipsis / dash) and a screen-reader label that speaks the semantic state ("Failed, certain" / "Cheat day used" / "Pending, 2 of 3 remaining"), not the color name.
- Minimum 44×44pt tap targets on all interactive elements, including individual calendar day cells in Month view — cell visuals may be small, but hit areas are not.
- Text respects the OS dynamic-type/font-scale setting; layouts reflow rather than truncate at larger sizes (single-column layout, per `DESIGN.md` Layout & Spacing, makes this tractable).
- Color pairs in `DESIGN.md` (`colors`) target WCAG AA contrast for text-on-surface and status-glyph-on-status-fill in both light and dark; re-verify exact ratios against final rendered values at implementation time.
- No motion to disable — per `DESIGN.md`'s Do's and Don'ts, there is no celebratory or transition animation in the first place, so `prefers-reduced-motion` has nothing to override.

## Key Flows

- **UJ-1. Panda logs the day and checks progress.**
  Panda opens the app once a day (no fixed time). Entry state: no login, straight to the Dashboard. Path: Dashboard shows today's eligible goals; Panda marks Boolean goals done/not-done and enters/increments Counter values; the same view surfaces this week's and this month's in-progress goals for a glance. Climax: the day's status locks in — green if targets are met, red only once failure is certain, yellow if a Cheat Day was used. Resolution: Panda closes the app trusting that what's shown matches what they actually did, including for goals with irregular (every-3-days, specific-weekday, rolling-window) schedules.
  → Composition reference: `mockups/dashboard.html`, `mockups/calendar-month.html`.

- **Panda sets up an exotic goal.**
  Panda wants to track gym attendance: 3 times a week, workdays only, with the occasional planned skip. Entry: taps "+" from the Goals tab. Path: Name → picks Counter tracking type → schedule step, sets Evaluation Period to Weekly and Eligible-Days to the "Workdays" preset → target step, sets "At least 3" → dates step, start today, no end date → reminders step, opts into the single global reminder time → Review step shows the full rule as one plain sentence, including the daily-vs-weekly Streak distinction called out in FR-6 so Panda can confirm this is a weekly pass/fail goal with no daily Streak, not a daily one. Climax: Panda saves, and the goal immediately appears correctly on today's Dashboard (if today is a workday) or as `status-empty` (if not) — proving the rule was understood correctly before any log entry exists to hide a misconfiguration. Resolution: two months later Panda changes the target to "At least 4" mid-week; FR-3's versioning means the weeks already evaluated under "At least 3" don't silently change.
  → Composition reference: `mockups/wizard-schedule-step.html`.
