# Adversarial Review — Goal Tracker Architecture Spine

Target: `docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md`
Method: for each candidate pair, both builders are assumed to read the spine in good faith, follow every AD Rule as literally written, and never talk to each other. The question asked of each pair: can they both be "correct" per the letter of the spine and still ship incompatible code?

Five divergence pairs survive scrutiny. They are ordered by severity (silent data-integrity breakage first, silent staleness/UX breakage last).

---

## Pair 1 — Daily-entry screen vs. Import feature: who is allowed to write a `GoalLog`, and by what path

**Builders:** Developer A builds the daily-entry screen (`presentation/screens/daily_entry`). Developer B builds the CSV/JSON import feature (FR-34).

**The clash:** Developer A reads AD-6's *Rule* sentence-by-sentence. The Rule says, verbatim:

> "`GoalService`... is the only component permitted to create a `GoalVersion`; every edit that changes target, eligible-days, or lifecycle state (pause/resume) routes through it. A `GoalVersion` is never mutated in place once `GoalLog`s exist against it. The correction-delta floor... is enforced inside the domain `GoalLog` aggregate itself — no caller, including import, can bypass it."

Every clause about mandatory routing through `GoalService` names `GoalVersion` specifically. The one clause that mentions `GoalLog` says the floor invariant is enforced *inside the domain `GoalLog` aggregate itself* — which reads naturally as "any caller can construct/mutate a `GoalLog` because the aggregate's own factory/mutator method guards the invariant regardless of who calls it." Developer A therefore wires the daily-entry screen's save button straight to `GoalLogRepository.upsert()` in the data layer, going through the `GoalLog` aggregate's own constructor for validation, and never touches `GoalService`. This is faster, avoids a service round-trip for a plain check-off, and is defensible line-by-line against the Rule.

Developer B instead reads the AD-6 *title* ("GoalService Owns Version **and Log** Mutation") and the Consistency Conventions table, which states flatly: "All `Goal`/`Version`/`Log` mutation routes through `GoalService` (AD-6)." Developer B therefore funnels every imported log row through `GoalService.recordLog(...)`.

Both are "compliant." The result: two mutation paths to the same table, one that bypasses `GoalService` entirely and one that doesn't. If `GoalService` is ever given responsibilities beyond floor-enforcement for logs — e.g., triggering `StatusCacheWriter` invalidation post-commit (see Pair 4), deduplication, or FR-15 correction-delta bookkeeping that spans more than one `GoalLog` row — Developer A's path silently skips it, and only import-derived data behaves correctly. This is exactly the "divergent versioning/mutation behavior between screens and import" AD-6 says it exists to *prevent*, reintroduced through the Log side of the same AD.

**Which AD's wording is loose:** AD-6's Rule (line ~72) is asymmetric — it makes `GoalVersion` routing mandatory in the Rule body but only implies `GoalLog` routing via the section title and a separate table (Consistency Conventions), not the Rule itself. A Rule and its own title disagreeing is a real hole, not a stretch.

**Tightened Rule:** Add an explicit sentence to AD-6's Rule (not just the title or the table): *"The same restriction applies to `GoalLog`: no repository, screen, or import path may construct, upsert, or mutate a `GoalLog` row directly. All log writes — including bulk import writes — call `GoalService.recordLog(...)` (or an explicitly named bulk variant), which delegates to the `GoalLog` aggregate for floor enforcement. The aggregate is not a public write path in its own right."*

---

## Pair 2 — Live-calendar repository vs. widget-bridge/cache-writer repository: unordered `List<GoalVersion>` breaks determinism across the two paradigm-defining callers

**Builders:** Developer A builds the data-layer query backing the live calendar (`presentation/screens/calendar`, FR-21–23). Developer B builds the data-layer query backing the widget precompute job / `StatusCacheWriter` (AD-7).

**The clash:** AD-4's signature is `evaluate({Goal goal, List<GoalVersion> versions, List<GoalLog> logs, DateTime date})`, and the Rule promises this function is "fully deterministic" and that "all four callers... call this same function; none re-implements evaluation logic." But determinism of a pure function is only as strong as its inputs, and the Rule never states that `versions` must be sorted, nor that `evaluate()` itself must sort internally before resolving "the Version active on that date" (AD-5).

Developer A's calendar repository issues `SELECT * FROM goal_versions WHERE goalId = ? ORDER BY id` (insertion order, the default index) because ordering was never a stated requirement and `id` order is the path of least resistance in Drift. Developer B's widget-bridge query, written independently, issues `ORDER BY versionStartDate ASC` because that's the natural order for a "find current version" scan. If the evaluator's internal boundary-resolution logic (AD-5: "locate the Version active on that date") is written as a linear/first-match scan rather than an explicit sort-then-scan, the two callers can hand it the *same* underlying rows in different order and get different `DayStatus` results for the identical Goal — for example, whenever two `GoalVersion`s exist whose applicability windows are resolved by scan order rather than by date comparison alone (this becomes a certainty, not just a risk, the moment Pair 3 below produces two Versions with an identical `startDate` — see below).

This is the paradigm's own stated failure mode reappearing one level down: AD-1 exists specifically to prevent "the evaluator... diverging between the live-calendar path and the cached widget/stats path." Both builders call the one shared `evaluate()` function, exactly as instructed — and still diverge, because the shared function's contract doesn't pin down input ordering, and nothing in AD-3/AD-4/AD-5 assigns sorting responsibility to either the caller or the callee.

**Which AD's wording is loose:** AD-4's Rule specifies the function's *purity* and *inputs* but not their *required ordering/canonicalization*; AD-5's Rule says "the Version active on that date" as if that's unambiguous given an arbitrary-order list, without saying how ties or ordering are resolved.

**Tightened Rule:** Add to AD-4: *"`evaluate()` treats `versions` and `logs` as unordered sets — it MUST sort by `versionStartDate` (resp. `date`) internally before any window resolution, and MUST NOT assume or require caller-side ordering. Callers may pass repository results in any order."* This closes the hole without asking every repository author to remember to sort.

---

## Pair 3 — Goal-edit screen vs. GoalService's own same-day-edit handling: duplicate `startDate` on `GoalVersion`

**Builders:** Developer A builds the "edit goal" flow inside the goal-detail screen, calling into `GoalService`. Developer B builds `GoalService.editGoal(...)` itself (a different slice, per the "GoalService vs. a screen that calls it" framing).

**The clash:** AD-6 says a `GoalVersion` is "never mutated in place once `GoalLog`s exist against it" — which by clear implication means it *can* be mutated in place when no `GoalLog`s exist yet against it. Nothing in AD-5 or AD-6 states whether two edits to the same Goal on the same calendar day (e.g., user changes the target at 9am, then again at 6pm, no logs recorded yet either time) should (a) mutate the same day's pending `GoalVersion` row in place, producing one row with `startDate = today`, or (b) always insert a fresh `GoalVersion` per edit call (since AD-6's Rule says "every edit... routes through it," read as "every edit produces a Version"), producing two rows that both have `startDate = today`.

If Developer A's UI treats "editing today's already-pending version" as calling the *same* `GoalService.editGoal` method used for any edit (not a special "amend" method), and Developer B's `GoalService` implementation defaults to "insert, don't update" for simplicity and auditability, the system now legitimately contains two `GoalVersion` rows with identical `startDate`. AD-5's Rule — "the Version active on that date" — never says what happens when more than one Version claims the same date. Combined with Pair 2, the two rows' relative order becomes the deciding (and non-deterministic, per-caller) factor in what `evaluate()` returns.

**Which AD's wording is loose:** AD-6's "never mutated in place once `GoalLog`s exist against it" establishes an exception (pre-log mutation is fine) without ever stating the corresponding rule as an obligation, and AD-5 has no tie-break for duplicate `startDate`.

**Tightened Rule:** Add to AD-6: *"A Goal has at most one `GoalVersion` per `startDate`. If `GoalService.editGoal` is called for a date that already has a `GoalVersion` with no `GoalLog`s against it, that Version is updated in place, not duplicated. If `GoalLog`s already exist against it, editing that date is rejected/redirected to the next eligible date, per FR-3."* This also removes the need for any tie-break logic in AD-5, since duplicates become structurally impossible.

---

## Pair 4 — Daily-entry write path vs. widget precompute job: who is the "domain use-case" that invokes `StatusCacheWriter`, and does it even legally exist under AD-1

**Builders:** Developer A wires the daily-entry screen's commit path (composition-root provider calling `GoalService`). Developer B wires the midnight-rollover job / widget precompute path that must also trigger `StatusCacheWriter`.

**The clash:** AD-7's Rule says the cache "has exactly one writer, a data-layer `StatusCacheWriter`, invoked by a domain use-case only after a `GoalLog` write commits, a `GoalVersion` write commits, or the midnight-rollover job... runs." But `StatusCacheWriter` is explicitly *data*-layer, and AD-1's Rule is unambiguous: "domain depends on neither [data nor presentation]. Only the composition root... imports across all three." A literal "domain use-case" (i.e., code living in `domain/`) calling directly into a data-layer class is a straight AD-1 violation. The spine's own Structural Seed has no `application/` or `usecases/` folder to house a legally-layered orchestrator — only `domain/`, `data/`, `presentation/`, `platform/` — so there is no named home for "the domain use-case" AD-7 requires.

Developer A resolves this by defining a small interface in `domain/services` (e.g. `abstract class CacheInvalidationPort`), implemented by `StatusCacheWriter` in `data/cache`, and injects it into `GoalService` via Riverpod (AD-2) so that every `GoalService` write commits and invalidates atomically from inside domain, satisfying AD-1 through interface inversion. Under this design, *every* caller of `GoalService` gets cache invalidation automatically.

Developer B, working on the midnight-rollover job and reading "domain use-case" more loosely as "a use-case concerned with domain data" rather than "code that lives in `domain/`," puts the orchestration in a `presentation/providers` composition-root provider instead — call `GoalService.recordLog(...)`, then separately call `statusCacheWriter.invalidate(...)`, both from the provider, since the composition root is the one place in the app AD-1 explicitly permits to import across all three layers.

These are not cosmetic differences. Under Developer A's design, cache invalidation is structurally guaranteed for any `GoalService` caller, including a future one nobody remembers to update. Under Developer B's design, invalidation is the *composition root's* responsibility per call site — meaning Pair 1's Developer A (daily-entry screen bypassing `GoalService` for logs) or *any* new call site that talks to `GoalService` without also remembering to call `statusCacheWriter.invalidate()` produces a silently stale cache, with no compiler or reviewer signal, since AD-7's text never states where this wiring must live.

**Which AD's wording is loose:** AD-7's Rule uses "a domain use-case" as the invoker without reconciling that phrase against AD-1's dependency direction, and without the Structural Seed defining any layer where such an object could legally exist. This is a Rule that is satisfiable in two structurally incompatible ways, one of which (Developer B's) reintroduces exactly the "ad-hoc code paths writing/triggering the cache" risk AD-7 says it prevents.

**Tightened Rule:** Either (a) add an `application/` (or `usecases/`) layer to the Structural Seed explicitly, with a stated rule "cache invalidation triggering lives here, never in presentation, never inline in a screen's provider," or (b) if no new layer is wanted, amend AD-7 to say explicitly: *"`GoalService`'s own commit methods are responsible for invoking cache invalidation, via a domain-defined interface implemented by `StatusCacheWriter` and injected via Riverpod. No other call site may invoke `StatusCacheWriter` for these three trigger events."* Either fix removes the two-structurally-different-but-both-"compliant" readings.

---

## Pair 5 — Statistics screen vs. widget precompute job: cache shape assumed richer than `DayStatus` alone

**Builders:** Developer A builds the long-range statistics screen (streaks, rolling averages, per-category rollups). Developer B builds the widget precompute job (Today/Week/Month glance data).

**The clash:** AD-7 says the cache "exists only to serve widgets and long-range stats" and must be "provably re-derivable from `evaluate()` over rules + logs at any time," with `StatusCacheWriter` as the one writer producing per-day `DayStatus` entries. AD-4 defines `evaluate()`'s *output* only as a single `DayStatus` per `(goal, date)` call — there is no stated aggregate shape (e.g., streak length, rolling N-day completion rate) anywhere in the domain layer or the cache contract.

Developer A, needing streaks and rolling averages, has two equally "compliant" options never disambiguated by the spine: (a) treat the per-day cache as the only persisted artifact and compute all rollups in the statistics screen/provider by reading a range of cached `DayStatus` rows and folding over them at read time, or (b) — reasoning that "long-range stats" is explicitly named as something the cache "exists to serve" in AD-7 — assume `StatusCacheWriter` itself should also persist precomputed rollups (streak-so-far, rolling sums) as additional cached fields/rows, since recomputing a rolling window over potentially years of per-day rows on every stats-screen open is exactly the kind of cost AD-3 says Drift's schema exists to avoid ("rolling-window aggregation... the data model requires"). Developer B, building only the widget precompute job, never persists anything beyond bare per-day `DayStatus`, because AD-4's `evaluate()` output type is the only shape named anywhere in the spine.

If Developer A goes with reading (b), the statistics screen depends on cache fields `StatusCacheWriter` (built independently by Developer B, or simply not extended because nothing in AD-7 told Developer B to) never populates — a silent, compile-time-invisible gap (or, if using a loosely-typed cache row, a runtime null/zero that reads as "no streak" rather than "not computed").

**Which AD's wording is loose:** AD-7 names "long-range stats" as a cache consumer but never states the cache's persisted shape beyond reusing `DayStatus` from AD-4, and AD-3's mention of "rolling-window aggregation" as a scenario Drift's schema must support is never connected back to whether that aggregation is precomputed-and-cached or computed-at-read-time over cached per-day rows.

**Tightened Rule:** Add to AD-7: *"The cache persists exactly one row shape: per-`(goal, date)` `DayStatus`, nothing richer. Streaks, rolling averages, and other multi-day rollups are computed at read time by the statistics screen/provider folding over a range of cached `DayStatus` rows — `StatusCacheWriter` never persists pre-aggregated rollup fields."* (Or the opposite, explicit choice, if precomputed rollups are actually wanted — either resolves it, the current text does neither.)

---

## Summary Table

| Pair | Screens/agents | AD with loose wording | Failure mode if unresolved |
| --- | --- | --- | --- |
| 1 | Daily-entry screen vs. Import | AD-6 (Rule body silent on Log routing vs. its own title + Consistency Conventions table) | Two GoalLog write paths; one silently skips future GoalService-side invariants |
| 2 | Live calendar vs. widget/cache repositories | AD-4 (no ordering contract on `versions`/`logs` inputs) + AD-5 (no tie-break) | Same Goal, different DayStatus, between the two paths AD-1 exists to keep in sync |
| 3 | Goal-edit screen vs. GoalService internals | AD-6 (implies in-place mutation is allowed but never obligates it) + AD-5 (no duplicate-startDate handling) | Duplicate GoalVersion rows sharing a startDate; feeds Pair 2 |
| 4 | Daily-entry write path vs. midnight-rollover/widget job | AD-7 ("domain use-case" invoking data-layer class contradicts AD-1; no layer named to host it) | Cache invalidation wiring is structurally inconsistent; new call sites silently skip it |
| 5 | Statistics screen vs. widget precompute job | AD-7 (cache row shape unstated beyond DayStatus) + AD-3 (rolling-window aggregation mentioned but not placed) | Stats screen depends on rollup fields the cache writer never populates |

All five pairs satisfy the review's bar: both builders can point to specific AD wording that licenses their choice, and the two choices are not merely stylistically different but produce incompatible data shapes, state-mutation paths, or evaluation results.
