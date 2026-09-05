/// Domain-defined, `home_widget`-agnostic abstraction for keeping the native
/// home-screen widgets' shared data container up to date (AD-7, FR-31) —
/// mirrors the [CacheWriter]/`StatsService`-style inversion pattern (AD-3):
/// implemented by `WidgetBridgeWriterImpl` in `data/widget_bridge/` (AD-1),
/// no `home_widget`/Flutter-widget-tree code lives here.
///
/// [writeAll] reads only already-computed `DayStatus` rows (via the existing
/// [StatusCacheRepository]) — it never reads `GoalLog`/`GoalVersion` rows to
/// derive a status itself and never calls `evaluate()` (Caching Policy:
/// widgets are cache-only, never live evaluation). Every call fully rebuilds
/// and overwrites all three scope payloads (today/week/month) from current
/// cache state — never an incremental patch — so a caller never needs to
/// reason about which scopes a given commit could have affected (Dev Notes:
/// "Full-scope-rebuild rule").
abstract interface class WidgetBridgeWriter {
  /// Rebuilds and writes the Today/Week/Month shared-container payloads for
  /// the local calendar day [today].
  Future<void> writeAll(DateTime today);
}
