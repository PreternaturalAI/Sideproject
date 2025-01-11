// swift-tools-version:5.10

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
                "SideprojectCore",
                "Sideproject",
                // "_USearchObjective",
                // "_USearch",
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/PreternaturalAI/AI.git", branch: "main"),
        .package(url: "https://github.com/PreternaturalAI/Cataphyl.git", branch: "main"),
        .package(url: "https://github.com/PreternaturalAI/ChatKit.git", branch: "main"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", branch: "master"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIZ.git", branch: "main"),
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
        /*.target(
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
        ),*/
        .target(
            name: "SideprojectCore",
            dependencies: [
                "AI",
                "CorePersistence",
                "Merge",
                "NetworkKit",
                "Swallow",
                "SwiftUIX",
                "SwiftUIZ",
            ],
            path: "Sources/SideprojectCore",
            resources: [.process("Resources")],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .target(
            name: "SideprojectDocuments",
            dependencies: [
                "Cataphyl",
                "SideprojectCore",
            ],
            path: "Sources/SideprojectDocuments",
            resources: [],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),
        .target(
            name: "Sideproject",
            dependencies: [
                "AI",
                "Cataphyl",
                "ChatKit",
                "CorePersistence",
                "Merge",
                "NetworkKit",
                "SideprojectCore",
                "SideprojectDocuments",
                "Swallow",
                "SwiftUIX",
                "SwiftUIZ",
            ],
            path: "Sources/Sideproject",
            resources: [],
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
    ]/*,
    cxxLanguageStandard: CXXLanguageStandard.cxx11*/
)
