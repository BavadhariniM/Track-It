# Caching Policy (requirements-v2.md §23.1)

- The live calendar (day/week/month views, FR-21–FR-23) is never cached — always computed fresh from rules + logs + Cheat Days.
- A per-day status cache exists only to serve the widgets (FR-31) and long-range statistics (FR-28) — a read-optimization, explicitly not a second source of truth. This is why widgets show cached status rather than live evaluation: it's a deliberate performance/battery tradeoff v2 made, not a correctness compromise, since the cache is provably re-derivable from the same source data at any time.
