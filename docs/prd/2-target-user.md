# 2. Target User

## 2.1 Jobs To Be Done

- As the builder, I need a habit/goal tracker that models my actual commitments precisely — including irregular schedules that don't fit a simple daily checkbox — so I can trust what it tells me instead of gaming or ignoring it.
- I need to open the app once a day, log what happened, and immediately see accurate progress across today/this week/this month in one place.
- I need my data to be mine — fully offline, no account, no server, no telemetry — because privacy is a hard requirement, not a preference.
- I need to be able to move my data to a new device or back it up without depending on any service staying online.

## 2.2 Non-Users (v1)

Tracker is explicitly single-user by design, not just for v1 — there is no account system, no sharing, and no multi-user data model to grow into. This is a firmer commitment than `docs/brief.md`'s original framing, which left wider-audience use explicitly "undecided"; this PRD forecloses it deliberately (confirmed twice during PRD creation — see `.memlog.md`), rather than leaving the door open. Anyone looking for a shared/family habit tracker, a team accountability tool, or a cloud-synced multi-device experience is not the audience for this product as scoped.

## 2.3 Key User Journeys

- **UJ-1. Panda logs the day and checks progress.**
  Panda opens the app once a day (no fixed time). Entry state: no login, straight to the dashboard. Path: dashboard shows today's eligible goals; Panda marks Boolean goals done/not-done and enters/increments Counter values; the same view also surfaces this week's and this month's in-progress goals for a glance. Climax: the day's status locks in — green if targets are met, red only once failure is certain, yellow if a cheat day was used. Resolution: Panda closes the app trusting that what's shown matches what they actually did, including for goals with irregular (every-3-days, specific-weekday, rolling-window) schedules.

This is the only journey the product needs to support well — there is one user, one recurring loop, and the goal engine's correctness is what makes that loop trustworthy.
