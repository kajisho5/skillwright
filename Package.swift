// swift-tools-version: 6.2
// Core parts of Skillwright that have no screens. They build and test on Linux too,
// so most checks run for free without a Mac.
import PackageDescription

let package = Package(
    name: "SkillwrightCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "LintEngine", targets: ["LintEngine"]),
    ],
    dependencies: [
        // Version pinned on purpose (design spec §7-2). Do not bump without updating the spec.
        .package(url: "https://github.com/jpsim/Yams.git", exact: "6.2.2"),
    ],
    targets: [
        .target(
            name: "LintEngine",
            dependencies: ["Yams"],
            path: "App/Core/LintEngine",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "LintEngineTests",
            dependencies: ["LintEngine"],
            path: "Tests/LintEngineTests"
        ),
    ]
)
