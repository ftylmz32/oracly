plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "app.oracly"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.oracly"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Populated only when android/key.properties is present.
            // Missing file is rejected for release tasks below (no debug fallback).
            if (keystorePropertiesFile.exists()) {
                val alias = keystoreProperties["keyAlias"] as String?
                val keyPass = keystoreProperties["keyPassword"] as String?
                val storePass = keystoreProperties["storePassword"] as String?
                val storePath = keystoreProperties["storeFile"] as String?
                require(!alias.isNullOrBlank()) { "keyAlias missing in android/key.properties" }
                require(!keyPass.isNullOrBlank()) { "keyPassword missing in android/key.properties" }
                require(!storePass.isNullOrBlank()) { "storePassword missing in android/key.properties" }
                require(!storePath.isNullOrBlank()) { "storeFile missing in android/key.properties" }
                keyAlias = alias
                keyPassword = keyPass
                storePassword = storePass
                storeFile = file(storePath)
            }
        }
    }

    buildTypes {
        release {
            // R8 / resource shrinking for release APKs and App Bundles.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )

            // Production release uses upload keystore only — never silent debug signing.
            if (keystorePropertiesFile.exists()) {
                val storePath = keystoreProperties["storeFile"] as String?
                val keystore = storePath?.let { file(it) }
                if (keystore == null || !keystore.exists()) {
                    throw GradleException(
                        "Release keystore not found. Check storeFile in android/key.properties.",
                    )
                }
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

// Fail release assemble/bundle early if signing secrets are absent.
// Debug/profile builds stay unaffected (android {} still configures safely).
gradle.taskGraph.whenReady {
    val releaseRequested = allTasks.any { task ->
        val n = task.name
        n.contains("Release") &&
            (n.startsWith("assemble") ||
                n.startsWith("bundle") ||
                n.startsWith("package") ||
                n.contains("Bundle") ||
                n.contains("Apk") ||
                n.contains("Aab"))
    }
    if (releaseRequested && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "Release signing requires android/key.properties. " +
                "Copy android/key.properties.example, fill secrets locally, " +
                "and never commit key.properties or keystore files. " +
                "Silent debug signing fallback is disabled.",
        )
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.core:core-splashscreen:1.0.1")
}
