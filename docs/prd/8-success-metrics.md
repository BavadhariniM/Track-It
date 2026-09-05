# 8. Success Metrics

**Primary**
- **SM-1**: Tracker replaces whatever method was used before — daily logging happens consistently rather than lapsing. Self-assessed periodically via the Statistics screen (FR-28), since no telemetry is collected. Validates FR-13, FR-14, FR-26.
- **SM-2**: Zero instances where displayed status contradicts what the user knows actually happened, including under the exotic scheduling patterns in §4.2. Validates FR-4, FR-12, FR-18.
- **SM-3**: Android and iOS are equally usable day-to-day — neither platform is quietly avoided. Self-assessed by the user actually using both installs day-to-day, since no telemetry distinguishes platform usage. Validates all of §4.

**Counter-metrics (do not optimize)**
- **SM-C1**: Usage frequency should not be driven by naggy notifications guilting the user into opening the app. Counterbalances SM-1.
- **SM-C2**: Correctness (SM-2) must be verified against genuinely exotic real-world Goals the user actually runs — not just the simple cases from the worked-example table. Counterbalances SM-2.
