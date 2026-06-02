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
    val subproject = this
    fun setupAndroid() {
        subproject.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
            compileSdkVersion(36)
            defaultConfig {
                targetSdkVersion(36)
            }
        }
    }

    if (subproject.state.executed) {
        setupAndroid()
    } else {
        subproject.afterEvaluate { setupAndroid() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
