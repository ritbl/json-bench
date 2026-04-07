plugins {
    application
}

val javaRelease = providers.gradleProperty("javaRelease").orElse("25").get().toInt()
val jsonPath = providers.gradleProperty("jsonPath")
    .orElse(layout.projectDirectory.file("../data/big.json").asFile.absolutePath)
    .get()
val iterations = providers.gradleProperty("iterations").orElse("10").get()
val warmup = providers.gradleProperty("warmup").orElse("3").get()

repositories {
    mavenCentral()
}

dependencies {
    implementation("com.dslplatform:dsl-json:2.0.2")
    annotationProcessor("com.dslplatform:dsl-json:2.0.2")
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(javaRelease))
    }
}

application {
    mainClass.set("bench.BigJsonBenchmark")
}

tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
    options.release.set(javaRelease)
    options.compilerArgs.add("-Adsljson.generatedmarker=")
}

tasks.named<JavaExec>("run") {
    args(jsonPath, iterations, warmup)
    jvmArgs(
        "-server",
        "-XX:+UseG1GC",
        "-XX:+AlwaysPreTouch",
        "-XX:+UseStringDeduplication",
        "-XX:+OptimizeStringConcat",
    )
}
