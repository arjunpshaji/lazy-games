plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.devzilla.lazygames"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.devzilla.lazygames"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // Real Android phones are arm64-v8a (modern) or armeabi-v7a (older 32-bit).
            // x86/x86_64 are only used by emulators and Chromebooks, and account for
            // ~29MB of duplicated native libraries in the fat APK. Excluding them in
            // release shrinks the build without affecting any real device.
            // Skipped when `--split-per-abi` is used, since that sets its own ABI splits.
            if (project.findProperty("split-per-abi") != "true") {
                ndk {
                    abiFilters.clear()
                    abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a"))
                }
            }
        }
    }
}

flutter {
    source = "../.."
}
