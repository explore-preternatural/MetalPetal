// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "MetalPetal",
    platforms: [
        .macOS(.v14),
        .iOS(.v16),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "MetalPetal",
            targets: ["MetalPetal"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MetalPetal",
            dependencies: ["MetalPetalObjectiveC"]
        ),
        .target(
            name: "MetalPetalObjectiveC",
            dependencies: []
        ),
        .target(
            name: "MetalPetalTestHelpers",
            dependencies: ["MetalPetal"],
            path: "Tests/MetalPetalTestHelpers"
        ),
        .testTarget(
            name: "MetalPetalTests",
            dependencies: [
                "MetalPetal",
                "MetalPetalTestHelpers"
            ]
        ),
    ],
    cxxLanguageStandard: .cxx14
)
