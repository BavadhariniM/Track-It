---
name: 'Tech Currency Review — Goal Tracker Architecture Spine'
type: review
reviews: '../ARCHITECTURE-SPINE.md'
created: '2026-08-17'
---

# Tech Currency Review — Stack Table

Method: WebSearch + WebFetch against pub.dev, riverpod.dev, docs.flutter.dev, and GitHub, run 2026-08-17. Each Stack row checked for (a) still exists, (b) actively maintained, (c) fit for the stated use case, (d) any greenfield-relevant default behavior confirmed live rather than from training data.

## 1. Flutter / Dart — OK, appropriately hedged

The spine deliberately doesn't pin a version ("pin exact version via `flutter --version` at project init"). Good call — live checks of docs.flutter.dev returned **internally inconsistent** version signals: the release-notes page header claims "Flutter 3.47.0" while the same page's footer says content "reflects Flutter 3.44.7," and a separate search surfaced 3.44.0 (dated May 2026). This churn is exactly why the spine is right not to hard-code a number. **No fix needed**, but flagging the inconsistency so whoever runs `flutter --version` at init isn't surprised if `flutter --version` and docs disagree.

Source: [Flutter release notes](https://docs.flutter.dev/release/release-notes), [Flutter 3.41 blog](https://blog.flutter.dev/whats-new-in-flutter-3-41-302ec140e632)

## 2. flutter_riverpod + riverpod_generator — PARTIALLY WRONG, needs correction

`flutter_riverpod` is genuinely on the 3.x line (latest **3.4.2**, published ~19 days before the check) — that part of the claim holds up.

**However, `riverpod_generator` is NOT on the 3.x line — it's on 4.x (latest 4.0.8), and has been since a stable "4.0.0" release.** The official riverpod.dev "Getting Started" guide itself pairs these as:
- `flutter_riverpod: ^3.4.2`
- `riverpod_annotation: ^4.0.6`
- `riverpod_generator: ^4.0.8`

The generator/annotation packages appear to version independently from the runtime package now (their changelog frames 3.0.0 as "stable for Riverpod 3.0" and 4.0.0 as tracking "Riverpod 4.0," yet `flutter_riverpod` core itself hasn't moved past 3.4.2) — this looks like a tooling-version-vs-runtime-version split that a from-training-data assumption would miss entirely, since historically these tracked together.

**Fix recommended:** change the Stack row to something like "flutter_riverpod 3.x + riverpod_generator/riverpod_annotation 4.x (current official pairing per riverpod.dev, versioned independently — not a mismatch)." As written, "3.x line" for both packages together is factually wrong for the generator.

Source: [riverpod.dev Getting Started](https://riverpod.dev/docs/introduction/getting_started), [riverpod_generator changelog](https://pub.dev/packages/riverpod_generator/changelog), [flutter_riverpod versions](https://pub.dev/packages/flutter_riverpod/versions)

## 3. drift + drift_flutter — CONFIRMED ACCURATE

Verified: starting at drift 2.32.0 (depending on sqlite3 package 3.x), `drift_flutter` bundles `sqlite3_flutter_libs` internally so the app author does no native setup on Android/iOS/macOS/Linux/Windows — matches the spine's claim exactly. One caveat not in the spine: **web** support still requires manually downloading WASM/worker files into `web/` — irrelevant here since this app is mobile-only (Android/iOS), but worth knowing if that scope ever expands.

Source: [drift_flutter changelog](https://pub.dev/packages/drift_flutter/changelog), [Drift setup docs](https://drift.simonbinder.eu/setup/), [drift issue #3710](https://github.com/simolus3/drift/issues/3710)

## 4. flutter_local_notifications — CONFIRMED ACCURATE

Latest stable is 21.0.0, actively published (a 22.0.0-dev prerelease exists), maintained by dexterx.dev. No deprecation notices for the package as a whole. Fit for the spine's stated single-global-reminder-time use case.

Source: [flutter_local_notifications on pub.dev](https://pub.dev/packages/flutter_local_notifications), [changelog](https://pub.dev/packages/flutter_local_notifications/changelog)

## 5. home_widget — MOSTLY CONFIRMED, one claim is unverifiable from the package itself

- **Actively maintained: confirmed.** 2.2k likes, 160 pub points, 149k downloads, verified-publisher badge, latest release 0.9.3 published ~2 months before the check.
- **"Does not let widget UI be written in Flutter — native code required": confirmed**, matches the spine's Deferred section exactly. The package bridges data (via UserDefaults on iOS / SharedPreferences on Android) and triggers widget refresh; native Kotlin/Glance or Swift/WidgetKit still owns rendering.
- **Three-widget (Today/Week/Month) use case: NOT explicitly documented by home_widget itself, and this is a genuine gap.** The package's own README/docs don't state "supports N distinct widget types per app" as a feature — that capability comes from the underlying Android `AppWidgetProvider`/Glance and iOS `WidgetKit` platform APIs (which do support multiple widget definitions per app; this is standard, well-established native platform behavior), with home_widget only providing one shared key/value data container both native widgets read from. **This is architecturally sound** (the spine's own Deferred section already assigns native widget registration to platform code, not to home_widget), but the spine's Stack-table phrasing implies home_widget itself was checked against the three-widget use case, when what was actually verified is (a) home_widget is maintained and bridges data, and (b) native platforms independently support multiple widget types. Recommend rewording the Stack row to make that distinction explicit rather than implying home_widget was checked for multi-widget support specifically.

Source: [home_widget on pub.dev](https://pub.dev/packages/home_widget), [home_widget GitHub](https://github.com/ABausG/home_widget)

## Summary Table

| Stack item | Verdict | Action |
| --- | --- | --- |
| Flutter/Dart | OK (correctly unpinned) | None |
| flutter_riverpod | OK, confirmed 3.x | None |
| riverpod_generator | **Wrong** — actually 4.x, not 3.x | Reword Stack row |
| drift + drift_flutter | OK, confirmed | None |
| flutter_local_notifications | OK, confirmed | None |
| home_widget maintenance | OK, confirmed | None |
| home_widget 3-widget claim | Unverified against package itself (relies on native platform capability, not home_widget) | Reword Stack row for precision |
