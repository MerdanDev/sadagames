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
// Escape hatch for a machine whose NDK install is broken. A half-downloaded copy
// fails configuration with a bare "[CXX1101] ... did not have a source.properties
// file", and the version Flutter defaults to is the one that tends to be damaged.
// Set sadagames.ndkVersion in ~/.gradle/gradle.properties, or SADAGAMES_NDK_VERSION
// in the environment, to point every Android module at a known-good install.
//
// Unset by default, so CI and other machines keep whatever their SDK provides —
// this is a local workaround, not a requirement of the project.
//
// It overrides every module rather than the app alone: plugins that compile native
// code — flutter_soloud, which synthesises every sound — resolve their own AGP
// default instead of inheriting the app's, so an app-level pin never reaches them.
//
// Registered before the evaluationDependsOn below, which evaluates :app eagerly;
// afterEvaluate throws on a project that has already been evaluated.
val pinnedNdkVersion = (findProperty("sadagames.ndkVersion") as String?)
    ?.takeIf { it.isNotBlank() }
    ?: System.getenv("SADAGAMES_NDK_VERSION")?.takeIf { it.isNotBlank() }

if (pinnedNdkVersion != null) {
    subprojects {
        afterEvaluate {
            extensions.findByName("android")?.withGroovyBuilder {
                setProperty("ndkVersion", pinnedNdkVersion)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}