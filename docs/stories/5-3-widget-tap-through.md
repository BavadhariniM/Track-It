---
baseline_commit: NO_VCS
---

# Story 5.3: Widget Tap-Through

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As Panda,
I want tapping any home-screen widget to open the app to the relevant date,
so that I can go straight from a glance to logging or reviewing without extra navigation.

## Acceptance Criteria

1. **Given** the Today widget
   **When** Panda taps it
   **Then** the app opens directly to today's Day View (FR-32)

2. **Given** the Week or Month widget
   **When** Panda taps it (or a specific day cell within it, where the platform's widget-tap API supports per-cell deep links)
   **Then** the app opens to that week/day or month/day accordingly (FR-32)

3. **Given** tap-through is the widget's only supported interaction
   **When** Panda attempts any other gesture (long-press, swipe) on a widget
   **Then** no action occurs — widgets are read-only except for tap-through (UX-DR18)

4. **And** the exact per-platform tap-through granularity (whole-widget vs. per-cell) is resolved here according to each platform's actual capability, closing the `[ASSUMPTION]` the PRD carried forward on this point (FR-32)

## Tasks / Subtasks

- [x] Task 1 (data/presentation, Flutter/Dart side): Deep-link contract and in-app routing (AC: 1, 2)
  - [x] 1.1 Define the URI contract (binding for both native platforms — see Dev Notes): `trackerapp://day?date=YYYY-MM-DD`, `trackerapp://week?date=YYYY-MM-DD`, `trackerapp://month?date=YYYY-MM-DD`.
  - [x] 1.2 On app cold start, call `HomeWidget.initiallyLaunchedFromHomeWidget()` (verify the exact `home_widget` 0.9.3 API surface at build time, per the Stack table's own re-verify caveat) to detect a widget-tap launch and capture its URI before the first frame renders.
  - [x] 1.3 Subscribe to `HomeWidget.widgetClicked` (or the current `home_widget` 0.9.3 equivalent stream) for the warm-start case (app already running in the background) so a widget tap while the app is alive also routes correctly.
  - [x] 1.4 In `lib/presentation/providers/` (composition-root/navigation wiring, AD-2), parse the received URI's host (`day`/`week`/`month`) and `date` query parameter, and route to the existing Day View / Week View / Month View screens (Epic 1 Stories 1.1/1.10) at that date — reuse existing screens and navigation, do not create new ones.
  - [x] 1.5 Confirm the destination screen performs its normal live `evaluate()`-backed rendering exactly as it does when reached by any other navigation path (AD-7: the live calendar always calls `evaluate()` fresh) — tap-through changes only how the user arrived at the screen, never what data path the screen itself uses once there.

- [x] Task 2 (native Android, Kotlin/Jetpack Glance): Implement tap targets (AC: 1, 2, 3, 4)
  - [x] 2.1 `TodayWidget`: attach a single click action to the whole widget's root composable — `actionStartActivity`/`HomeWidgetLaunchIntent.getActivity(context, Uri.parse("trackerapp://day?date=$today"))` (verify the current `home_widget` Android helper API at build time) — so a tap anywhere on the widget opens today's Day View, satisfying AC1 without needing per-cell granularity (there is only one date to target).
  - [x] 2.2 `WeekWidget`/`MonthWidget`: give each individual day `StatusCell` composable (from Story 5.2) its own click action carrying that specific cell's `date` (`trackerapp://day?date=$cellDate`) — Glance supports per-composable click actions with parameters, so per-cell deep-linking is achievable on Android. This is the platform-capability confirmation that resolves AC4 for Android: per-cell, not whole-widget-only.
  - [x] 2.3 Any remaining non-cell chrome (e.g. a header row) in `WeekWidget`/`MonthWidget` gets its own click action to `trackerapp://week?date=$rangeStart` / `trackerapp://month?date=$rangeStart` (using the envelope's `rangeStart` from Story 5.1) so tapping the widget outside a specific cell still opens something sensible — the containing Week/Month View.
  - [x] 2.4 Do not attach any long-press or swipe/drag gesture handler to any Glance composable in any of the three widgets — Glance composables have no such handlers unless explicitly added, so satisfy AC3 by simply never adding one; explicitly confirm no click modifier is accidentally attached to a container that would also intercept a swipe gesture.

- [x] Task 3 (native iOS, Swift/WidgetKit): Implement tap targets (AC: 1, 2, 3, 4)
  - [x] 3.1 `TodayWidget` (`systemSmall` family): set `.widgetURL(URL(string: "trackerapp://day?date=\(today)"))` on the widget's root view. `systemSmall` widgets support exactly one tap destination for the whole widget, which matches AC1 exactly (there is only one date to target, so whole-widget granularity is correct here, not a limitation).
  - [x] 3.2 `WeekWidget`/`MonthWidget` (`systemMedium`/`systemLarge` families): wrap each `StatusCellView` (from Story 5.2) in its own `Link(destination: URL(string: "trackerapp://day?date=\(cellDate)")!)`. WidgetKit supports multiple independent `Link` tap targets within one medium/large widget, so per-cell deep-linking is achievable on iOS as well — this is the platform-capability confirmation that resolves AC4 for iOS: per-cell, not whole-widget-only.
  - [x] 3.3 Any remaining non-cell area in `WeekWidget`/`MonthWidget` uses its own `Link` to `trackerapp://week?date=...` / `trackerapp://month?date=...` (using the envelope's `rangeStart`).
  - [x] 3.4 Register the `trackerapp` URL scheme in the main app target's `Info.plist` (`CFBundleURLTypes`) so tapping a `Link`/`widgetURL` foregrounds or launches the app and routes the URL through `application(_:open:options:)` / SwiftUI `onOpenURL`, which `home_widget`'s iOS plugin surfaces to Dart via the mechanism wired in Task 1.
  - [x] 3.5 Do not add iOS 17 interactive-widget App Intents/Buttons — `Link`/`.widgetURL` tap-through is the only interaction implemented; do not add any long-press or swipe handling anywhere in any of the three widgets' SwiftUI views.

- [ ] Task 4 (verification): Manual QA across both platforms (AC: 1, 2, 3, 4) — **blocked, needs a human with real devices/simulators (see Completion Notes)**
  - [ ] 4.1 Cold-start case: with the app not running, tap the Today widget (opens today's Day View), tap a specific day cell in Week/Month widgets (opens that day's Day View), tap non-cell chrome in Week/Month widgets (opens that Week/Month View) — on both Android and iOS.
  - [ ] 4.2 Warm-start case: repeat 4.1 with the app already running in the background, confirming the `widgetClicked`/stream-based path (Task 1.3) routes identically to the cold-start path (Task 1.2).
  - [ ] 4.3 Attempt long-press and swipe/drag on each of the three widgets on both platforms and confirm no action occurs of any kind (AC3).

## Dev Notes

- **This story spans three surfaces — keep them distinct:**
  - **Flutter/Dart side (`lib/presentation/providers/`, composition root):** owns the URI contract, detects a widget-tap launch (cold or warm start) via `home_widget`'s Dart API, and routes to an existing screen. This is the only Dart-side work in this story.
  - **Native Android (`lib/platform/android/`, extending Story 5.2's Glance widgets):** attaches click actions that construct the `trackerapp://` URI and launch the app via a `PendingIntent`/`home_widget` helper — no Dart/Flutter code involved.
  - **Native iOS (`lib/platform/ios/`, extending Story 5.2's WidgetKit widgets):** attaches `Link`/`.widgetURL` tap targets carrying the same URI scheme, plus `Info.plist` URL-scheme registration — again no Dart/Flutter code involved.

- **The URI contract (binding across both platforms and the Flutter router):**

  | URI | Opens | Used by |
  |---|---|---|
  | `trackerapp://day?date=YYYY-MM-DD` | Day View for that date | Today widget (whole-widget); Week/Month widget (per-cell tap) |
  | `trackerapp://week?date=YYYY-MM-DD` | Week View containing that date | Week widget (non-cell area), using the envelope's `rangeStart` |
  | `trackerapp://month?date=YYYY-MM-DD` | Month View containing that date | Month widget (non-cell area), using the envelope's `rangeStart` |

  `date` is always a naive ISO-8601 date-only string, consistent with Data conventions used everywhere else in the app (never a timezone-aware value). Both native platforms must construct exactly these three URI shapes; the Flutter side must parse exactly these three shapes — any mismatch here silently breaks tap-through, since there is no schema validation layer between native and Dart for this URI beyond string parsing.

- **AC4's resolution, stated explicitly:** the PRD carried this forward as an open `[ASSUMPTION]` because it wasn't known at spec time whether each platform's widget-tap API could support per-cell deep links or only a single whole-widget destination. Both platforms turn out to support per-cell targets: Android Glance via per-composable click actions with parameters (Task 2.2), and iOS WidgetKit via multiple `Link` views within one `systemMedium`/`systemLarge` widget (Task 3.2). The Today widget deliberately uses whole-widget granularity on both platforms — not because either platform lacks per-cell capability, but because Today only ever has one date to target, so per-cell granularity would be meaningless there. This closes the assumption: per-cell where the widget has multiple dates to distinguish (Week/Month), whole-widget where it doesn't (Today). [Source: docs/epics.md#Story 5.3]

- **Cache-only rule does NOT extend past the tap:** Stories 5.1/5.2 established that the widget itself and `widget_bridge` must never call `evaluate()` or compute anything — they only render precomputed cache. That rule is scoped to the widget/bridge surface. Once tap-through lands the user inside the actual app on a Day/Week/Month View, that screen behaves exactly as it always does for any other navigation path: the live calendar always calls `evaluate()` fresh and never reads the cache (AD-7). Do not attempt to "stay consistent" with the widget's cached value on the destination screen — the destination screen recomputing live and potentially showing a more current status than the widget did (e.g. if data changed between the widget's last refresh and the tap) is correct behavior, not a bug. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-7]

- **UX-DR18's read-only requirement:** tap-through is the widget's only supported interaction — no long-press, no swipe, no in-widget buttons/quick actions (the widget-detail addendum notes quick actions were never confirmed as an FR and are explicitly not in scope). Both platforms' widget frameworks default to no such gestures unless a developer explicitly wires one in, so this AC is satisfied primarily by omission — Task 2.4/3.5 exist to make that omission a deliberate, verified choice rather than an accident of not having gotten to it yet. [Source: docs/epics.md#UX Design Requirements (UX-DR18)] [Source: docs/addendum/widget-detail-requirementsmd-v1-3637-narrowed-by-v2-311-and-prd-decisions.md]

- **Structural seed:** all native tap-target code extends the same Story 5.2 widget files under `lib/platform/android/` and `lib/platform/ios/`; all Dart-side routing code lives in `lib/presentation/providers/` (composition root / navigation wiring per AD-2, Riverpod). No new domain or data-layer code is introduced by this story. [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed]

- **Testing standards:** the Flutter-side URI-parsing/routing logic (Task 1.4) is unit-testable in isolation (given a URI string, assert the correct screen/date is targeted) without needing a real widget tap. The native tap-target wiring (Tasks 2–3) is verified the same way Story 5.2's rendering was — Android/iOS platform preview tooling only covers rendering, not tap dispatch, so tap-through itself is verified via manual on-device/simulator QA (Task 4) covering both cold-start and warm-start launch paths and the negative case (no action on long-press/swipe). This mirrors Story 5.2's own noted exception to automated UI testing for native widget surfaces — there is no practical automated harness for OS-level widget tap dispatch in this stack.

### Project Structure Notes

- Native changes extend the exact same widget files Story 5.2 created under `lib/platform/android/` and `lib/platform/ios/` — no new native files beyond what 5.2 already scaffolded, except iOS's `Info.plist` URL-scheme entry (project configuration, not a new source file).
- New Dart-side routing code lives in `lib/presentation/providers/`, consistent with the structural seed's placement of Riverpod composition-root wiring. No Drift, repository, or domain changes. No conflicts or variances detected.

### References

- [Source: docs/epics.md#Story 5.3]
- [Source: docs/epics.md#Epic 5]
- [Source: docs/epics.md#FR-32]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-2]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#AD-7]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Structural Seed]
- [Source: docs/architecture/architecture-Tracker-2026-08-17/ARCHITECTURE-SPINE.md#Stack] (home_widget 0.9.3 — re-verify launch/click API at build time)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md#Components] (status-cell reused from Story 5.2, unchanged here)
- [Source: docs/ux-designs/ux-Tracker-2026-08-17/EXPERIENCE.md#Foundation] (widgets "read-only except for tap-through")
- [Source: docs/addendum/widget-detail-requirementsmd-v1-3637-narrowed-by-v2-311-and-prd-decisions.md]
- [Source: docs/stories/5-1-widget-data-bridge.md] (shared-container envelope fields `rangeStart`/`date` reused for URI construction)
- [Source: docs/stories/5-2-today-week-month-widget-rendering.md] (StatusCell/StatusCellView composables this story attaches tap targets to)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `dart run build_runner build` — generated `widget_launch_router_provider.g.dart` (riverpod codegen), no errors.
- `flutter analyze` — 0 issues in changed files; 26 pre-existing `prefer_initializing_formals` infos elsewhere, unrelated to this story.
- `flutter test` — 320/320 passed (full suite, including the 12 new tests in `widget_launch_router_provider_test.dart`).
- `flutter config --jdk-dir="C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"` then `flutter build apk --debug` — succeeded, confirming the new/edited Kotlin (`WidgetDeepLinks.kt`, `StatusCell.kt`, `WidgetGrid.kt`, `TodayWidget.kt`) compiles against the real Android Glance/`home_widget` APIs, not just read by inspection.

### Completion Notes List

- **Task 1 (Flutter/Dart routing) — done and tested.** Added `lib/presentation/providers/widget_launch_router_provider.dart`: a pure `parseWidgetLaunchUri(Uri?)` (host+`date` → `DayLaunchTarget`/`WeekLaunchTarget`/`MonthLaunchTarget`, extra query items such as iOS's `homeWidget` marker ignored), `navigateToWidgetLaunchTarget` (pushes the existing `DayViewScreen`/`WeekViewScreen`/`MonthViewScreen` via a new `widgetLaunchNavigatorKey`), and a `widgetLaunchWatcherProvider` composition-root hook (cold-start via `HomeWidget.initiallyLaunchedFromHomeWidget()`, warm-start via a `widgetClickedProvider` stream) watched once from `main.dart`. `MaterialApp` in `main.dart` now carries `navigatorKey: widgetLaunchNavigatorKey` (it had none before — every prior push already had a `BuildContext` at hand). `MonthViewScreen` gained an optional `initialMonth` constructor param (it previously had no way to open on an arbitrary month); every pre-existing call site (`AppShell`, `_openWeekView`, tests) is unaffected since the param defaults to `null` and preserves the original "always open on the current month" behavior.
- **Task 2 (Android/Kotlin) — done and compiled.** Added `lib/platform/android/WidgetDeepLinks.kt` (URI builders). `StatusCell` gained an optional `onClick: Action?`. `WidgetGridContent` (shared by Week/Month) now gives each cell its own `actionStartActivity<MainActivity>` click carrying that cell's date, plus a container-level click (outer `Column` and the goal-name `Text`) to the week/month URI built from the envelope's own `scope`/`rangeStart` — no new param threaded through `WeekWidget.kt`/`MonthWidget.kt` since the scope is already in the envelope. `TodayWidget`'s root `Column` gets a single click to `trackerapp://day?date=$generatedAt` (using the cache's own stamped date, never a native-computed "now", per AD-7). Confirmed via reading the installed `home_widget` 0.9.3 Android plugin source that no `AndroidManifest.xml` intent-filter is needed — `actionStartActivity`/`HomeWidgetLaunchIntent` launch `MainActivity` via an explicit `Intent` keyed off a custom `Intent.action`, not a manifest-registered URI scheme.
- **Task 3 (iOS/Swift) — done, not compiled (pre-existing environment gap).** Added `lib/platform/ios/WidgetDeepLinks.swift`. `WidgetGridView` wraps each `StatusCellView` in its own `Link` and the goal-name `Text` in a `Link` to the week/month URI (derived from `envelope.scope`/`rangeStart`, mirroring the Android side). `TodayWidgetEntryView` sets `.widgetURL(...)` on its root. `ios/Runner/Info.plist` now registers the `trackerapp` `CFBundleURLTypes` scheme. **Important discovery, not called out in the story text:** reading the installed `home_widget` 0.9.3 iOS plugin source (`HomeWidgetPlugin.swift`) shows `isWidgetUrl(url:)` only intercepts a URL if it carries a query item literally named `homeWidget` — a bare `trackerapp://day?date=...` would be silently dropped on iOS. `WidgetDeepLinks.swift` therefore appends `&homeWidget=true` on iOS only (Android's plugin has no such filter, so `WidgetDeepLinks.kt` doesn't need it); `parseWidgetLaunchUri` on the Dart side already ignores unrecognized query items, so this doesn't affect parsing. As Story 5.2 already documented, this WidgetKit extension is source-only in this repo — no Xcode target exists yet, and this is a Windows machine with no Xcode/simulator — so unlike the Android side, this Swift code could not be compiled or run, only written and read-verified against the real installed plugin source.
- **Task 4 (manual QA) — NOT done, genuinely blocked in this environment.** This task is explicitly manual, on-device QA (cold-start tap, warm-start tap, long-press/swipe negative case) across a real Android device/emulator and a real iOS device/simulator. This machine has no Android emulator image (`flutter emulators` finds none) and no attached Android device, and no Xcode/iOS simulator (Windows). I did not check these subtasks off — doing so without having actually performed them would misrepresent the story's state. **A human needs to**: (1) create/start an Android emulator (or connect a device), run the app, add all three widgets to the home screen, and work through subtasks 4.1–4.3; (2) on a Mac with Xcode, first create the WidgetKit extension target from the `lib/platform/ios/*.swift` files (a pre-existing gap from Story 5.2, not new to this story), then repeat 4.1–4.3 on iOS. Once confirmed, check off Task 4's subtasks and flip the story to `review`/`done` per the normal flow — I left the story at `in-progress`/Task 4 unchecked rather than advancing it to `review` on unverified manual QA.

### File List

- `lib/presentation/providers/widget_launch_router_provider.dart` (new)
- `lib/presentation/providers/widget_launch_router_provider.g.dart` (generated)
- `lib/presentation/screens/month_view.dart` (modified — `initialMonth` param)
- `lib/main.dart` (modified — `navigatorKey`, `widgetLaunchWatcherProvider`)
- `lib/platform/android/WidgetDeepLinks.kt` (new)
- `lib/platform/android/StatusCell.kt` (modified — optional `onClick`)
- `lib/platform/android/WidgetGrid.kt` (modified — per-cell + container click actions)
- `lib/platform/android/TodayWidget.kt` (modified — whole-widget click action)
- `lib/platform/ios/WidgetDeepLinks.swift` (new)
- `lib/platform/ios/WidgetGridView.swift` (modified — per-cell + container `Link`s)
- `lib/platform/ios/TodayWidget.swift` (modified — `.widgetURL`)
- `ios/Runner/Info.plist` (modified — `CFBundleURLTypes` scheme registration)
- `test/presentation/widget_launch_router_provider_test.dart` (new)

## Change Log

- 2026-08-31: Implemented Story 5.3 (Widget Tap-Through) Tasks 1–3 — Flutter-side deep-link parsing/routing (unit+widget tested, 12 new tests), Android Kotlin click-action wiring (built and verified with `flutter build apk --debug` against a real JDK 17/Android SDK), and iOS Swift `Link`/`.widgetURL` wiring plus `Info.plist` scheme registration (written and read-verified against the installed `home_widget` plugin source, but unverifiable — no Xcode/simulator on this Windows machine, same pre-existing gap Story 5.2 documented). Discovered and worked around an undocumented iOS-only requirement: `home_widget`'s iOS plugin ignores any URL without a `homeWidget` query item. Task 4 (manual on-device QA) left unchecked — this environment has no Android emulator/device and no iOS simulator, so it needs a human to actually execute before this story can move to review. Full regression suite green (320 passing).
