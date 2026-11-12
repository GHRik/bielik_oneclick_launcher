import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val e2eBuild = (project.findProperty("dart-defines") as? String)
    ?.split(",")
    ?.any { String(Base64.getDecoder().decode(it)) == "BIELIK_E2E=true" }
    ?: false

val apkUpdates = (project.findProperty("dart-defines") as? String)
    ?.split(",")
    ?.any { String(Base64.getDecoder().decode(it)) == "BIELIK_APK_UPDATES=true" }
    ?: false

// ABIs requested with `flutter build --target-platform` (or chosen by `flutter run`).
// The Flutter Gradle plugin allows every ABI it supports, so plugin libraries add
// folders for ABIs that have no Flutter engine in this build. Such an APK installs on
// devices where it cannot start.
// Like the plugin, leave the filters alone for `--split-per-abi`, which conflicts with
// them, and for `-P disable-abi-filtering=true`.
val abiFilteringDisabled = listOf("split-per-abi", "disable-abi-filtering")
    .any { project.findProperty(it)?.toString().toBoolean() }
val targetAbis = (project.findProperty("target-platform") as? String)
    ?.takeUnless { abiFilteringDisabled }
    ?.split(",")
    ?.mapNotNull {
        mapOf(
            "android-arm" to "armeabi-v7a",
            "android-arm64" to "arm64-v8a",
            "android-x64" to "x86_64",
        )[it.trim()]
    }
    .orEmpty()

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun signingValue(environment: String, property: String): String? =
    providers.environmentVariable(environment).orNull
        ?.takeIf { it.isNotBlank() }
        ?: keystoreProperties.getProperty(property)?.takeIf { it.isNotBlank() }

val releaseStorePath = signingValue("ANDROID_KEYSTORE_PATH", "storeFile")
val releaseStorePassword = signingValue("ANDROID_KEYSTORE_PASSWORD", "storePassword")
val releaseKeyAlias = signingValue("ANDROID_KEY_ALIAS", "keyAlias")
val releaseKeyPassword = signingValue("ANDROID_KEY_PASSWORD", "keyPassword")

val validateReleaseSigning by tasks.registering {
    doLast {
        check(listOf(releaseStorePath, releaseStorePassword, releaseKeyAlias, releaseKeyPassword).all { it != null }) {
            "Release signing is required. Set ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS and ANDROID_KEY_PASSWORD, or android/key.properties. See docs/RELEASING.md."
        }
        check(rootProject.file(releaseStorePath!!).isFile) {
            "The release keystore file does not exist."
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(validateReleaseSigning)
}

android {
    namespace = "bielik.ai.bielik_oneclick_launcher"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures { buildConfig = true }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = if (e2eBuild) "bielik.ai.bielik_oneclick_launcher.e2e" else "bielik.ai"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        buildConfigField("boolean", "APK_UPDATES", apkUpdates.toString())
        if (targetAbis.isNotEmpty()) {
            ndk {
                abiFilters.clear()
                abiFilters += targetAbis
            }
        }
    }

    if (apkUpdates) {
        sourceSets.getByName("release").manifest.srcFile("src/apkUpdates/AndroidManifest.xml")
    }

    signingConfigs {
        create("release") {
            storeFile = releaseStorePath?.let { rootProject.file(it) }
            storePassword = releaseStorePassword
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
        }
    }

    buildTypes {
        debug {
            buildConfigField("boolean", "APK_UPDATES", "true")
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
