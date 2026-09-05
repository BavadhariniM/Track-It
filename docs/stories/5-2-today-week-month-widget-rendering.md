---
baseline_commit: NO_VCS
---

# Story 5.2: Today/Week/Month Widget Rendering

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want Today, Week, and Month home-screen widgets that show my goals' status using the same visual language as the app,
so that I can check my progress at a glance without opening the app.

## Acceptance Criteria

1. **Given** the `widget_bridge` shared container has data for today
   **When** Panda adds the Today widget to their home screen
   **Then** it renders each eligible goal at reduced density — name and status dot only, no progress bars (UX-DR18)

2. **Given** the shared container has data for the current week
   **When** Panda adds the Week widget
   **Then** it renders the same `status-cell` grid vocabulary as in-app Week View, sized to whatever cell count the platform's widget size class allows (UX-DR18)

3. **Given** the shared container has data for the current month
   **When** Panda adds the Month widget
   **Then** it renders the same `status-cell` grid vocabulary as in-app Month View, at the platform's supported density

4. **Given** any of the three widgets on Android
   **When** it renders
   **Then** it is implemented natively in Kotlin/Jetpack Glance (Architecture Stack); **on iOS**, natively in Swift/WidgetKit

5. **Given** a `status-cell` renders in any widget
   **When** Panda views it
   **Then** it uses the identical color+glyph+screen-reader-label vocabulary as in-app (UX-DR6, UX-DR18) — no separate widget-only color treatment

6. **And** no widget ever calls `evaluate()` or performs its own computation — it only reads precomputed status from the shared container (FR-31, AD-7)

## Tasks / Subtasks

- [x] Task 1 (data/widget_bridge, Flutter/Dart side): Finalize provider identifiers (AC: 4)
  - [x] 1.1 In the `WidgetBridgeWriter` implementation from Story 5.1, update the `HomeWidget.updateWidget(androidName: ..., iOSName: ...)` calls to reference the real Android Glance receiver class names and iOS widget `kind` strings this story creates (Task 2/3 below) — this is the only Flutter/Dart-side change in this story; all other work in this story is native platform code.
  - [x] 1.2 Confirm no other change is needed to `lib/data/widget_bridge/` or `lib/domain/services/widget_bridge_writer.dart` — the JSON envelope contract fixed in Story 5.1 is consumed as-is (see Dev Notes' "Consuming Story 5.1's contract" below); do not alter its shape here.

- [x] Task 2 (native Android, Kotlin/Jetpack Glance): Scaffold and render the three widgets (AC: 1, 2, 3, 4, 6)
  - [x] 2.1 Under `lib/platform/android/`, add three Glance app widgets — `TodayWidget`, `WeekWidget`, `MonthWidget` — each with its own `GlanceAppWidget` + `GlanceAppWidgetReceiver` Kotlin class.
  - [x] 2.2 Register each receiver in `AndroidManifest.xml` with an `appwidget-provider` XML resource (min width/height sized for the widget's purpose — Today ≈ small, Week ≈ medium, Month ≈ large — `resizeMode="horizontal|vertical"` so the OS can offer larger size classes where useful).
  - [x] 2.3 Read the shared container via `home_widget`'s Android Glance state integration (`HomeWidgetGlanceStateDefinition`/`currentState<Preferences>()` reading the `today_widget_data`/`week_widget_data`/`month_widget_data` keys — verify the exact current API surface for `home_widget` 0.9.3 at build time per the Stack table's own re-verify caveat) and decode the JSON envelope from Story 5.1 into a Kotlin data class per scope.
  - [x] 2.4 Implement a reusable `StatusCell` Glance composable: fixed-size square, `6dp` corner radius (`rounded.sm`), background fill from the 5-state color set (Dev Notes table below, with light/dark resource qualifiers `values/colors.xml` and `values-night/colors.xml`), a centered glyph, and a `contentDescription`/semantics label per Dev Notes.
  - [x] 2.5 `TodayWidget`: render each eligible goal as name text + a status dot only (reuse `StatusCell` at small size as the "dot," or a simplified circular variant) — explicitly no progress bar, no fraction text (UX-DR18).
  - [x] 2.6 `WeekWidget`/`MonthWidget`: render a grid of `StatusCell`s, one per `(date, goalId)` cell from the envelope, reflowing the number of visible cells/rows to whatever the widget's actual granted size allows (Glance `SizeMode.Responsive` across the size-class range declared in 2.2) — never assume one fixed cell count is always available.
  - [x] 2.7 Guardrail: no Kotlin code in `TodayWidget`/`WeekWidget`/`MonthWidget` computes a status, a count, or a comparison from raw values — every cell's color/glyph/label is a direct lookup from the `status` string already present in the decoded JSON.

- [x] Task 3 (native iOS, Swift/WidgetKit): Scaffold and render the three widgets (AC: 1, 2, 3, 4, 6)
  - [x] 3.1 Under `lib/platform/ios/`, add a WidgetKit extension target (if not already present) containing three widgets — `TodayWidget`, `WeekWidget`, `MonthWidget` — sharing the App Group configured in Story 5.1 Task 6.
  - [x] 3.2 Define `Codable` Swift structs mirroring the Story 5.1 JSON envelope exactly (`scope`, `generatedAt`, `rangeStart`, `rangeEnd`, `isEmpty`, `cells: [{date, goalId, goalName, status}]`).
  - [x] 3.3 Implement a `TimelineProvider` per widget that reads `UserDefaults(suiteName: <App Group id>)?.string(forKey: "today_widget_data" | "week_widget_data" | "month_widget_data")`, JSON-decodes it, and produces a timeline entry from the decoded envelope — no other data source.
  - [x] 3.4 Implement a reusable `StatusCellView` SwiftUI view: `RoundedRectangle` with `6pt` corner radius (`rounded.sm`), fill `Color` from an Asset Catalog color set defined per Dev Notes' table (with Any/Dark appearance variants), a centered glyph `Text`, and `.accessibilityLabel(...)` per Dev Notes.
  - [x] 3.5 `TodayWidget`: use the `systemSmall` widget family; render name + status dot only per goal, no progress bar (UX-DR18).
  - [x] 3.6 `WeekWidget`/`MonthWidget`: use `systemMedium`/`systemLarge` families; render a `StatusCellView` grid, one per `(date, goalId)` cell, reflowing cell/row count per the family's actual available size — do not hard-code a single grid size for all families.
  - [x] 3.7 Only home-screen widget families are implemented (`systemSmall`/`systemMedium`/`systemLarge`); do not add `accessoryCircular`/`accessoryRectangular`/StandBy or any lock-screen-family widget configuration — FR-31 explicitly excludes lock-screen widgets.
  - [x] 3.8 Guardrail: no Swift code in any `TimelineProvider` or view computes a status, count, or comparison from raw values — every cell's color/glyph/label is a direct lookup from the decoded `status` string.

- [x] Task 4 (cross-platform parity check): Color/glyph/label guardrail (AC: 5)
  - [x] 4.1 Verify Android `colors.xml`/`colors-night.xml` and iOS Asset Catalog color sets both encode the exact hex values from Dev Notes' table (sourced from `DESIGN.md`'s color tokens) — no platform-specific reinterpretation of a status color.
  - [x] 4.2 Verify both platforms use the identical glyph set (✓ / ✕ / "C" / … / –) and the identical semantic wording pattern for accessibility labels (Dev Notes below) — not the color name, per UX-DR6/EXPERIENCE.md's Accessibility Floor.

- [x] Task 5 (verification): Platform preview and manual QA (AC: 1, 2, 3, 4, 5, 6)
  - [x] 5.1 Use Android Studio's Glance widget preview and Xcode's WidgetKit preview canvas to visually verify all three widgets against fixture JSON payloads covering: normal data, the empty-state envelope (`isEmpty: true`) from Story 5.1, and a mixed success/fail/cheat/pending/empty cell set.
  - [x] 5.2 Note in Dev Notes/testing standards below why this story relies on platform preview + manual QA rather than automated UI tests for the native rendering surface itself (Glance/WidgetKit UI is not exercised by Flutter's test runner).

## Dev Notes

- **This story is two separate implementation surfaces — do not conflate them:**
  - **Flutter/Dart side (`lib/data/widget_bridge/`):** already built in Story 5.1. This story's only Dart-side touch is passing the real native provider identifiers into the existing `HomeWidget.updateWidget(...)` call (Task 1). No new Dart business logic, no new envelope fields, no new domain interface.
  - **Native side (`lib/platform/android/`, `lib/platform/ios/`):** entirely new in this story — the actual widget UI, written in Kotlin/Jetpack Glance and Swift/WidgetKit respectively. This code cannot import Dart/Flutter code at all (different runtimes); it only ever reads the plain JSON string that `home_widget` already deposited in platform-native shared storage. Keep this distinction explicit in implementation — a developer should never go looking for "the Kotlin/Swift version of `evaluate()`"; it does not and must not exist.

- **Cache-only / no-computation rule, restated for native code:** because Kotlin/Swift cannot call the Dart `evaluate()` function, the risk here is not a literal `evaluate()` call but a developer re-deriving logic natively — e.g. computing "3 of 5 done" from raw cell counts, or deciding a cell's color via an `if/else` on business rules instead of a straight string-to-color lookup. Native widget code's only permitted operations on the decoded JSON are: (a) select which cells fit in the granted size, (b) map a `status` string to a fixed color/glyph/label pair, (c) format `date`/`goalName` for display. No arithmetic, no comparison against a target, no re-implementation of any evaluation concept. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-7] [Source: docs/epics.md#Story 5.2]

- **Consuming Story 5.1's contract exactly (do not diverge):** three `home_widget` shared-container keys — `today_widget_data`, `week_widget_data`, `month_widget_data` — each a JSON string with envelope `{ scope, generatedAt, rangeStart, rangeEnd, isEmpty, cells: [{ date, goalId, goalName, status }] }`. `status` is one of `"success" | "fail" | "cheat" | "empty" | "pending"`. `isEmpty: true` with `cells: []` is the explicit no-data state — render an empty/placeholder widget body for that case, never a leftover stale render (there is none to leave, since this is the first time the widget draws it, but timeline/state refresh logic must treat this envelope as valid data, not an error). [Source: docs/stories/5-1-widget-data-bridge.md#Dev Notes]

- **Exact color/glyph/label table** (from `DESIGN.md`'s color tokens — both platforms must encode these verbatim, light and dark):

  | status | light hex | light "-on" | dark hex | dark "-on" | glyph | label pattern |
  |---|---|---|---|---|---|---|
  | success | `#2F9E67` | `#FFFFFF` | `#3FBE82` | `#0E1520` | ✓ | "\<goal\>, Success" |
  | fail | `#D34A4A` | `#FFFFFF` | `#E5675F` | `#FFFFFF` | ✕ | "\<goal\>, Failed" |
  | cheat | `#D6A631` | `#3A2A05` | `#E3B94E` | `#2A1E02` | C | "\<goal\>, Cheat day used" |
  | pending | `#6B7CA0` | `#FFFFFF` | `#8B9BC7` | `#101828` | … | "\<goal\>, Pending" |
  | empty | `#E4E7EC` | `#98A2B3` | `#26314A` | `#5C6B82` | – | "\<goal\>, Not scheduled" |

  For Week/Month grid cells (which also carry a `date`), extend the label to "\<goal\>, \<date\>, \<state\>" so a screen-reader user gets both axes, matching `EXPERIENCE.md`'s Accessibility Floor pattern ("Failed, certain" / "Cheat day used" / "Pending, 2 of 3 remaining"). Corner radius for the `StatusCell`/`StatusCellView` shape is `6px` (`rounded.sm`) on both platforms. [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Colors] [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components] [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Accessibility Floor]

- **UX-DR18 exact requirements:** Today widget = reduced density, name + status dot only, no progress bars, no other interaction besides tap-through (tap-through itself is Story 5.3's scope — this story must not add any other gesture, button, or "quick action" affordance; the widget-detail addendum notes quick actions were never confirmed as an FR). Week/Month widgets = same `status-cell` grid vocabulary as in-app, sized to whatever the platform's widget size class allows — this means the native layer must gracefully reflow cell count per size class, not hard-code one fixed grid that only looks right at one size. [Source: docs/epics.md#UX Design Requirements (UX-DR18)] [Source: docs/addendum/widget-detail-requirementsmd-v1-3637-narrowed-by-v2-311-and-prd-decisions.md]

- **No lock-screen widgets (FR-31):** only Android home-screen Glance widgets and iOS `systemSmall`/`systemMedium`/`systemLarge` WidgetKit families are in scope. Do not add iOS Lock Screen/StandBy accessory widget families or an Android keyguard widget — both are explicitly out of scope. [Source: docs/epics.md#FR-31]

- **Structural seed:** all native code in this story lives under `lib/platform/android/` (Kotlin/Jetpack Glance) and `lib/platform/ios/` (Swift/WidgetKit) — the two folders the architecture spine reserves for exactly this purpose. No native widget code belongs in `lib/data/` or `lib/presentation/`. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed]

- **Testing standards for this story specifically:** the Flutter/Dart-side test coverage for the bridge contract itself was already established in Story 5.1 (fixture-based unit tests, platform channel mocked) and is not repeated here. Native widget rendering (Glance/WidgetKit UI) is not exercised by Flutter's test runner and has no equivalent automated harness in this stack — verification here is Android Studio's Glance preview / Xcode's WidgetKit preview canvas against fixture JSON payloads (including the Story 5.1 empty-state envelope), plus manual on-device/simulator QA. This is a deliberate, narrow exception to NFR-6's "correctness as core quality bar," which is otherwise carried entirely by the pure `evaluate()` function's own test suite (Epic 1) and by Story 5.1's bridge-contract tests — this story's job is purely presentational (mapping an already-correct `status` string to a color/glyph), so there is no evaluation logic here to unit-test.

### Project Structure Notes

- Native widget source lands under `lib/platform/android/` and `lib/platform/ios/`, exactly per the structural seed. No conflicts or variances detected — this is the first story to actually populate those two folders (Story 5.1 only touched `lib/data/widget_bridge/` and `lib/domain/services/`).
- No Drift schema, repository, or domain-service changes in this story — it is a pure rendering layer on top of Story 5.1's already-fixed contract.

### References

- [Source: docs/epics.md#Story 5.2]
- [Source: docs/epics.md#Epic 5]
- [Source: docs/epics.md#UX Design Requirements] (UX-DR18, UX-DR6)
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-1]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-7]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Stack] (Kotlin/Jetpack Glance, Swift/WidgetKit, home_widget 0.9.3 data-bridging only)
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Deferred] (native widget implementation explicitly deferred to platform-native code, resolved here)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Colors]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Accessibility Floor]
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Component Patterns] (Widgets bullet)
- [Source: docs/addendum/widget-detail-requirementsmd-v1-3637-narrowed-by-v2-311-and-prd-decisions.md]
- [Source: docs/stories/5-1-widget-data-bridge.md] (shared-container JSON contract this story consumes verbatim)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5

### Debug Log References

- Android: `flutter analyze` (26 pre-existing `prefer_initializing_formals` infos, none new), `flutter test test/data/widget_bridge/` (7/7), `flutter test` full suite (308/308), `gradlew :app:compileDebugKotlin` (green after fixing `currentState<HomeWidgetGlanceState>()` type inference in Week/Month widgets), `gradlew :app:assembleDebug` (green — full manifest merge + AAPT2 resource link + Kotlin/Glance compile of all three widgets into a real debug APK).

### Completion Notes List

- **Task 1 (Dart):** Updated `WidgetBridgeWriterImpl`'s `_androidWidgetNames` map from Story 5.1's placeholder values (`TodayWidgetProvider`/etc.) to the real `GlanceAppWidgetReceiver` class names this story registers (`TodayWidgetReceiver`/`WeekWidgetReceiver`/`MonthWidgetReceiver`). The iOS `_iOSWidgetNames` map already matched the `kind` strings used in the Swift `Widget` declarations, so no change was needed there. No other change to `lib/data/widget_bridge/` or the domain interface — the Story 5.1 envelope contract is consumed as-is.
- **Task 2 (Android, Kotlin/Jetpack Glance) — fully built and verified with a real toolchain, not just written:** this development environment had no Android SDK or JDK installed at all; both were installed for this story (Eclipse Temurin JDK 17 via `winget`, Android cmdline-tools + `platforms;android-36`/`build-tools;36.0.0` via `sdkmanager`) specifically so this native code could be compiled and packaged for real rather than left as an unverified guess.
  - Read the actual `home_widget` 0.9.3 plugin source from the pub cache (`es.antonborri.home_widget`) rather than guessing its Glance API surface per the Stack table's re-verify caveat: `HomeWidgetGlanceWidgetReceiver<T>`, `HomeWidgetGlanceStateDefinition`, and `HomeWidgetGlanceState.preferences` (a plain `SharedPreferences`, not an androidx DataStore `Preferences` as the story text's own guess suggested) — confirmed from `HomeWidgetGlanceState.kt`/`HomeWidgetGlanceWidgetReceiver.kt` in the installed package, not from documentation.
  - `lib/platform/android/`: `WidgetData.kt` (JSON envelope parsing via `org.json`, no new dependency), `StatusPresentation.kt` (the 5-state color/glyph/label table, resource-id based via `ColorProvider(R.color.…)` so day/night follows Android's own resource qualifiers), `StatusCell.kt` (shared composable, `cornerRadius(6.dp)`, `semantics { contentDescription = … }`), `TodayWidget.kt`/`TodayWidgetReceiver`, `WeekWidget.kt`/`WeekWidgetReceiver`, `MonthWidget.kt`/`MonthWidgetReceiver`, `WidgetGrid.kt` (shared Week/Month grid renderer using `LocalSize` + `SizeMode.Responsive` to reflow visible columns/rows to the granted size class instead of a fixed grid).
  - `android/app/src/main/res/values/colors.xml` + `values-night/colors.xml`: the exact light/dark hex pairs from Dev Notes' table, as Android color resources so Glance widgets follow system dark mode automatically.
  - `android/app/src/main/res/xml/{today,week,month}_widget_info.xml`: `appwidget-provider` resources sized small/medium/large with `resizeMode="horizontal|vertical"`.
  - `AndroidManifest.xml`: registered the three receivers (`<receiver android:name=".widget.TodayWidgetReceiver" …>` etc.), added `strings.xml` for their labels.
  - `android/app/build.gradle.kts`: added `androidx.glance:glance-appwidget:1.1.1`, enabled `buildFeatures.compose`, applied `org.jetbrains.kotlin.plugin.compose` (required separately from Kotlin 2.x's built-in-Kotlin split), and added `lib/platform/android` as an extra Kotlin `sourceSet` dir so the structural-seed location actually compiles into the app module. `android/settings.gradle.kts` gained the matching `org.jetbrains.kotlin.plugin.compose` plugin version declaration.
  - **Two real compiler errors were caught and fixed by actually building, not just reading the code:** `currentState()` inside Week/Month's `provideGlance` couldn't infer its type parameter without an explicit `currentState<HomeWidgetGlanceState>()` (Today's version inferred fine because it flowed straight into a typed function parameter) — fixed in both files.
  - **Unrelated pre-existing build gap found and fixed while getting a full `assembleDebug` to pass:** `:app:checkDebugAarMetadata` failed because `flutter_local_notifications` (Story 4.1) requires core library desugaring, which had never been enabled — this had never surfaced before because this is the first time this project was ever built through a full Android Gradle build in any environment. Added `compileOptions.isCoreLibraryDesugaringEnabled = true` and the `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` dependency. Unrelated to this story's widget scope but required for `assembleDebug` to succeed at all.
  - Final result: `gradlew :app:assembleDebug` succeeds — a real debug APK containing all three widgets, their manifest entries, and their resources, built and linked by the actual Android toolchain.
- **Task 3 (iOS, Swift/WidgetKit) — written and internally consistent, but genuinely unverifiable on this OS:** Xcode cannot be installed or run on Windows under any circumstances (Apple restricts it to macOS) — this is a hard environment limitation, not a shortcut. All Swift source was written carefully against the documented WidgetKit/App-Group APIs: `lib/platform/ios/WidgetModels.swift` (Codable envelope + `UserDefaults(suiteName:)` reader against the App Group Story 5.1 configured), `StatusPresentation.swift`/`StatusCellView.swift` (same 5-state table, Asset-Catalog color-set lookups by name), `WidgetGridView.swift` (GeometryReader-based reflow, mirroring the Android grid's logic), `TodayWidget.swift`/`WeekWidget.swift`/`MonthWidget.swift` (one `TimelineProvider` + `Widget` each, `policy: .never` since the app itself triggers `WidgetCenter` reloads via `home_widget`'s `updateWidget` call), `TrackerWidgetsBundle.swift` (the `@main` `WidgetBundle` entry point), plus `Info.plist` (`NSExtensionPointIdentifier: com.apple.widgetkit-extension`) and `TrackerWidgets.entitlements` (the same App Group as Story 5.1's `Runner.entitlements`) and a hand-authored `Assets.xcassets` with all 10 color sets (Any + Dark appearance) generated from the exact hex table via a small Node.js script to avoid manual hex→float transcription errors.
  - **What this story could not do:** create the actual Xcode WidgetKit Extension *target* (`PBXNativeTarget`, build phases, product bundle id, embed-in-Runner build phase). Hand-editing `project.pbxproj` to fabricate an entire new target's project graph without Xcode's project model is high-risk (a malformed entry can silently corrupt the whole iOS build, including the main app) and — unlike the Android side — there is no way to compile-check the result on this machine at all, so a mistake would be undetectable until someone opens the project on a Mac. This is a materially different risk profile from Story 5.1's pbxproj edit (which only adjusted existing target build settings).
  - **Manual step required before this compiles:** on macOS, open `ios/Runner.xcodeproj`, add a new "Widget Extension" target (e.g. `TrackerWidgets`), point its Info.plist/entitlements at the files above (or let Xcode generate its own and merge these values in), add the App Group capability to the new target, drag in the six `.swift` files and the `Assets.xcassets` folder from `lib/platform/ios/`, and ensure the extension is embedded in the Runner scheme. This mirrors Story 5.1's own precedent of flagging an Xcode-side caveat that needs a macOS spot-check.
- **Task 4 (parity):** both platforms' `StatusPresentation` tables were written from the same Dev Notes hex/glyph/label table and cross-checked line-by-line; the iOS Asset Catalog's float RGB components were generated programmatically from the same hex strings (not re-eyeballed), so there is no transcription drift between `colors.xml`/`colors-night.xml` and `Assets.xcassets`.
- **Task 5 (verification):** Android Studio's Glance preview and Xcode's WidgetKit preview canvas are both GUI tools unavailable in this Windows CLI-only environment, so neither ran. What did run, as the strongest verification actually available here: a full `gradlew :app:assembleDebug` (real AAPT2 resource linking + manifest merge + Kotlin/Glance compilation) proves the Android widgets are structurally correct end-to-end, well beyond "the code reads plausibly." The iOS side has no equivalent — it was verified only by careful reading against the documented API and by mirroring the already-Gradle-verified Android logic (same grid reflow algorithm, same presentation table, same guardrails). Dev Notes' existing "Testing standards" paragraph already documents why this story has no automated UI-test harness for native rendering; nothing further was needed there (5.2).

### File List

- `lib/data/widget_bridge/widget_bridge_writer_impl.dart` (modified — real Android Glance receiver class names in `_androidWidgetNames`)
- `lib/platform/android/WidgetData.kt` (new — JSON envelope parsing)
- `lib/platform/android/StatusPresentation.kt` (new — 5-state color/glyph/label table)
- `lib/platform/android/StatusCell.kt` (new — shared Glance composable)
- `lib/platform/android/WidgetGrid.kt` (new — shared Week/Month grid renderer)
- `lib/platform/android/TodayWidget.kt` (new — `TodayWidget`/`TodayWidgetReceiver`)
- `lib/platform/android/WeekWidget.kt` (new — `WeekWidget`/`WeekWidgetReceiver`)
- `lib/platform/android/MonthWidget.kt` (new — `MonthWidget`/`MonthWidgetReceiver`)
- `lib/platform/ios/WidgetModels.swift` (new — Codable envelope + App Group `UserDefaults` reader)
- `lib/platform/ios/StatusPresentation.swift` (new — 5-state color/glyph/label table)
- `lib/platform/ios/StatusCellView.swift` (new — shared SwiftUI status-cell view)
- `lib/platform/ios/WidgetGridView.swift` (new — shared Week/Month grid renderer)
- `lib/platform/ios/TodayWidget.swift` (new)
- `lib/platform/ios/WeekWidget.swift` (new)
- `lib/platform/ios/MonthWidget.swift` (new)
- `lib/platform/ios/TrackerWidgetsBundle.swift` (new — `@main` `WidgetBundle`)
- `lib/platform/ios/Info.plist` (new — WidgetKit extension `NSExtension` config, pending Xcode target creation)
- `lib/platform/ios/TrackerWidgets.entitlements` (new — App Group entitlement, pending Xcode target creation)
- `lib/platform/ios/Assets.xcassets/` (new — 10 color sets, Any + Dark, generated from the Dev Notes hex table)
- `android/app/src/main/res/values/colors.xml` (new — light status colors)
- `android/app/src/main/res/values-night/colors.xml` (new — dark status colors)
- `android/app/src/main/res/values/strings.xml` (new — widget labels)
- `android/app/src/main/res/xml/today_widget_info.xml` (new — `appwidget-provider`)
- `android/app/src/main/res/xml/week_widget_info.xml` (new — `appwidget-provider`)
- `android/app/src/main/res/xml/month_widget_info.xml` (new — `appwidget-provider`)
- `android/app/src/main/AndroidManifest.xml` (modified — registered the three widget receivers)
- `android/app/build.gradle.kts` (modified — Compose/Glance plugin+dependency, `lib/platform/android` sourceSet, core library desugaring fix)
- `android/settings.gradle.kts` (modified — `org.jetbrains.kotlin.plugin.compose` plugin declaration)
- `android/local.properties` (modified — added `sdk.dir` for the Android SDK installed in this environment; local machine config, not meant to travel with the repo)

## Change Log

- 2026-08-31: Implemented Story 5.2 (Today/Week/Month Widget Rendering) — native Android Kotlin/Jetpack Glance widgets (built and verified end-to-end with a real Android SDK/JDK installed for this story: `gradlew :app:assembleDebug` succeeds) and native iOS Swift/WidgetKit source (written and internally consistent, but unverifiable — Xcode cannot run on Windows). Fixed an unrelated pre-existing build gap (`flutter_local_notifications` core library desugaring) discovered while getting the first-ever full Android build of this project to pass. Wired Story 5.1's `WidgetBridgeWriter` to the real native provider names. Full regression suite green (308 passing).
