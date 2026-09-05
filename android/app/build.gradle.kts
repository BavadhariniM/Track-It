plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.panda.tracker.tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    buildFeatures {
        compose = true
    }

    // Story 5.2: Kotlin/Jetpack Glance widget UI lives under lib/platform/android/
    // per the architecture spine's structural seed, not under the conventional
    // android/app/src/main/kotlin tree — wire it in as an extra Kotlin source dir.
    sourceSets {
        getByName("main") {
            kotlin.srcDir("../../lib/platform/android")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.panda.tracker.tracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Story 5.2: Today/Week/Month home-screen widgets (Kotlin/Jetpack Glance).
    implementation("androidx.glance:glance-appwidget:1.1.1")
    // Required by flutter_local_notifications (Story 4.1); surfaced as a
    // hard AAR-metadata build failure the first time this project was ever
    // run through a full `assembleDebug` in this environment — unrelated to
    // this story's widget code but needed for the app to build at all.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
