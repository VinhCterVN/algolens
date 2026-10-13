plugins {
	id("com.android.application")

	id("dev.flutter.flutter-gradle-plugin")
}

android {
	namespace = "com.vincent.algorithms.algolens"
	compileSdk = 36
	ndkVersion = "28.2.13676358"

	compileOptions {
		sourceCompatibility = JavaVersion.VERSION_17
		targetCompatibility = JavaVersion.VERSION_17
	}

	defaultConfig {
		applicationId = "com.vincent.algorithms.algolens"
		minSdk = 24
		targetSdk = 35
		versionCode = 1
		versionName = "1.0.0"
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
