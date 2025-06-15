plugins {
    id("com.android.application")
    id("kotlin-android")
    // Plugin de Flutter
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.cleanpro"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.cleanpro"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Usa la firma de debug para que compile sin error
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase Authentication y Analytics
    implementation("com.google.firebase:firebase-auth-ktx:22.3.0")
    implementation("com.google.firebase:firebase-analytics-ktx:21.5.0")
}

// Aplica el plugin de servicios de Google (Firebase)
apply(plugin = "com.google.gms.google-services")
