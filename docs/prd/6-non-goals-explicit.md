# 6. Non-Goals (Explicit)

- No cloud sync, account system, or login — ever, by architectural design, not a deferred feature.
- No web version; Android and iOS native only.
- No cross-Goal dependencies or if-then/conditional branching between Goals.
- No percentage targets, streak-dependent targets, time-of-day requirements, duration tracking, or multiple measurements per day in MVP. `[NOTE FOR PM]` The rule engine should not be architecturally designed in a way that precludes adding these later, per the original v1 framing, but none are built now.
- No CSV or ZIP export.
- No lock-screen widgets.
- No per-Goal custom reminder times — one global reminder time for MVP.
- No telemetry, analytics, or crash reporting — see NFR-2.
- No multi-device sync; moving data between devices is a manual export/import (merge).
- No timestamped multi-entry logging (e.g. a distinct 8am/12pm/5pm log with per-entry notes) — Counter Goals instead support repeated same-day increments summed into one total, with no per-increment timestamp (FR-14). This is a narrower mechanism than `docs/brief.md`'s original "in for v1" description; see `addendum.md`.
