import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val isBundleBuild = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("bundle", ignoreCase = true)
}
val isReleaseBuild = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("release", ignoreCase = true)
}
val releaseSigningProperties = Properties()
val releaseSigningPropertiesFile = rootProject.file("key.properties")
if (releaseSigningPropertiesFile.exists()) {
    releaseSigningPropertiesFile.inputStream().use { input ->
        releaseSigningProperties.load(input)
    }
}

fun releaseSigningValue(name: String, legacyName: String): String? {
    val gradleValue = providers.gradleProperty(name).orNull
    if (!gradleValue.isNullOrBlank()) {
        return gradleValue
    }
    val envValue = System.getenv(name)
    if (!envValue.isNullOrBlank()) {
        return envValue
    }
    return releaseSigningProperties.getProperty(name)
        ?: releaseSigningProperties.getProperty(legacyName)
}

android {
    namespace = "group.zn.xianyushengxi"
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
        applicationId = "group.zn.xianyushengxi"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            abiFilters.clear()
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    signingConfigs {
        create("release") {
            val storeFilePath = releaseSigningValue(
                "RELEASE_STORE_FILE",
                "storeFile"
            )
            val storePasswordValue = releaseSigningValue(
                "RELEASE_STORE_PASSWORD",
                "storePassword"
            )
            val keyAliasValue = releaseSigningValue("RELEASE_KEY_ALIAS", "keyAlias")
            val keyPasswordValue = releaseSigningValue(
                "RELEASE_KEY_PASSWORD",
                "keyPassword"
            )
            val hasReleaseSigning = listOf(
                storeFilePath,
                storePasswordValue,
                keyAliasValue,
                keyPasswordValue
            ).all { !it.isNullOrBlank() }
            if (hasReleaseSigning) {
                storeFile = file(storeFilePath!!)
                storePassword = storePasswordValue
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
            } else if (isReleaseBuild) {
                throw GradleException(
                    "Release signing is not configured. Provide RELEASE_STORE_FILE, " +
                        "RELEASE_STORE_PASSWORD, RELEASE_KEY_ALIAS, and RELEASE_KEY_PASSWORD " +
                        "as Gradle properties, environment variables, or android/key.properties."
                )
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            isCrunchPngs = false
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    lint {
        disable += "LintVitalReport"
        checkReleaseBuilds = false
    }

    splits {
        abi {
            isEnable = !isBundleBuild
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = true
        }
    }
}

flutter {
    source = "../.."
}
