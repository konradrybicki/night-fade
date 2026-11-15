// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

let package = Package(
    name: "Domain",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "Domain", targets: ["Domain"])
    ],
    targets: [
        .target(name: "Domain", swiftSettings: swiftSettings),
        .testTarget(name: "DomainTests", dependencies: ["Domain"], swiftSettings: swiftSettings),
    ]
)
