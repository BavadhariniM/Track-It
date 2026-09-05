---
name: Goal Tracker
description: Offline-first personal habit/goal tracker; a precise instrument for a genuine rule engine, not a gamified wellness app.
status: final
sources:
  - docs/brief.md
  - docs/prd/
  - docs/addendum/
  - docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md
updated: 2026-08-17
colors:
  bg-base: '#F4F6F8'
  bg-surface: '#FFFFFF'
  text-primary: '#101828'
  text-secondary: '#475467'
  text-muted: '#98A2B3'
  border-hairline: '#E4E7EC'
  accent: '#2E6F8E'
  accent-on: '#FFFFFF'
  status-success: '#2F9E67'
  status-success-on: '#FFFFFF'
  status-fail: '#D34A4A'
  status-fail-on: '#FFFFFF'
  status-cheat: '#D6A631'
  status-cheat-on: '#3A2A05'
  status-empty: '#E4E7EC'
  status-empty-on: '#98A2B3'
  status-pending: '#6B7CA0'
  status-pending-on: '#FFFFFF'
  bg-base-dark: '#0E1520'
  bg-surface-dark: '#141C2A'
  text-primary-dark: '#E6EAF0'
  text-secondary-dark: '#9AA6B8'
  text-muted-dark: '#5C6B82'
  border-hairline-dark: '#26314A'
  accent-dark: '#5DA8CC'
  accent-on-dark: '#0E1520'
  status-success-dark: '#3FBE82'
  status-success-on-dark: '#0E1520'
  status-fail-dark: '#E5675F'
  status-fail-on-dark: '#FFFFFF'
  status-cheat-dark: '#E3B94E'
  status-cheat-on-dark: '#2A1E02'
  status-empty-dark: '#26314A'
  status-empty-on-dark: '#5C6B82'
  status-pending-dark: '#8B9BC7'
  status-pending-on-dark: '#101828'
typography:
  display:
    note: 'Platform native — iOS Large Title · Android Display Small. Dashboard header, goal name on detail screen only.'
  title:
    note: 'Platform native — iOS Title 2 · Android Title Large. Screen titles, section headers.'
  body:
    note: 'Platform native — iOS Body · Android Body Large. Goal names in lists, form fields, primary reading text.'
  label:
    note: 'Platform native — iOS Subheadline (weight 600) · Android Label Large. Buttons, chips, status badges.'
  meta:
    note: 'Platform native — iOS Footnote · Android Body Small. Timestamps, counts, secondary detail (e.g. "2/3", "Paused since Jun 4").'
  numeric:
    note: 'Tabular/monospaced-figure variant of body, for counter values and stat numbers only, so digits do not shift width while incrementing.'
rounded:
  sm: 6px
  md: 12px
  lg: 18px
  full: 9999px
spacing:
  '1': 4px
  '2': 8px
  '3': 12px
  '4': 16px
  '5': 24px
  '6': 32px
  '7': 48px
components:
  button-primary:
    background: '{colors.accent}'
    text: '{colors.accent-on}'
    radius: '{rounded.md}'
    padding: '{spacing.3} {spacing.4}'
  button-secondary:
    background: transparent
    border: '1px solid {colors.border-hairline}'
    text: '{colors.text-primary}'
    radius: '{rounded.md}'
  status-cell:
    radius: '{rounded.sm}'
    success: '{colors.status-success}'
    fail: '{colors.status-fail}'
    cheat: '{colors.status-cheat}'
    empty: '{colors.status-empty}'
    pending: '{colors.status-pending}'
  status-badge:
    radius: '{rounded.full}'
    padding: '{spacing.1} {spacing.3}'
    text: '{typography.label}'
  goal-row:
    radius: '{rounded.md}'
    padding: '{spacing.3}'
    border: '1px solid {colors.border-hairline}'
  stat-card:
    background: '{colors.bg-surface}'
    radius: '{rounded.lg}'
    padding: '{spacing.4}'
    border: '1px solid {colors.border-hairline}'
  wizard-progress:
    height: 4px
    radius: '{rounded.full}'
    track: '{colors.border-hairline}'
    fill: '{colors.accent}'
  card-surface:
    background: '{colors.bg-surface}'
    border: '1px solid {colors.border-hairline}'
    radius: '{rounded.lg}'
---

# DESIGN.md — Goal Tracker

## Brand & Style

Goal Tracker reads as an instrument, not an app trying to be liked. The brief is explicit about what this product refuses to be: a streak-gaming wellness app that flatters the user into ignoring what actually happened. Every visual decision here serves that refusal — no confetti, no badges, no celebratory animation on a completed day, no color used for encouragement rather than fact. A day is green because the rule engine proved it succeeded; red because failure became mathematically certain (FR-18); yellow because a Cheat Day was deliberately spent. The interface's only job is to render that computation legibly and get out of the way.

The reference point is closer to a well-made gauge cluster than a lifestyle app: cool, restrained, high-legibility, built to be glanced at once a day and trusted immediately. Nothing about the surface should compete with the numbers it's reporting.

## Colors

`{colors.accent}` (steel-blue, `#2E6F8E` light / `#5DA8CC` dark) is used only for interactive elements and the wizard's progress fill — never for status. This separation is deliberate and load-bearing: FR-4 and FR-18 make status color a computed fact, not a design flourish, so the brand accent must never be mistaken for a status signal or vice versa.

The status set is fixed and semantic, reused identically across the calendar, dashboard, and widgets:

- `{colors.status-success}` — a day or period the evaluator confirmed met its target.
- `{colors.status-fail}` — failure is mathematically certain (FR-18); never shown merely because a day hasn't been logged yet.
- `{colors.status-cheat}` — a Cheat Day was spent against the goal's quota (FR-16).
- `{colors.status-pending}` — an in-progress period whose outcome isn't certain yet (FR-4); visually closer to the muted neutrals than to any pass/fail color, so it never reads as a disguised red or green.
- `{colors.status-empty}` — nothing scheduled (not eligible that day), except the FR-5 zero-eligible-day exception, which renders `status-fail`, not `status-empty`, by design.

`{colors.bg-base}` / `{colors.bg-surface}` split (page vs. card) is a one-step tonal lift, not a shadow-driven hierarchy — see Elevation & Depth. Text uses a three-step scale (`text-primary` / `text-secondary` / `text-muted`) so numeric detail (streak counts, "2/3") can recede without vanishing.

Dark mode is a first-class second definition of every token above (`-dark` suffix), not an inverted filter. The app follows the OS theme setting by default; there is no dedicated "brand" mode that overrides the user's system preference, consistent with this being a private, personal-use tool rather than a marketing surface.

## Typography

No custom typeface — platform-native type (San Francisco on iOS, Roboto on Android) at every role, per the `note` convention in `{typography}`. This is a deliberate parity decision (see Foundation in `EXPERIENCE.md`): the brief's stated success bar is functional parity across Android and iOS from one Flutter codebase, not a custom brand typeface that would need separate hinting/licensing per platform and add zero functional value to a single-user tool.

`{typography.numeric}` is the one departure from pure "inherit the platform default" — tabular figures are required anywhere a number updates live (Counter entry, streak count, dashboard "3/5 complete"), so digits don't visually jitter as their width changes.

## Layout & Spacing

The `{spacing}` scale is a plain 4px/8px-based ramp (`spacing.1`–`spacing.7`), used uniformly — no separate "editorial" or "marketing" spacing track, because there are no marketing surfaces in this product. `spacing.3`–`spacing.4` is the standard internal padding for rows and cards; `spacing.5`–`spacing.6` separates major sections on a screen (e.g. between the dashboard's "Today" card and its "This Week" rollup).

Single-column layouts throughout — this is a phone-first, one-hand tool used briefly once a day (UJ-1); there is no tablet/desktop-optimized multi-column mode in v1.

## Elevation & Depth

Flat by design. Hierarchy comes from the `bg-base` → `bg-surface` tonal step and a single 1px `{colors.border-hairline}`, not drop shadows — an instrument panel doesn't cast shadows on itself. The one exception is a light shadow (`0 1px 3px rgba(0,0,0,0.08)`, dark: `0 1px 3px rgba(0,0,0,0.4)`) reserved for the guided-creation wizard's bottom action bar and any modal sheet, so those read as temporarily "lifted" above the base screen.

## Shapes

Moderate, consistent rounding (`{rounded.sm}`–`{rounded.lg}`) — soft enough to feel calm and hand-usable, restrained enough to avoid a playful/toy register. `{rounded.full}` is reserved for two things only: status badges/pills and the wizard progress bar — never for primary buttons, which use `{rounded.md}` so the interface doesn't read as a consumer app with pill-everything chrome.

## Components

- **`status-cell`** — the calendar's atomic unit (day cell in Day/Week/Month views, and the widgets). Fixed-size square, `{rounded.sm}`, filled with exactly one of the five status colors, plus a compact glyph (✓ / ✕ / a "C" mark / an ellipsis for pending / a dash for empty) so status never depends on color alone — see Accessibility Floor in `EXPERIENCE.md`.
- **`goal-row`** — the recurring list item on the dashboard and goal-list surfaces: a status dot, the goal name, and either a "Done" label (Boolean) or a compact progress bar + fraction (Counter/period goals). Never shows a Cheat Day or Blackout Date inline as separate iconography beyond the status dot — those are period-level facts, surfaced on tap-through, not row-level clutter.
- **`stat-card`** — used on the Goal Detail screen for Streak, longest Streak, and completion percentage. Numeric-heavy, `{typography.numeric}`, no icons — the number is the content.
- **`wizard-progress`** — a thin top-of-screen bar in the guided creation flow (FR-6), filled proportionally to the current step of seven. No step numerals shown elsewhere in the UI; this is the flow's only persistent progress indicator, keeping the seven-step form from feeling longer than it is.
- **`button-primary`** / **`button-secondary`** — primary is reserved for the single forward-moving action per screen (Next, Save, Log); secondary covers Back, Cancel, and Edit. No tertiary/ghost/text-only button style — three tiers would be more than this app's action surface needs.

## Do's and Don'ts

- **Do** use the five status colors identically in the calendar, dashboard rollups, Goal Detail history, and widgets — one vocabulary everywhere, per AD-7's single-writer cache principle: the visualization layer must not invent a status the evaluator didn't produce.
- **Do** pair every status color with a glyph, never color alone.
- **Don't** use `{colors.accent}` for anything status-related — it must stay legible as "this is interactive," never "this is good/bad."
- **Don't** add celebratory motion, sound, or badges on goal completion. Correctness is the product's whole claim; congratulating the user for something the rule engine merely confirmed undercuts it.
- **Don't** introduce a second accent color, a gradient, or photography/illustration anywhere — the palette stays exactly as scoped above across every screen, including the three widgets.
- **Don't** let Pending read as a disguised pass or fail — it must sit visually between the neutrals and the status colors, never tinted toward green or red.
