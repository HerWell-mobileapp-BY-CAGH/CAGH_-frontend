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
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    val configureAndroid: Project.() -> Unit = {
        if (hasProperty("android")) {
            val androidExt = extensions.findByName("android")
            if (androidExt != null) {
                try {
                    val setNdkVersion = androidExt.javaClass.getMethod("setNdkVersion", String::class.java)
                    setNdkVersion.invoke(androidExt, "28.2.13676358")
                } catch (e: Exception) {}
                try {
                    val setCompileSdk = androidExt.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                    setCompileSdk.invoke(androidExt, 36)
                } catch (e: Exception) {
                    try {
                        val setCompileSdkVersion = androidExt.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                        setCompileSdkVersion.invoke(androidExt, 36)
                    } catch (e2: Exception) {}
                }
            }
        }
    }

    if (state.executed) {
        configureAndroid()
    } else {
        afterEvaluate {
            configureAndroid()
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
