// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EnergyAppBrain",
    products: [
        .library(
            name: "EnergyAppBrainCore",
            targets: ["EnergyAppBrainCore"]
        ),
        .executable(
            name: "EnergyAppBrain",
            targets: ["EnergyAppBrain"]
        )
    ],
    targets: [
        .target(
            name: "EnergyAppBrainCore"
        ),
        .executableTarget(
            name: "EnergyAppBrain",
            dependencies: ["EnergyAppBrainCore"]
        ),
        .testTarget(
            name: "EnergyAppBrainTests",
            dependencies: ["EnergyAppBrainCore"]
        )
    ]
)
