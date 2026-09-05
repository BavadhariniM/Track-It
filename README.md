# Track-It

A Flutter habit-tracking app.

## Getting Started

Requires the Flutter SDK matching `^3.13.2` (see `environment.sdk` in `pubspec.yaml`).

1. Install dependencies:

   ```
   flutter pub get
   ```

2. Generate code (Drift database and Riverpod providers). This project uses
   `build_runner` to generate `*.g.dart` files, which are not committed to
   version control:

   ```
   dart run build_runner build --delete-conflicting-outputs
   ```

3. Run the app on a connected device or emulator:

   ```
   flutter run
   ```

## Building for Android

```
flutter build apk --release
```

The output APK is written to `build/app/outputs/flutter-apk/app-release.apk`.
For an installable app bundle (e.g. for Play Store), use `flutter build appbundle --release` instead.

## Building for iOS

Requires a Mac with Xcode and CocoaPods installed.

```
flutter build ios --release
```

Opening `ios/Runner.xcworkspace` in Xcode is required at least once to set a
development team for code signing before the build will run on a physical
device.

For more general Flutter guidance, see the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
