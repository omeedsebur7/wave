plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.firebase-perf")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // TODO: replace with your real, registered application id before any
    // release build. "com.example.wave" is the Flutter template default and
    // is not eligible for Play Store upload regardless of flavors.
    namespace = "com.example.wave"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
    resValues = true
}

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.wave"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ── Flavors ────────────────────────────────────────────────────────────
    //
    // Without this block Gradle has exactly one build variant, so `--flavor
    // dev` / `--flavor staging` / `--flavor prod` on the command line had
    // nothing to select — every `flutter run -t lib/main_*.dart` silently
    // built against whichever single google-services.json Gradle found (the
    // one at android/app/google-services.json, project wave-dev-bb9da),
    // regardless of which Dart entry point was requested. A `--flavor prod`
    // typo or omission would not have failed the build; it would have quietly
    // built the dev-configured APK and shipped it as if it were production.
    //
    // Flavor NAMES must match android/app/src/<name>/ exactly — that is how
    // Gradle finds each flavor's google-services.json — and must match
    // Flavor.<x>.id in lib/core/config/flavor.dart, since that is the string
    // `flutter run --flavor <name>` is compared against on the command line.
    // The two are independent files with no compiler link between them; only
    // running each flavor once and confirming it initializes the right
    // Firebase project actually proves they agree.
    flavorDimensions += "env"

    productFlavors {
        create("dev") {
            dimension = "env"
            // .dev suffix lets dev, staging, and prod be installed side by
            // side on one device for testing — without it, installing one
            // flavor overwrites another sharing the same applicationId.
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "WAVE Dev")
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "WAVE Staging")
        }
        create("prod") {
            dimension = "env"
            // No suffix: this is the identity that ships to the Play Store,
            // and that applicationId cannot change after the first release.
            resValue("string", "app_name", "WAVE")
        }
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