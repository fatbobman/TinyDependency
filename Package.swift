// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TinyDependency",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "TinyDependency",
            targets: ["TinyDependency"],
        ),
    ],
    targets: [
        .target(
            name: "TinyDependency",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ],
        ),
        .testTarget(
            name: "TinyDependencyTests",
            dependencies: ["TinyDependency"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ],
        ),
    ],
)
