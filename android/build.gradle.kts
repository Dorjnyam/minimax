allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val localBuildRoot =
    System.getenv("LOCALAPPDATA") ?: System.getProperty("java.io.tmpdir")
val newBuildDir = file("$localBuildRoot/minimax_flutter_build/android")
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.resolve(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
