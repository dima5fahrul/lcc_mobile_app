// AC-25: must precede plugins {}. Inside the android { } block the identifier `java`
// binds to Gradle's JavaPluginExtension accessor, not the java.* package, so the
// fully-qualified `java.util.Properties()` does not resolve there. Import it instead.
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.lcc_mobile_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.lcc_mobile_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // --- AC-25: release signing scaffold (architecture-review §IV.1 / ADR-0002 §2) ---
    // An agent MUST NOT generate or commit a keystore. The USER generates, holds, and backs
    // up the signing key. This block reads android/key.properties IF it exists; if it does
    // not, the release signingConfig is left unconfigured and assembleRelease fails loudly
    // (see the guard below). NEVER fall back to the debug signing key for release.
    // NOTE: for a Flutter app, settings.gradle.kts lives in android/, so Gradle's
    // rootProject dir IS android/ — the path here is "key.properties", NOT
    // "android/key.properties" (that would resolve to android/android/key.properties
    // and make the guard below throw even when a valid keystore is configured).
    val keyPropertiesFile = rootProject.file("key.properties")
    if (keyPropertiesFile.exists()) {
        val keyProperties = Properties()
        keyPropertiesFile.inputStream().use { keyProperties.load(it) }
        signingConfigs.create("release") {
            keyAlias = keyProperties.getProperty("keyAlias")
            keyPassword = keyProperties.getProperty("keyPassword")
            storeFile = file(keyProperties.getProperty("storeFile"))
            storePassword = keyProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            // Resolves to the config created above from android/key.properties, or null
            // when no keystore is configured — in which case the guard below aborts the
            // build. The Flutter template's "sign with debug keys for now" default is
            // deliberately NOT used here (AC-25 / V-1).
            signingConfig = signingConfigs.findByName("release")
            // Fail loudly if assembleRelease runs without a user-provided keystore.
            // AC-25 / V-1: NEVER silently fall back to the debug signing key — the debug
            // key is published with the SDK; a same-signature APK inherits the app's data
            // directory and KeyStore-backed secure storage (where citizen tokens live).
            tasks.matching { it.name == "assembleRelease" }.configureEach {
                doFirst {
                    if (signingConfigs.findByName("release") == null) {
                        throw GradleException(
                            "AC-25: Release signing keystore not found. " +
                                "Create android/key.properties (see android/key.properties.example) " +
                                "and generate a keystore via keytool. " +
                                "Refusing to build a release APK signed with the debug key."
                        )
                    }
                }
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
