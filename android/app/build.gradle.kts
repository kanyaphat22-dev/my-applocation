plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin ต้องตามหลัง Android และ Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.location"
    compileSdk = 35   // ✅ ใช้ Android SDK 35
    ndkVersion = "27.0.12077973"   // ✅ สำหรับ video_player

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.location"
        minSdk = 21        // ✅ Flutter ต้องการอย่างน้อย 21
        targetSdk = 35     // ✅ ให้ตรงกับ compileSdk
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            // ตอนนี้ยังใช้ debug key อยู่
            signingConfig = signingConfigs.getByName("debug")

            // ✅ ถ้า build release จริง ค่อยเปิดใช้ด้านล่าง
            // minifyEnabled = true
            // shrinkResources = true
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

flutter {
    source = "../.."
}
