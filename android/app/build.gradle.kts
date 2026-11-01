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

val localPropertiesFile = rootProject.file("local.properties")
val localProperties = Properties()
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}
val localDebugApplicationId = providers
    .gradleProperty("oraclyDebugApplicationId")
    .orNull
    ?: localProperties.getProperty("oracly.debugApplicationId")
val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}
if (localDebugApplicationId != null) {
    require(localDebugApplicationId == "com.example.oracly_new") {
        "Only the registered local debug applicationId is allowed."
    }
    require(!releaseTaskRequested) {
        "The local debug applicationId override cannot be used for release tasks."
    }
}

// ── Google Mobile Ads app id (Freemium Aşama 3B, ads dark by default) ──
// Debug / profile carry Google's official sample app id (test ads only).
// Release carries ORACLY's real AdMob Android app id (an app id, not an ad
// unit id; it is public inside every shipped APK, not a secret). The app id
// alone never requests or shows an ad: that stays behind the ads gate and
// the default-off ads_v1 flag. lib/features/ads/ads_environment.dart holds
// the same value; test/features/ads/ads_gate_test.dart keeps them in sync.
val admobSampleAppId = "ca-app-pub-3940256099942544~3347511713"
val admobProductionAppId = "ca-app-pub-8094570449180229~6192956874"
val admobRealAppId = Regex("^ca-app-pub-[0-9]{16}~[0-9]{10}$")
fun isRealAdmobAppId(id: String?): Boolean =
    id != null && admobRealAppId.matches(id) && !id.startsWith("ca-app-pub-3940256099942544")

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
        applicationId = localDebugApplicationId ?: "app.oracly"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = admobSampleAppId
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
            // Real AdMob app id only (checked before any release task runs).
            manifestPlaceholders["admobAppId"] = admobProductionAppId
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

// Fail release assemble/bundle early unless the release app id is a real,
// non-sample AdMob app id (never a sample or invented id in a release).
gradle.taskGraph.whenReady {
    val releaseRequested = allTasks.any { task ->
        val n = task.name
        n.contains("Release") &&
            (n.startsWith("assemble") ||
                n.startsWith("bundle") ||
                n.startsWith("package") ||
                n.startsWith("process") ||
                n.contains("Bundle") ||
                n.contains("Apk") ||
                n.contains("Aab"))
    }
    if (releaseRequested && !isRealAdmobAppId(admobProductionAppId)) {
        throw GradleException(
            "Release builds need ORACLY's real AdMob Android app id " +
                "(admobProductionAppId). Google's sample id is debug-only.",
        )
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
