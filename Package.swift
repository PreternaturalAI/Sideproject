// swift-tools-version:5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Sideproject",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "Sideproject",
            targets: [
                "Cataphyl",
                "Sideproject",
                "_USearchObjective",
                "_USearch",
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
        .macro(
            name: "SideprojectMacros",
            dependencies: [
                .product(name: "MacroBuilder", package: "Swallow"),
            ],
            path: "Sources/SideprojectMacros"
        ),
        .target(
            name: "_USearchObjective",
            path: "Sources/_USearch/objc",
            sources: ["USearchObjective.mm"],
            cxxSettings: [
                .headerSearchPath("../include/"),
                .headerSearchPath("../fp16/include/"),
            ]
        ),
        .target(
            name: "_USearch",
            dependencies: [
                "_USearchObjective"
            ],
            path: "Sources/_USearch/swift",
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
                "_USearch",
            ],
            path: "Sources/Cataphyl",
            resources: [],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .target(
            name: "Sideproject",
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
            path: "Sources/Sideproject",
            resources: [.process("Resources")],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .testTarget(
            name: "SideprojectTests",
            dependencies: [
                "Sideproject"
            ],
            path: "Tests/Sideproject"
        ),
    ],
    cxxLanguageStandard: CXXLanguageStandard.cxx11
)
