plugins {
    id("com.google.gms.google-services") version "4.4.1" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            
            // Force namespace for telephony
            if (project.name == "telephony") {
                try {
                    val setNamespace = android::class.java.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(android, "com.shounakmulay.telephony")
                } catch (e: Exception) {}
            }
        }
    }
}

// Force JVM 17 for all subprojects, BUT for telephony we might need to match its internal 1.8 if it persists
allprojects {
    tasks.withType<JavaCompile>().configureEach {
        if (project.name == "telephony") {
            sourceCompatibility = "1.8"
            targetCompatibility = "1.8"
        } else {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
    }
    
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            if (project.name == "telephony") {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
            } else {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
