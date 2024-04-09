// swift-tools-version:5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Lite",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "Lite",
            targets: [
                "Cataphyl",
                "Lite",
                "USearchObjective",
                "USearch",
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/PreternaturalAI/AI.git", branch: "main"),
        .package(url: "https://github.com/PreternaturalAI/ChatKit.git", branch: "main"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", branch: "master"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIZ.git", branch: "main"),
        .package(url: "https://github.com/vmanot/BrowserKit.git", branch: "main"),
        .package(url: "https://github.com/vmanot/CorePersistence.git", branch: "main"),
        .package(url: "https://github.com/vmanot/Merge.git", branch: "master"),
        .package(url: "https://github.com/vmanot/NetworkKit.git", branch: "master"),
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "USearchObjective",
            path: "Sources/USearch/objc",
            sources: ["USearchObjective.mm"],
            cxxSettings: [
                .headerSearchPath("../include/"),
            ]
        ),
        .target(
            name: "USearch",
            dependencies: ["USearchObjective"],
            path: "Sources/USearch/swift",
            exclude: [],
            sources: ["USearch.swift", "Index+Sugar.swift"],
            cxxSettings: [
                .headerSearchPath("./include/"),
            ]
        ),
        .target(
            name: "Cataphyl",
            dependencies: [
                "AI",
                "CorePersistence",
                "Swallow",
                "USearch",
            ],
            path: "Sources/Cataphyl",
            resources: []
        ),
        .target(
            name: "Lite",
            dependencies: [
                "AI",
                "BrowserKit",
                "Cataphyl",
                "ChatKit",
                "CorePersistence",
                "Merge",
                "NetworkKit",
                "Swallow",
                "SwiftUIX",
                "SwiftUIZ",
            ],
            path: "Sources/Lite",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "LiteTests",
            dependencies: [
                "Lite"
            ],
            path: "Tests/Lite"
        ),
    ],
    cxxLanguageStandard: CXXLanguageStandard.cxx11
)
