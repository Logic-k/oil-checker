plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 기존 설치본과 나란히 설치하기 위한 선택적 패키지 접미사.
// 미지정(기본)이면 기존과 동일한 applicationId·앱 이름으로 빌드된다.
// 예: flutter build apk -P appIdSuffix=.preview
//   → com.oilchecker.oil_checker.preview, 런처 이름 "신규 Oil Checker"
val appIdSuffix = (project.findProperty("appIdSuffix") as String?)?.trim().orEmpty()

android {
    namespace = "com.oilchecker.oil_checker"
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
        applicationId = "com.oilchecker.oil_checker$appIdSuffix"
        manifestPlaceholders["appLabel"] =
            if (appIdSuffix.isEmpty()) "Oil Checker" else "신규 Oil Checker"
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
        }
    }
}

flutter {
    source = "../.."
}
