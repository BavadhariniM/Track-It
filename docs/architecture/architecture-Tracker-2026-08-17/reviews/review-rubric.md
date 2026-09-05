---
title: 'Architecture Spine Review — Goal Tracker'
type: review
reviews: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md
against: good-spine checklist (7 criteria)
created: '2026-08-17'
---

# Review: ARCHITECTURE-SPINE.md — Goal Tracker

## Verdict: Needs Revision

The paradigm choice, the layering ADs (AD-1/2/3), and — especially — AD-5's resolution of the PRD's explicitly-deferred version-boundary question are genuinely good spine work: concrete, enforceable, and traceable to the FR/NFR that motivates them. But the spine's centerpiece, the pure evaluator contract (AD-4), has a function signature that cannot actually compute the statuses the PRD requires (Cheat Days and Blackout Dates are not inputs to `evaluate()`), and the data model it presents omits the entities those two features need. Because rule-engine correctness is this product's entire stated reason for existing (Vision, NFR-6, SM-2), a gap in the evaluator contract is not a nitpick — it is exactly the kind of divergence point this altitude exists to close. Several other structural dimensions (streaks, import/export ownership, widget data-contract format, notification-trigger logic) are silently absent rather than decided or deferred. Recommend a revision pass before this is used as build substrate.

---

## Findings

### 1. [Critical] AD-4's evaluator signature omits Cheat Days and Blackout Dates, so it cannot implement FR-16/FR-10/FR-18 as specified

**Where:** AD-4 (lines 56–60); Evaluator flow diagram (lines 159–174).

AD-4's Rule fixes the exact signature: `DayStatus evaluate({Goal goal, List<GoalVersion> versions, List<GoalLog> logs, DateTime date})`. There is no parameter for Cheat Days or Blackout Dates.

But per the PRD, both are load-bearing inputs to the exact computation AD-4 claims to own:
- FR-16: a Cheat Day "does not reduce any Target Comparison's required count" but does exempt that day from failure — i.e. it changes whether FR-18's "failure is mathematically certain" test can fire on that date.
- FR-10: a Blackout Date "exempts that date from failure... but does not reduce the Goal's eligible-day count or target" — again, a direct input to the same certain-failure computation, with the added constraint that its accounting must differ from Cheat Days ("do not consume the Goal's Cheat Day quota — a separate mechanism").
- FR-18's worked consequence ("Weekly 'at least 3 of 5 workdays' does not turn red until 3 of the 5 eligible days have already been missed") is only correct if the function knows which of those missed days were exempted by a Cheat Day or Blackout Date.

As written, a story implementing `evaluate()` literally cannot satisfy FR-16 + FR-18 together from the given signature — it would have to either (a) silently smuggle cheat/blackout data in through the `logs` list (undocumented, and conflates two different exemption mechanisms the PRD explicitly says must stay separate), or (b) extend the signature on its own judgment. Either path is exactly the kind of two-independently-built-units divergence this spine exists to prevent, on the single most correctness-critical function in the app. The evaluator flowchart (lines 161–174) reinforces the same gap: it goes straight from "combine eligible days + logs" to the failure-certainty decision, with no step for applying cheat/blackout exemptions.

**Fix:** Extend AD-4's Rule to include Cheat Days and Blackout Dates as explicit, separate parameters (or an explicit sub-type wrapping them), and add a step to the flowchart showing where exemptions are applied before the certain-failure check.

### 2. [High] Core-entity ERD has no representation for Cheat Days, Blackout Dates, or DNF markers

**Where:** "Core-entity relationships" ERD (lines 124–155).

The ERD presents `GOAL` / `GOAL_VERSION` / `GOAL_LOG` as "the" data model ("three-table split per addendum, supports FR-3 versioning"). But three first-class FRs have no home in it:
- FR-16 Cheat Days — need per-Goal, per-date storage, and quota accounting that resets each Evaluation Period. Not a field on any of the three tables shown.
- FR-10 Blackout Dates — need per-Goal, per-date storage, optionally with a reason string ("add reason if needed" per FR-10's text). Not present.
- FR-17 DNF marking — a manual per-day annotation distinct from a `GoalLog` entry. `GOAL_LOG` has no `dnf` field, and DNF is conceptually "superseded" rather than a log value, so overloading `GOAL_LOG` for it is questionable.

This is the same root problem as Finding 1 viewed from the data side: the spine claims the data model dimension is decided, but it's decided for 3 of the ~6 entities/concepts the FRs actually require. Two stories built independently (one implementing Cheat Day marking UI, another implementing the evaluator's exemption check) have no shared contract for where this data lives or what shape it is.

**Fix:** Either add `CHEAT_DAY` / `BLACKOUT_DATE` entities (with FK to `Goal`, a `date`, and — for Cheat Days — enough context to compute quota-per-period) to the ERD, or state explicitly how they're encoded onto the existing three tables, and route their mutation through AD-6 the same way Version/Log mutation is routed.

### 3. [Medium] Streak calculation (FR-29) has no architectural owner

**Where:** Not addressed anywhere in the spine.

FR-29 is itself a rule-engine-correctness item with real edge cases ("Streak counts consecutive successful Evaluation Periods, not consecutive days... Rolling Window Goals have no Streak stat"), and NFR-6 explicitly says edge-case evaluation logic is a first-class acceptance bar. AD-4 governs `evaluate()` for a single date's `DayStatus`; nothing says whether streak aggregation is a second pure domain function, a use-case layered on top of `evaluate()`, or logic living in the stats/presentation layer. Given the spine's own argument for AD-4 (evaluation must be one shared, pure, testable function so callers can't diverge), leaving streak computation unassigned is a matching gap: the dashboard, goal-detail screen, and stats screen (FR-26, FR-27, FR-28) all need it and could each implement it differently.

**Fix:** Either fold streak computation into the domain layer under an explicit AD/rule (e.g. a second pure function consuming `evaluate()` output over a range), or note it in Deferred with a reason it's safe to leave open — silence isn't either.

### 4. [Medium] Import/export (FR-33/FR-34) validation and merge logic has no assigned layer

**Where:** Deferred section only addresses the import-conflict *UX* (line 178); the validation/merge logic itself is unaddressed.

FR-34's consequences list a substantial, correctness-sensitive validation surface (schema-version mismatch, duplicate IDs, orphaned logs, invalid dates, contradictory rules like min > max, invalid Cheat Day quota references). This is exactly the shape of logic AD-4's rationale argues should be pure/testable/domain-owned — but the spine never says whether import validation lives in `domain` (testable in isolation, consistent with the paradigm) or is glue code in `data`. The Deferred entry correctly scopes out the *UX flow* (modal vs. list) as UX's call, but conflates that with the architecturally-relevant question of where the validation rules themselves are enforced, which this altitude does own.

**Fix:** Add a short rule (or explicit Deferred note with rationale) assigning import validation/merge logic to a layer, consistent with AD-1's dependency direction.

### 5. [Medium] Widget data-contract format is claimed as "governed here" but never actually specified

**Where:** AD-7 (lines 74–78); Deferred, "Native home-screen widget implementation" (line 180); Structural Seed `widget_bridge/` comment (line 111).

AD-7 establishes `StatusCacheWriter` as the single writer of the cache, and the Deferred section states "the data contract (`StatusCacheWriter` → shared container, AD-7) is governed here" — but no schema, format, or versioning for that shared-container payload is given anywhere in the document. This is precisely the kind of contract where two independently-built units (Dart-side `widget_bridge` and native Kotlin/Swift widget code, built at different times, possibly by different sessions) are most likely to diverge, since neither side can type-check against the other. The claim that this is "governed" isn't backed by an actual rule.

**Fix:** Either add a minimal AD/convention pinning the shared-container format (e.g. "JSON with fields X/Y/Z, written to `home_widget`'s standard shared-preferences/UserDefaults key"), or move this line out of "governed here" framing and into Deferred honestly.

### 6. [Low-Medium] Notification trigger/suppression logic (FR-30) has no architectural home

**Where:** Not addressed anywhere in the spine; `flutter_local_notifications` only appears in the Stack table.

FR-30's suppression consequence (don't fire for ineligible days, paused/archived Goals, or Goals already at target) needs to consult the same evaluation state as everything else AD-4 governs, but nothing says which layer decides when to (re)schedule notifications or how that decision calls into `evaluate()`/`GoalService`. Low-medium because the logic is narrower than the evaluator/data-model gaps above, but it's still a real cross-cutting concern this altitude typically owns.

### 7. [Low-Medium] Testing strategy is decided only for the domain layer

**Where:** Structural Seed, `test/` (line 118–119): only `test/domain/` is listed.

Given NFR-6 makes correctness the core quality bar, and the checklist explicitly treats "testing strategy" as a dimension that can't be silently left partial, the spine should say something — even briefly — about whether/how the data layer (repository round-trips, cache-recompute-equals-live-evaluate invariant that AD-7 depends on), presentation layer, and the native widget code get tested, or explicitly defer each with a reason. As written, only the evaluator's test story is decided; the cache's core claim ("provably re-derivable... at any time," AD-7) has no stated test obligation even though it's the kind of invariant that rots silently if untested.

### 8. [Low] `endDate` (FR-1, drives FR-2's "Expired" lifecycle state) is absent from the ERD

**Where:** `GOAL` entity, ERD (lines 128–134).

Minor relative to Findings 1–2 since it's a single scalar field on an entity that already exists (not a missing entity), and reasonable to read as the ERD being non-exhaustive by design. Still, `endDate` is what drives the `Expired` state in FR-2 and is explicitly called out in FR-1 ("optional end date, or no end date") — worth a one-line mention or an explicit "ERD is illustrative, not exhaustive" caveat so readers don't mistake the omission for a decision that Expired is computed some other way.

### 9. [Low, nitpick] Stack table verification rigor is inconsistent across rows

**Where:** Stack table (lines 90–96).

`flutter_riverpod`/`riverpod_generator` and `drift`/`drift_flutter` carry explicit "verified via web search 2026-08-17" tags; `home_widget` has "(verified June 2026)"; `flutter_local_notifications` has neither a search-verification tag nor a date, just "actively maintained 2026." Not a substantive problem (all four read as current, plausible choices), but the inconsistent sourcing means a reader can't tell whether the `flutter_local_notifications` line was actually checked or asserted from training-data familiarity — which is precisely the distinction the checklist asks the spine to make legible.

### 10. [Low, nitpick] Design Paradigm's justification paragraph reads as memlog rationale, not invariant

**Where:** Lines 26 ("The reason this paradigm and not something looser...").

One paragraph of narrative "why we chose this over something looser" prose, distinct from each AD's terse Prevents/Rule structure. It's contained (not repeated throughout the doc) and does carry real signal (ties the paradigm directly to the two-callers-one-evaluator requirement), so this is a minor stylistic note rather than a real bloat problem — the rest of the document stays lean and doesn't repeat this pattern.

---

## Checklist Scorecard

| Criterion | Verdict |
| --- | --- |
| Fixes real divergence points, misses none that matter | **Fail** — evaluator contract (Finding 1) and data model (Finding 2) miss two FR-load-bearing mechanisms; streaks, import/export ownership, widget contract, notifications also unaddressed (Findings 3–6) |
| Every AD's Rule is enforceable and prevents its stated divergence | **Partial** — AD-1/2/3/5/6/7 are enforceable; AD-4 is enforceable-as-written but the thing it enforces is incomplete relative to the FRs it must satisfy |
| Nothing under Deferred could cause meaningful divergence | **Pass** — the six Deferred items are legitimately safe to defer (UX flow detail, unresolved PRD field, platform-native UI, release process, pinned versions, explicit non-goals); the widget-contract claim (Finding 5) is more a "claimed but not actually delivered" issue than a wrongly-deferred item |
| Named technology reads as verified-current | **Pass, with a minor nitpick** — two of four Stack rows show explicit search-verification with dates; two are weaker (Finding 9) but nothing looks stale or wrong |
| Every structural dimension is decided/deferred/open — none silently missing | **Fail** — data model (Finding 2), testing strategy beyond domain (Finding 7), streak ownership (Finding 3), import/export layer (Finding 4), widget contract (Finding 5), notification logic (Finding 6) are all silent |
| Spine stays lean | **Pass** — Stack/Structural Seed correctly marked as seed not invariant; one minor rationale paragraph (Finding 10) is the only padding found |
| Diagrams are valid Mermaid and convey real structure | **Pass, syntactically** — all three diagrams (layer graph, ERD, evaluator flowchart) appear to be valid Mermaid and genuinely convey structure rather than being decorative; the ERD and flowchart both inherit the substantive incompleteness from Findings 1–2 (correct as far as they go, just missing nodes/entities) |
