import java.util.Base64

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val e2eBuild = (project.findProperty("dart-defines") as? String)
    ?.split(",")
    ?.any { String(Base64.getDecoder().decode(it)) == "BIELIK_E2E=true" }
    ?: false

android {
    namespace = "bielik.ai.bielik_oneclick_launcher"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = if (e2eBuild) "bielik.ai.bielik_oneclick_launcher.e2e" else "bielik.ai.bielik_oneclick_launcher"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
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
