import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing lives outside the repository: `android/key.properties` points
// at a keystore in the user profile and is gitignored. Without it the build
// falls back to the debug key so `flutter run --release` still works.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.avalon.companion"
    compileSdk = flutter.compileSdkVersion
    // Pinned to the NDK Flutter 3.50 asks for, so the release build strips the
    // unstripped engine with that NDK's llvm-strip instead of shipping ~160 MB
    // of symbols per ABI. Pinning also stops Gradle from silently installing a
    // different NDK mid-build.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.avalon.companion"
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

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        // A debug build shares the release identity when the keystore is on the
        // machine, so `flutter test integration_test -d …` installs over the
        // release-signed app instead of failing with a signature mismatch. The
        // test harness still uninstalls the app when the run ends, which takes
        // the saved matches with it; without key.properties debug keeps the
        // debug key.
        debug {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // No keystore on this machine: sign with the debug key so the
                // release build still installs and can be tested.
                signingConfigs.getByName("debug")
            }
        }
    }

    packaging {
        jniLibs {
            // AGP strips Flutter's engine libraries with the pinned NDK's
            // llvm-strip. On a machine where that NDK is not fully installed the
            // strip task cannot even start, which fails the whole build. Setting
            // AVALON_KEEP_SYMBOLS=1 skips stripping instead: the APK grows by
            // ~160 MB per ABI and is only suitable for local testing.
            if (System.getenv("AVALON_KEEP_SYMBOLS") == "1") {
                keepDebugSymbols += "**/*.so"
            }
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
