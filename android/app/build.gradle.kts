import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
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

    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        applicationId = "group.zn.xianyushengxi"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // [风险] PERF-01: 不能同时设置 ndk.abiFilters 与 splits.abi
        // （AGP 直接报 Conflicting configuration）。ABI 取舍统一交给
        // 下面的 splits 块与 flutter.targetPlatform。
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
        checkReleaseBuilds = true
    }

    // [风险] PERF-01: ABI 取舍统一交给 Flutter 工具链：
    // - `flutter build apk --split-per-abi --target-platform android-arm,android-arm64`
    //   由插件自动配置 splits（universalApk=false），产出按 ABI 拆分的安装包；
    // - 普通 `flutter build apk` 由插件注入 abiFilters（随 target-platform）。
    // 在此手写 splits 会与插件注入的 abiFilters 冲突（AGP 直接报错），
    // 也不再保留 universal APK：双 ABI 合包体积约 166MB，不可接受。
}

flutter {
    source = "../.."
}
