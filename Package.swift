// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EvoBar",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "EvoBarCore", targets: ["EvoBarCore"]),
        .library(name: "EvoBarEvolution", targets: ["EvoBarEvolution"]),
        .library(name: "EvoBarPurchases", targets: ["EvoBarPurchases"]),
        .library(name: "EvoBarUsage", targets: ["EvoBarUsage"]),
        .library(name: "EvoBarPersistence", targets: ["EvoBarPersistence"]),
        .library(name: "EvoBarInfrastructure", targets: ["EvoBarInfrastructure"]),
        .executable(name: "EvoBar", targets: ["EvoBarApp"]),
    ],
    targets: [
        .target(
            name: "EvoBarCore",
            resources: [.process("Resources")]
        ),
        .target(
            name: "EvoBarEvolution",
            dependencies: ["EvoBarCore"]
        ),
        .target(
            name: "EvoBarPurchases",
            dependencies: ["EvoBarCore"]
        ),
        .target(
            name: "EvoBarUsage",
            dependencies: ["EvoBarCore"]
        ),
        .target(
            name: "EvoBarPersistence",
            dependencies: ["EvoBarCore", "EvoBarEvolution", "EvoBarUsage"]
        ),
        .target(
            name: "EvoBarInfrastructure",
            dependencies: ["EvoBarCore"],
            linkerSettings: [.linkedFramework("Security")]
        ),
        .target(
            name: "ClaudeCodeProvider",
            dependencies: ["EvoBarCore", "EvoBarUsage"]
        ),
        .target(
            name: "CodexProvider",
            dependencies: ["EvoBarCore", "EvoBarUsage"]
        ),
        .executableTarget(
            name: "EvoBarApp",
            dependencies: [
                "EvoBarCore",
                "EvoBarEvolution",
                "EvoBarPurchases",
                "EvoBarUsage",
                "EvoBarPersistence",
                "EvoBarInfrastructure",
                "ClaudeCodeProvider",
                "CodexProvider",
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "EvoBarCoreTests",
            dependencies: ["EvoBarCore"]
        ),
        .testTarget(
            name: "EvoBarEvolutionTests",
            dependencies: ["EvoBarCore", "EvoBarEvolution"]
        ),
        .testTarget(
            name: "EvoBarPurchasesTests",
            dependencies: ["EvoBarCore", "EvoBarPurchases"]
        ),
        .testTarget(
            name: "UsageProviderTests",
            dependencies: [
                "EvoBarCore",
                "EvoBarEvolution",
                "EvoBarPersistence",
                "EvoBarUsage",
                "ClaudeCodeProvider",
                "CodexProvider",
            ],
            resources: [.process("Fixtures")]
        ),
        .testTarget(
            name: "EvoBarPersistenceTests",
            dependencies: [
                "EvoBarCore",
                "EvoBarEvolution",
                "EvoBarPersistence",
                "EvoBarUsage",
            ]
        ),
        .testTarget(
            name: "EvoBarInfrastructureTests",
            dependencies: ["EvoBarCore", "EvoBarInfrastructure"]
        ),
    ]
)
