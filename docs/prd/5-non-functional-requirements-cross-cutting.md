# 5. Non-Functional Requirements (Cross-Cutting)

### NFR-1: Offline-First, Absolute
100% of core functionality works with no internet, ever. No login, no account, no backend server, no cloud database — not "usually," architecturally impossible to require.

### NFR-2: Zero Telemetry / Privacy
No telemetry, analytics, or crash reporting of any kind — not even opt-in/anonymous. No third-party network calls at all.

### NFR-3: No Timezone/DST Handling
Single-device assumption holds; all evaluation happens in local device time. No cross-timezone travel logic, no daylight-saving adjustment logic.

### NFR-4: Single-Device Data
No automatic sync between devices. Moving data between devices is a manual export/import (merge) operation (FR-33/FR-34), never automatic.

### NFR-5: Platform Parity
Android and iOS are both fully functional at initial release — not sequential, not one-primary-one-afterthought.

### NFR-6: Correctness as Core Quality Bar
Since the product's stated edge is rule-engine correctness (§1 Vision), edge-case evaluation logic — the exotic recurrence, rolling-window, and day-boundary cases in §4.2–4.3 — is treated as a first-class acceptance bar, not a nice-to-have, and should carry into test/acceptance criteria downstream.

### NFR-7: Data Durability
Only an in-flight unsaved entry is ever at risk (FR-19). Everything committed survives app kills, crashes, and midnight rollovers (FR-20).
